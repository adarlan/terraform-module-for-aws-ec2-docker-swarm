module "swarm" {
  source          = "./.."
  base_name       = "astrix"
  is_production   = false
  instance_type   = "t2.micro"
  base_domain     = local.base_domain
  subdomain_label = "astrix"
  deployment_config = {
    git_platform = "github"
    git_url      = "https://github.com/adarlan/traefik-swarm-deployment.git"
    git_ref      = "main"
  }
}
