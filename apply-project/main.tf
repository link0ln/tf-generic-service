data "terraform_remote_state" "shared_services" {
  backend = "s3"
  config = {
    bucket = "wavesprotocol-tf-state"
    key    = "kubernetes/inigma/terraform-init.tfstate"
    region = "eu-central-1"
    dynamodb_table = "wavesprotocol-terraform-state-locks"
    encrypt        = true
  }
}

module "vault_module" {
  source = "./modules/vault"
  vault_address = var.vault_address
  vault_token = var.vault_token
  service_name = var.service_name
  service_namespace = var.service_namespace
  service_env = var.service_env
  service_image_repo = var.service_image_repo
  service_image_tag = var.service_image_tag
}

module "argocd_module" {
  source = "./modules/argocd"
  argocd_address = var.argocd_address
  argocd_token = var.argocd_token
  argocd_project = data.terraform_remote_state.shared_services.outputs.argocd_project_var
  service_repo = var.service_repo
  service_name = var.service_name
  service_namespace = var.service_namespace
  service_env = var.service_env
  argocd_repository = data.terraform_remote_state.shared_services.outputs.argocd_repository_var
  service_repo_ver = var.service_repo_ver
  vault_address = var.vault_address
  vault_token_generated = module.vault_module.vault-token-secret
}

