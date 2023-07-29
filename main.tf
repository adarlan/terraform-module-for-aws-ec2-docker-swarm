terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "base_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "is_production" {
  type    = bool
  default = false
}

variable "instance_type" {
  type = string
}

variable "base_domain" {
  type        = string
  description = "Required. Examples: 'example.com'"
}

variable "subdomain_label" {
  type        = string
  default     = ""
  description = "Optional. Examples: 'blog', 'staging'"
}

variable "deployment_config" {
  type      = map(string)
  sensitive = true
}

locals {
  non_production_ingress = [
    { port = 80, description = "For web application users" },
    { port = 8080, description = "For debugging" }
  ]
  production_ingress = [
    { port = 443, description = "For web application users" },
    { port = 80, description = "For HTTPS redirection" }
  ]
}

module "dns_record" {
  source          = "./dns"
  base_name       = var.base_name
  base_domain     = var.base_domain
  subdomain_label = var.subdomain_label
}

resource "aws_ssm_parameter" "ssm_parameter" {
  name        = format("/%s/%s", var.base_name, "deployment_config")
  description = format("%s %s", "Deployment config for", var.base_name)
  type        = "SecureString"
  value       = jsonencode(var.deployment_config)
  tags        = merge(var.tags, { Name = format("%s-%s", var.base_name, "ssm_parameter") })
}

resource "aws_security_group" "security_group" {
  name        = format("%s-%s", var.base_name, "security_group")
  description = format("%s %s", "Inbound rules for", var.base_name)
  dynamic "ingress" {
    for_each = var.is_production ? local.production_ingress : local.non_production_ingress
    content {
      description = ingress.value["description"]
      from_port   = ingress.value["port"]
      to_port     = ingress.value["port"]
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = format("%s-%s", var.base_name, "security_group") })
}

data "aws_caller_identity" "caller_identity" {}

data "aws_ami" "ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["custom-swarm-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  owners = [data.aws_caller_identity.caller_identity.account_id]
}

resource "aws_instance" "instance" {
  ami             = data.aws_ami.ami.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.security_group.name]
  tags            = merge(var.tags, { Name = format("%s-%s", var.base_name, "instance") })
  iam_instance_profile = "AmazonSSMRoleForInstancesQuickSetup"
  user_data            = <<-EOF
    #!/bin/bash
    echo "export SSMParameterName=${aws_ssm_parameter.ssm_parameter.name}" >> /home/ec2-user/.bashrc
  EOF
  user_data_replace_on_change = true
}

resource "aws_eip_association" "eip_instance" {
  instance_id   = aws_instance.instance.id
  allocation_id = module.dns_record.eip_id
}
