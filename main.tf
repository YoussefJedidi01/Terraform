variable "existing_vpc_id" {
  default = "vpc-***********" #your existing vpc
}
 
variable "existing_subnet_id" {
  default = "subnet-************" #your existing subnet
}
 
variable "region" {
  description = "The AWS region to deploy resources in"
  default = "us-east-1"
}
 
locals {
  virtual_machines = [
    {
      Name                = "jenkins-master"
      instance_type       = "t3.small"
vpc_security_group_ids = [aws_security_group.jenkins_master_sg.id]
ssm_document = aws_ssm_document.install_jenkins.name
    },
    {
      Name                = "jenkins-agent"
      instance_type       = "t3.micro"
vpc_security_group_ids = [aws_security_group.jenkins_agent_sg.id]
ssm_document = aws_ssm_document.install_jenkins_agent.name
    }
  ]
instance_ids = [for vm in aws_instance.jenkins_server : vm.id]
}
 
resource "aws_security_group" "jenkins_master_sg" {
  name        = "jenkins_master_sg"
  description = "Allow HTTP access to Jenkins Master"
  vpc_id      = var.existing_vpc_id
 
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name            = "jenkins_master_sg"
    Environment     = "Development"
    Owner           = "DevOps Team"
    Project         = "CI/CD"
    CreatedBy       = "IAMUser:*************:JedidiTerra"
    "tag_name" = "YJedidi"
  }
}
 
resource "aws_security_group" "jenkins_agent_sg" {
  name        = "jenkins_agent_sg"
  description = "Allow communication between Jenkins Master and Agent"
  vpc_id      = var.existing_vpc_id
 
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name            = "jenkins_agent_sg"
    Environment     = "Development"
    Owner           = "DevOps Team"
    Project         = "CI/CD"
    CreatedBy       = "IAMUser:************:JedidiTerra"
    "tag_name" = "YJedidi"
  }
}
 
resource "aws_iam_role" "ssm_role" {
  name               = "SSMRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
 
  tags = {
    "tag_name" = "YJedidi"
  }
}
 
resource "aws_iam_role_policy_attachment" "ssm_role_attachment_ssm" {
role = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
 
resource "aws_iam_role_policy_attachment" "ssm_role_attachment_admin" {
role = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
 
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSM_Instance_Profile"
role = aws_iam_role.ssm_role.name
}
 
resource "aws_ssm_document" "install_jenkins" {
  name          = "install_jenkins"
  document_type = "Command"
  content       = file("install_jenkins.json")
}
 
resource "aws_ssm_document" "install_jenkins_agent" {
  name          = "install_jenkins_agent"
  document_type = "Command"
  content       = file("install_jenkins_agent.json")
}
 
resource "aws_instance" "jenkins_server" {
for_each = { for vm in local.virtual_machines : vm.Name => vm }
  ami      = "ami-0b72821e2f351e396" # Amazon Linux 2023 AMI
  instance_type          = each.value.instance_type
  key_name               = "ec2_terraform"
  vpc_security_group_ids = each.value.vpc_security_group_ids
  subnet_id              = var.existing_subnet_id
iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
 
  user_data = <<-EOF
    #!/bin/bash
    sudo yum install -y amazon-ssm-agent
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent
  EOF
 
  root_block_device {
    volume_type = "gp2"
    volume_size = 20
  }
 
  ebs_block_device {
    device_name  = "/dev/xvdf"
    volume_size  = 50
    volume_type  = "gp2"
  }
 
  tags = {
Name = each.value.Name
    Environment     = "Development"
    Owner           = "DevOps Team"
    Project         = "CI/CD"
    CreatedBy       = "IAMUser:*************:JedidiTerra"
    "tag_name" = "YJedidi"
  }
 
  provisioner "local-exec" {
command = "aws ssm send-command --document-name ${each.value.ssm_document} --targets '[{\"Key\":\"InstanceIds\",\"Values\":[\"${self.id}\"]}]' --comment 'Install Jenkins' --timeout-seconds 600 --max-concurrency '50' --max-errors '0' --region ${var.region}"
  }
}
 
resource "aws_iam_policy" "lambda_ec2_policy" {
  name        = "lambda_ec2_policy"
  path        = "/"
  description = "Policy to allow Lambda functions to start and stop EC2 instances and write to CloudWatch logs"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
 
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
 
  tags = {
    "tag_name" = "YJedidi"
  }
}
 
resource "aws_iam_role_policy_attachment" "lambda_administrator_access" {
role = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
 
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
role = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
 
resource "aws_iam_role_policy_attachment" "lambda_ec2_policy_attachment" {
role = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
}
 
resource "aws_lambda_function" "start_ec2_instance" {
filename = "Lambda_function/start_instances.zip"
  function_name    = "start_ec2_instance"
  role             = aws_iam_role.lambda_role.arn
  handler          = "start_instances.lambda_handler"
source_code_hash = filebase64sha256("Lambda_function/start_instances.zip")
  runtime          = "python3.11"
  timeout          = 30
 
  environment {
    variables = {
      INSTANCE_IDS = join(",", local.instance_ids)
    }
  }
}
 
resource "aws_lambda_function" "stop_ec2_instance" {
filename = "Lambda_function/stop_instances.zip"
  function_name    = "stop_ec2_instance"
  role             = aws_iam_role.lambda_role.arn
  handler          = "stop_instances.lambda_handler"
source_code_hash = filebase64sha256("Lambda_function/stop_instances.zip")
  runtime          = "python3.11"
  timeout          = 30
  environment {
    variables = {
      INSTANCE_IDS = join(",", local.instance_ids)
    }
  }
}



resource "aws_lambda_permission" "allow_cloudwatch_start_scheduler" {
  statement_id  = "AllowExecutionFromCloudWatchStartScheduler"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_ec2_instance.function_name
principal = "events.amazonaws.com"
}
 
resource "aws_lambda_permission" "allow_cloudwatch_stop_scheduler" {
  statement_id  = "AllowExecutionFromCloudWatchStopScheduler"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_ec2_instance.function_name
principal = "events.amazonaws.com"
}
 
resource "aws_cloudwatch_event_rule" "start_ec2_rule" {
  name                = "start_ec2_rule"
  description         = "Start EC2 instances at 9 AM Tunisia time"
  schedule_expression = "cron(0 8 ? * MON-FRI *)"  # 8 AM UTC
}
 
resource "aws_cloudwatch_event_rule" "stop_ec2_rule" {
  name                = "stop_ec2_rule"
  description         = "Stop EC2 instances at 5 PM Tunisia time"
  schedule_expression = "cron(0 16 ? * MON-FRI *)"  # 4 PM UTC
}
 
resource "aws_cloudwatch_event_target" "start_ec2_target" {
rule = aws_cloudwatch_event_rule.start_ec2_rule.name
  target_id = "start_ec2_lambda"
  arn       = aws_lambda_function.start_ec2_instance.arn
}
 
resource "aws_cloudwatch_event_target" "stop_ec2_target" {
rule = aws_cloudwatch_event_rule.stop_ec2_rule.name
  target_id = "stop_ec2_lambda"
  arn       = aws_lambda_function.stop_ec2_instance.arn
}
 
output "instance_ids" {
  value = join(",", local.instance_ids)
}