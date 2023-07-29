module "swarm" {
  source    = "./.."
  base_name = "rolling_stones"
  is_production = false
  instance_type = "t2.micro"
  base_domain     = var.base_domain
  subdomain_label = var.subdomain_label
  deployment_config = var.deployment_config
}

variable "base_domain" {
  type = string
}

variable "subdomain_label" {
  type = string
}

variable "deployment_config" {
  type = map(string)
  sensitive = true
}
