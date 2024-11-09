data "aws_ami" "amazon_linux" {
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  most_recent = true
}

data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "factorio_launch_template" {
  image_id      = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type = var.aws_instance_type
  name_prefix   = "factorio-"
  iam_instance_profile {
    arn = aws_iam_instance_profile.instance_profile.arn
  }
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.factorio_cluster.name} >> /etc/ecs/ecs.config;
    EOF
  )
}

resource "aws_autoscaling_group" "factorio_ag" {
  name                = "factorio_group"
  vpc_zone_identifier = [aws_subnet.factorio_a.id, aws_subnet.factorio_b.id]
  max_size            = var.aws_autoscaling_max
  min_size            = var.aws_autoscaling_min
  desired_capacity    = var.aws_autoscaling_desired_capacity
  # health_check_grace_period = 0
  # health_check_type         = "EC2"
  # protect_from_scale_in     = false

  launch_template {
    id      = aws_launch_template.factorio_launch_template.id
    version = "$Latest"
  }


  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "factorio-ecs-cluster"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}


resource "aws_ecs_cluster" "factorio_cluster" {
  name = "factorio-cluster"
}

# resource "aws_ecs_capacity_provider" "factorio_ecs_capacity_provider" {
#   name = "factorio-ecs-ec2"
#
#   auto_scaling_group_provider {
#     auto_scaling_group_arn         = aws_autoscaling_group.factorio_ag.arn
#     managed_termination_protection = "DISABLED"
#
#     managed_scaling {
#       maximum_scaling_step_size = 2
#       minimum_scaling_step_size = 1
#       status                    = "ENABLED"
#       target_capacity           = 100
#     }
#   }
# }
#
# resource "aws_ecs_cluster_capacity_providers" "factorio_cluster_cap_prov" {
#   cluster_name       = aws_ecs_cluster.factorio_cluster.name
#   capacity_providers = [aws_ecs_capacity_provider.factorio_ecs_capacity_provider.name]
#
#   default_capacity_provider_strategy {
#     capacity_provider = aws_ecs_capacity_provider.factorio_ecs_capacity_provider.name
#     base              = 1
#     weight            = 100
#   }
# }

resource "aws_ecs_task_definition" "factorio_ecs_task_definition" {
  family = "Factorio-ECS-Task"

  container_definitions = jsonencode([{
    name   = "factorio",
    image  = "${var.factorio_docker_image}:${var.factorio_image_tag}",
    memory = 1024
    cpu    = 512
    portMappings = [
      {
        containerPort = 34197,
        hostPort      = 34197,
        protocol      = "udp"
      },
      {
        containerPort = 27015,
        hostPort      = 27015,
        protocol      = "tcp"
      }
    ],
    environment = [
      { name = "UPDATE_MODS_ON_START", value = tostring(var.update_mods_on_start) },
      { name = "DLC_SPACE_AGE", value = tostring(var.dlc_space_age) }
    ],
    mountPoints = [
      {
        ContainerPath = "/factorio",
        SourceVolume  = "factorio",
        ReadOnly      = false
      }
    ]
  }])

  volume {
    name = "factorio"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.factorio_efs.id
      transit_encryption = "ENABLED"
    }
  }
  # task_role_arn      = aws_iam_role.ecs_task_role.arn
  # execution_role_arn = aws_iam_role.ecs_exec_role.arn
}

resource "aws_ecs_service" "factorio_ecs_service" {
  name                               = "factorio-ecs-service"
  cluster                            = aws_ecs_cluster.factorio_cluster.id
  desired_count                      = 1
  task_definition                    = aws_ecs_task_definition.factorio_ecs_task_definition.arn
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0



  # network_configuration {
  #   subnets         = [aws_subnet.factorio_a.id, aws_subnet.factorio_b.id]
  #   security_groups = [aws_security_group.factorio-efs-sg.id, aws_security_group.instance_sg.id]
  # }

  # capacity_provider_strategy {
  #   capacity_provider = aws_ecs_capacity_provider.factorio_ecs_capacity_provider.name
  #   base              = 1
  #   weight            = 100
  # }
}



data "archive_file" "dns_lambda" {
  type        = "zip"
  source_file = "../scripts/dns_lambda.py"
  output_path = "lambda_dns_function_payload.zip"
}

resource "aws_lambda_function" "set_dns_record_lambda" {
  count         = 1
  function_name = "factorio_dns_lambda"
  role          = aws_iam_role.DNS_lambda_role.arn
  environment {
    variables = {
      HostedZoneID = var.hosted_zone_id
      RecordName   = var.factorio_uri
    }
  }
  filename         = data.archive_file.dns_lambda.output_path
  source_code_hash = data.archive_file.dns_lambda.output_base64sha256
  description      = "Sets Route 53 DNS Record for Factorio"
  handler          = "index.handler"
  memory_size      = 128
  runtime          = "python3.12"
  timeout          = 20
}