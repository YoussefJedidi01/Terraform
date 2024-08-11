# Terraform EC2 Infrastructure for Jenkins Server

## Description
This project contains Terraform code to provision an EC2 instance on AWS for setting up a Jenkins server. Jenkins is an open-source automation server that helps automate parts of software development related to building, testing, and deploying.

## Prerequisites
Before you begin, ensure you have met the following requirements:
- Terraform installed (>= v0.12)
- AWS CLI installed and configured with the necessary credentials
- SSH key pair available for connecting to the EC2 instance

## Usage

### 1. Clone the repository
git clone https://github.com/YoussefJedidi01/Terraform.git
cd Terraform

### 2. Initialize the Terraform configuration
terraform init

### 3. Apply the Terraform plan
terraform apply
You will be prompted to confirm before resources are created.

### 4. Access the Jenkins server
Once the EC2 instance is up and running, you can access Jenkins by navigating to the public IP of the instance in your browser on port 8080:
http://<ec2-public-ip>:8080 OR http://localhost:8080

## Terraform Configuration

### Variables

The Terraform code allows customization through the following variables:

- existing_vpc_id: The ID of an existing VPC where the EC2 instances will be deployed.
- existing_subnet_id: The ID of an existing Subnet within the specified VPC.
- region: The AWS region to deploy resources in (default: us-east-1).

### Local Values

The Terraform code uses the following local values:

- virtual_machines: A list of virtual machines to be created. Each VM has the following attributes:
  - Name: The name of the virtual machine.
  - instance_type: The EC2 instance type (e.g., t3.small for Jenkins master and t3.micro for Jenkins agent).
  - vpc_security_group_ids: The security group IDs associated with the instance.
  - ssm_document: The SSM document used to install Jenkins or the Jenkins agent on the instance.

### Resources

- *Security Groups:*
  - aws_security_group.jenkins_master_sg: Security group to allow HTTP access to the Jenkins Master instance on port 8080.
  - aws_security_group.jenkins_agent_sg: Security group to allow communication between the Jenkins Master and Agent instances on port 50000.

- *IAM Roles and Policies:*
  - aws_iam_role.ssm_role: IAM role for EC2 instances to interact with AWS Systems Manager (SSM).
  - aws_iam_instance_profile.ssm_instance_profile: Instance profile associated with the SSM role.
  - aws_iam_role.lambda_role: IAM role for Lambda functions to manage EC2 instances.
  - aws_iam_policy.lambda_ec2_policy: Custom policy to allow Lambda functions to start/stop EC2 instances and log to CloudWatch.
  
- *EC2 Instances:*
  - aws_instance.jenkins_server: Provisions the Jenkins Master and Agent instances using the specified AMI (ami-0b72821e2f351e396), instance type, and security group.

- *AWS Systems Manager (SSM):*
  - aws_ssm_document.install_jenkins: SSM document for installing Jenkins on the Jenkins Master instance.
  - aws_ssm_document.install_jenkins_agent: SSM document for installing Jenkins Agent on the Jenkins Agent instance.

- *Lambda Functions:*
  - aws_lambda_function.start_ec2_instance: Lambda function to start EC2 instances based on a schedule.
  - aws_lambda_function.stop_ec2_instance: Lambda function to stop EC2 instances based on a schedule.

- *CloudWatch Events:*
  - aws_cloudwatch_event_rule.start_ec2_rule: CloudWatch rule to trigger the start of EC2 instances at 9 AM Tunisia time (8 AM UTC) on weekdays.
  - aws_cloudwatch_event_rule.stop_ec2_rule: CloudWatch rule to trigger the stop of EC2 instances at 5 PM Tunisia time (4 PM UTC) on weekdays.
  - aws_cloudwatch_event_target.start_ec2_target: Target configuration for the start EC2 Lambda function.
  - aws_cloudwatch_event_target.stop_ec2_target: Target configuration for the stop EC2 Lambda function.

### Outputs

- instance_ids: A list of IDs of the created EC2 instances, which are used as input for the Lambda functions to manage their lifecycle.
