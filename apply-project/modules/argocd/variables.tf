variable "argocd_address" {
  type = string
}
variable "argocd_token" {
  type = string
}
variable "helm_repo" {
  type = string
}
variable "service_name" {
  type = string
}
variable "project_name" {
  type = string
}
variable "service_env" {
  type = string
}
variable "helm_repo_ver" {
  type = string
}
variable "vault_address" {
  type = string
}
variable "vault_token_generated" {
  type = string
}
variable "ingress_enabled" {
  type = string
}
variable "ingress_host" {
  type = string
}