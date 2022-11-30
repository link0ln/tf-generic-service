variable "argocd_address" {
  type = string
  default = "argocd-htz.wvservices.com:443"
}
variable "argocd_token" {
  type = string
}
variable "helm_repo" {
  type = string
  default = "https://github.com/link0ln/helm-generic.git"
}
variable "project_name" {
  type = string
}
variable "project_env" {
  type = string
}
variable "vault_address" {
  type = string
  default = "https://vaultwp.wvservices.com"
}
variable "vault_token" {
  type = string
}
