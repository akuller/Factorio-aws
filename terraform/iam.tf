data "aws_iam_policy_document" "instance_assume_role_policy"{
  statement {
    effect = "Allow"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
  statement {
    effect = "Allow"
    actions = ["route53:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "instance_role" {
  name = "instance_role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = aws_iam_role.instance_role.arn
}

resource "aws_security_group" "instance_sg" {
  name = "factorio-instance-sg"
  vpc_id = aws_vpc.factorio_vpc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.myip]
  }
  ingress {
    from_port = 34197
    to_port = 34197
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 27015
    to_port = 27015
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "DNS_lambda_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
  statement {
    effect = "Allow"
    actions = ["route53:*"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = ["ec2:DescribeInstance*"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "DNS_lambda_role" {
  name = "DNS-Lambda-Policy"
  description = "DNS Lambda Policy"
  assume_role_policy = data.aws_iam_policy_document.DNS_lambda_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

resource "aws_security_group" "factorio-efs-sg" {
  name = "factorio-efs-sg"
  description = "factorio efs security group"
  ingress {
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    security_groups = aws_security_group.instance_sg.arn
  }
  vpc_id = aws_vpc.factorio_vpc.id
}