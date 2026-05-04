resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-lambda-report-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "s3_write" {
  name = "${var.project}-lambda-s3-write"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:PutObjectAcl"]
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.bucket_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.s3_write.arn
}

resource "aws_security_group" "lambda_sg" {
  name        = "${var.project}-lambda-report-sg"
  description = "Security group for lambda report function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

resource "aws_lambda_function" "report" {
  filename         = abspath("${path.root}/../lambda/report.zip")
  source_code_hash = filebase64sha256(abspath("${path.root}/../lambda/report.zip"))

  function_name = var.function_name
  role          = aws_iam_role.lambda_role.arn

  handler = "index.handler"
  runtime = "nodejs20.x"
  timeout = 60

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
      SERVER_IPS  = join(",", var.server_ips)
    }
  }

  tags = var.common_tags
}

resource "aws_security_group_rule" "lambda_to_ec2" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = var.ec2_sg_id
  source_security_group_id = aws_security_group.lambda_sg.id
  description              = "Allow Lambda to reach EC2 nginx"
}
