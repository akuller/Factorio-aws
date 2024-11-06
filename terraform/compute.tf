data "aws_ami" "amazon_linux"{
  most_recent = true
  owners = ["amazon"]
  name_regex = "Amazon Linux 2*"
  filter {
    name = "architecture"
    values = ["amd64"]
  }
    filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_launch_template" "factorio_launch_template" {
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.aws_instance_type
  name_prefix = "factorio-"
}


resource "aws_autoscaling_group" "factorio_ag" {
  name = "factorio_group"
  max_size = var.aws_autoscaling_max
  min_size = var.aws_autoscaling_min
  launch_template {
    id      = aws_launch_template.factorio_launch_template.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.factorio_a, aws_subnet.factorio_b, aws_subnet.factorio_c]

}


resource "aws_ecs_cluster" "factorio_cluster" {
  name = "factorio-cluster"
}

resource "aws_ecs_service" "factorio_ecs_service" {
  name = "factorio-ecs-service"
  cluster = aws_ecs_cluster.factorio_cluster.arn
  desired_count = 1
  iam_role = aws_iam_role.instance_role.arn
  task_definition = aws_ecs_task_definition.factorio_ecs_task_definition.arn
}


resource "aws_ecs_task_definition" "factorio_ecs_task_definition" {
  family = "Factorio ECS Task"
  container_definitions = jsondecode(
    {
      name   = "factorio"
      image  = "${var.factorio_docker_image}:${var.factorio_image_tag}"
      memory = 1024
      portMappings = [
        {
          containerPort = 34197
          hostPort = 34197
          protocol = "udp"
        },
        {
          containerPort = 27015
          hostPort = 27015
          protocol = "tcp"
        }
      ]
      Environment = [
        {
          name = "Update MODS on Start"
          value = var.update_mods_on_start
        },
        {
          name = "DLC Space Age"
          value = var.dlc_space_age
        }
      ]
      mount_points = {
        ContainerPath = "/factorio"
        SourceVolume = "factorio"
        ReadOnly = false
      }
    }
  )

  volume {
    name = "factorio"
    efs_volume_configuration = {
      file_system_id          = aws_efs_file_system.factorio_efs.arn
      transit_encryption      = "ENABLED"
    }
  }
}

data "archive_file" "dns_lambda"{
  type = "zip"
  source_file = "../scripts/dns_lambda.py"
  output_path = "lambda_dns_function_payload.zip"
}

resource "aws_lambda_function" "set_dns_record_lambda" {
  count         = 1
  function_name = "factorio_dns_lambda"
  role          = aws_iam_role.DNS_lambda_role.arn
  environment {
    variables = {
      HostedZoneID = aws_route53_zone.main.id
      RecordName   = var.factorio_uri
    }
  }
  filename = data.archive_file.dns_lambda.output_path
  source_code_hash = data.archive_file.dns_lambda.output_base64sha256
  description = "Sets Route 53 DNS Record for Factorio"
  handler = "index.handler"
  memory_size = 128
  runtime = "python3.12"
  timeout = 20
}