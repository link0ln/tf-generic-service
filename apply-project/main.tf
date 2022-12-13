#data "terraform_remote_state" "shared_services" {
#  backend = "s3"
#  config = {
#    bucket = "wavesprotocol-tf-state"
#    key    = "kubernetes/inigma/terraform-init.tfstate"
#    region = "eu-central-1"
#    dynamodb_table = "wavesprotocol-terraform-state-locks"
#    encrypt        = true
#  }
#}

module "vault_module" {
  source = "./modules/vault"
  vault_address = var.vault_address
  vault_token = var.vault_token
  vault_wallet_name = var.project_name
  service_name = var.service_name
  service_env = var.project_env
  service_image_repo = "${var.harbor_url}/${var.project_name}/${var.service_name}"
  service_image_tag = "latest"
}

module "argocd_module" {
  source = "./modules/argocd"
  argocd_address = var.argocd_address
  argocd_token = var.argocd_token
  service_name = var.service_name
  project_name = var.project_name
  service_env = var.project_env
  helm_repo = var.helm_repo
  helm_repo_ver = var.helm_repo_ver
  vault_address = var.vault_address
  vault_token_generated = module.vault_module.vault-token-secret
  ingress_host = var.ingress_domain
}

module "cloudflare" {
  source = "./modules/cloudflare"
  cloudflare_token = var.cloudflare_token
  cloudflare_domain = var.ingress_domain
  cloudflare_target = var.cloudflare_target
  cloudflare_zone_id = var.cloudflare_zone_id
  cloudflare_target_type = "CNAME"
}

