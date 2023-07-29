# Terraform Swarm AWS

## Static Testing

```shell
terraform fmt -check -recursive .
terraform init -backend=false
terraform validate .
```

## Dynamic Testing

Create the `test/secret.backend.tf` file:

```tf
terraform {
  backend "s3" {
    region = "BUCKET_REGION"
    bucket = "BUCKET_NAME"
    key    = "test/foo.tfstate"
  }
}
```

Create the `test/secret.tfvars` file:

```tfvars
base_domain     = "example.com"
subdomain_label = "foo"
deployment_config = {
  git_platform = "github"
  git_url      = "https://github.com/foo/foo.git"
  git_ref      = "main"
}
```

Test:

```shell
cd test
terraform init
terraform validate .
terraform plan -var-file=secret.tfvars -out create.tfplan
terraform apply create.tfplan
terraform plan -var-file=secret.tfvars -destroy -out destroy.tfplan
terraform apply destroy.tfplan
```
