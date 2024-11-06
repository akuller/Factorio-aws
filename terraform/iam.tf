data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "instance_s3_policy" {
  statement {
    effect    = "Allow"
    actions   = ["route53:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "instance_role" {
  name               = "instance-role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
  ]
  inline_policy {
    name   = "s3-policy"
    policy = data.aws_iam_policy_document.instance_s3_policy.json
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_security_group" "instance_sg" {
  name   = "factorio-instance-sg"
  vpc_id = aws_vpc.factorio_vpc.id
  /*
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.myip]
  }
   */
  ingress {
    from_port   = 34197
    to_port     = 34197
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 27015
    to_port     = 27015
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "DNS_lambda_policy_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "DNS_lambda_policy" {
  statement {
    effect    = "Allow"
    actions   = ["route53:*"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeInstance*"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "DNS_lambda_role" {
  name                = "DNS-Lambda-Policy"
  description         = "DNS Lambda Policy"
  assume_role_policy  = data.aws_iam_policy_document.DNS_lambda_policy_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  inline_policy {
    name   = "lambda-policy"
    policy = data.aws_iam_policy_document.DNS_lambda_policy.json
  }
}

resource "aws_security_group" "factorio-efs-sg" {
  depends_on = [aws_security_group.instance_sg]
  name        = "factorio-efs-sg"
  description = "factorio efs security group"
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.instance_sg.id]
  }
  vpc_id = aws_vpc.factorio_vpc.id
}