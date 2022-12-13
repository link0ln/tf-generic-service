variable "vault_address" {
  type = string
  default = "https://vaultwp.wvservices.com"
}
variable "vault_token" {
  type = string
}
variable "helm_repo" {
  type = string
  default = "https://github.com/link0ln/helm-generic.git"
}
variable "helm_repo_ver" {
  type = string
  default = "0.1.12"
}
variable "service_name" {
  type = string
}
variable "project_name" {
  type = string
}
variable "project_env" {
  type = string
}
variable "argocd_address" {
  type = string
  default = "argocd-htz.wvservices.com:443"
}
variable "argocd_token" {
  type = string
}
variable "harbor_url" {
  type = string
  default = "https://registry.wvservices.com"
}
variable "harbor_username" {
  type = string
}
variable "harbor_password" {
  type = string
}
variable "action" {
  type = string
}
variable "ingress_domain" {
  type = string
}
variable "cloudflare_token" {
  type = string
}
variable "cloudflare_target" {
  type = string
}
variable "cloudflare_zone_id" {
  type = string
}