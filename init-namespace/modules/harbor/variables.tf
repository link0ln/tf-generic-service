variable "harbor_username" {
  type = string
}
variable "harbor_password" {
  type = string
}
variable "harbor_url" {
  type = string
  default = "https://registry.wvservices.com"
}
variable "harbor_project_name" {
  type = string
}