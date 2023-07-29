terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "base_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "base_domain" {
  type        = string
  description = "Required. Example: 'example.com'"
}

variable "subdomain_label" {
  type        = string
  default     = ""
  description = "Optional. Examples: 'blog', 'staging'"
}

locals {
  is_subdomain                = var.subdomain_label == "" || var.subdomain_label == "www" ? false : true
  fully_qualified_domain_name = local.is_subdomain ? var.base_domain : format("%s.%s", var.subdomain_label, var.base_domain)
}

resource "aws_eip" "eip" {
  domain = "vpc"
  tags = merge(
    var.tags,
    {
      Name = format("%s-%s", var.base_name, "eip")
      FQDN = local.fully_qualified_domain_name
    }
  )
}

output "eip_id" {
  value = aws_eip.eip.id
}

data "aws_route53_zone" "route53_zone" {
  name = "${var.base_domain}."
}

resource "aws_route53_record" "base_record" {
  count   = local.is_subdomain ? 0 : 1
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = ""
  type    = "A"
  ttl     = "300"
  records = [aws_eip.eip.public_ip]
}

resource "aws_route53_record" "www_record" {
  count   = local.is_subdomain ? 0 : 1
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "300"
  records = [var.base_domain]
}

resource "aws_route53_record" "subdomain_record" {
  count   = local.is_subdomain ? 1 : 0
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.subdomain_label
  type    = "A"
  ttl     = "300"
  records = [aws_eip.eip.public_ip]
}
