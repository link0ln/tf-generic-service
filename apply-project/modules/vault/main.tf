provider "vault" {
  address   = var.vault_address
  token     = var.vault_token
}

resource "vault_kv_secret_v2" "secret_env" {
  mount                      = "${var.vault_wallet_name}"
  name                       = "${var.service_name}/${var.service_env}/env"
  cas                        = 1
  delete_all_versions        = true
  data_json                  = jsonencode(
  {
    "${var.service_env}-name1"      = "value1",
    "${var.service_env}-name2"      = "value2",
    "${var.service_env}-name3"     = "value3",
  }
  )
}

resource "vault_kv_secret_v2" "secret_kv" {
  mount                      = "${var.vault_wallet_name}"
  name                       = "${var.service_name}/${var.service_env}/kv"
  cas                        = 1
  delete_all_versions        = true
  data_json                  = jsonencode(
  {
    image    = var.service_image_repo,
    tag      = var.service_image_tag,
  }
  )
}

resource "vault_policy" "service-policy" {
  name   = "${var.vault_wallet_name}-${var.service_name}-${var.service_env}-service-policy"
  policy = <<EOT
    path "${var.vault_wallet_name}/data/${var.service_name}/${var.service_env}*" {
      capabilities = ["create", "update", "delete", "read", "list"]
    }
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_token" "app-service-token" {
#  role_name = "${var.service_name}-app"
  policies = ["default", vault_policy.service-policy.name]
  no_parent = true
  ttl = "100000h"
  explicit_max_ttl = "100000h"
  renewable = false
  metadata = {
    "purpose" = "service-account"
  }
}

output "vault-token-secret" {
  value = vault_token.app-service-token.client_token
}
