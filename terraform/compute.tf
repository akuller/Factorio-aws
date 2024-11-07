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

resource "aws_launch_template" "factorio_launch_template" {
  image_id      = data.aws_ami.amazon_linux.id
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
  name     = "factorio_group"
  max_size = var.aws_autoscaling_max
  min_size = var.aws_autoscaling_min
  launch_template {
    id      = aws_launch_template.factorio_launch_template.id
    version = "$Latest"
  }
  #vpc_zone_identifier = [aws_subnet.factorio_a.id, aws_subnet.factorio_b.id, aws_subnet.factorio_c.id]
  vpc_zone_identifier = [aws_subnet.factorio_a.id, aws_subnet.factorio_b.id]
}


resource "aws_ecs_cluster" "factorio_cluster" {
  name = "factorio-cluster"
}

resource "aws_ecs_service" "factorio_ecs_service" {
  name            = "factorio-ecs-service"
  cluster         = aws_ecs_cluster.factorio_cluster.arn
  desired_count   = 1
  task_definition = aws_ecs_task_definition.factorio_ecs_task_definition.arn
}


resource "aws_ecs_task_definition" "factorio_ecs_task_definition" {
  family                = "Factorio-ECS-Task"
  container_definitions = <<TASK_DEFINITION
  [
    {
      "image": "${var.factorio_docker_image}:${var.factorio_image_tag}",
      "memory": 1024,
      "name": "factorio",
      "portMappings": [
        {
          "containerPort": 34197,
          "hostPort": 34197,
          "protocol": "udp"
        },
        {
          "containerPort": 27015,
          "hostPort": 27015,
          "protocol": "tcp"
        }
      ],
      "mountPoints": [
        {
          "ContainerPath": "/factorio",
          "ReadOnly": false,
          "SourceVolume": "factorio"
        }
      ],
      "environment" : [
        {"name": "Update MODS on Start", "value": "${var.update_mods_on_start}" },
        {"name": "DLC Space Age", "value": "${var.dlc_space_age}" }
      ]
    }
  ]
  TASK_DEFINITION

  volume {
    name = "factorio"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.factorio_efs.id
      transit_encryption = "ENABLED"
    }
  }
}

resource "aws_ecs_capacity_provider" "factorio_ecs_capacity_provider" {
  name = "factorio-ecs-ec2"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.factorio_ag.arn
    managed_termination_protection = "DISABLED"
    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "factorio_cluster_cap_prov" {
  cluster_name       = aws_ecs_cluster.factorio_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.factorio_ecs_capacity_provider.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.factorio_ecs_capacity_provider.name
    base              = 1
    weight            = 100
  }
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