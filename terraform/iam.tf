data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
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
  name_prefix        = "ecs-factorio-node-role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
  inline_policy {
    name   = "route53_allow"
    policy = data.aws_iam_policy_document.instance_s3_policy.json
  }
}

resource "aws_iam_role_policy_attachment" "ecs_factorio_role_policy" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "factorio-ecs-node-profile"
  role = aws_iam_role.instance_role.name
}

data "aws_iam_policy_document" "ecs_task_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name_prefix        = "factorio-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role" "ecs_exec_role" {
  name_prefix        = "demo-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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
  name                = "DNS_Lambda_Policy"
  description         = "DNS Lambda Policy"
  assume_role_policy  = data.aws_iam_policy_document.DNS_lambda_policy_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  inline_policy {
    name   = "lambda-policy"
    policy = data.aws_iam_policy_document.DNS_lambda_policy.json
  }
}

