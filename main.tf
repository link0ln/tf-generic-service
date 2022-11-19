provider "vault" {
  address   = var.vault_address
  token     = var.vault_token
}

resource "vault_mount" "service_name" {
  path        = "${var.service_namespace}"
  type        = "kv"
  options     = { version = "2" }
  description = "Service ${var.service_name} from ${var.service_repo}"
}

resource "vault_kv_secret_v2" "secret_env" {
  mount                      = vault_mount.service_name.path
  name                       = "${var.service_name}/${var.service_env}/env"
  cas                        = 1
  delete_all_versions        = true
  data_json                  = jsonencode(
  {
    name1      = "value1",
    name2      = "value2",
    name3      = "value3",
  }
  )
}

resource "vault_kv_secret_v2" "secret_kv" {
  mount                      = vault_mount.service_name.path
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
  name   = "${var.service_namespace}-${var.service_name}-${var.service_env}-service-policy"
  policy = <<EOT
    path "${var.service_namespace}/data/${var.service_name}/${var.service_env}*" {
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

provider "argocd" {
  server_addr = "${var.argocd_address}"
  auth_token  = "${var.argocd_token}"
}

resource "argocd_repository" "private" {
  repo     = "${var.service_repo}"
}

resource "argocd_project" "target_project" {
  metadata {
    name      = "${var.argocd_project}"
    labels = {
      acceptance = "true"
    }
    annotations = {
      "this.is.a.really.long.nested.key" = ""
    }
  }

  spec {
    description  = "${var.argocd_project} project"
    source_repos = ["${var.service_repo}"]

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "${var.service_namespace}" 
    }
    # need to be inspected to allow how to create namespaces
    #cluster_resource_blacklist {
    #  group = "*"
    #  kind  = "*"
    #}
    cluster_resource_whitelist {
      group = "rbac.authorization.k8s.io"
      kind  = "ClusterRoleBinding"
    }
    cluster_resource_whitelist {
      group = "rbac.authorization.k8s.io"
      kind  = "ClusterRole"
    }
    cluster_resource_whitelist {
      group = "*"
      kind  = "Namespace"
    }
    namespace_resource_blacklist {
      group = "networking.k8s.io"
      kind  = "Ingress"
    }
    namespace_resource_whitelist {
      group = "*"
      kind  = "*"
    }
    orphaned_resources {
      warn = true

      ignore {
        group = "apps/v1"
        kind  = "Deployment"
        name  = "ignored1"
      }
      ignore {
        group = "apps/v1"
        kind  = "Deployment"
        name  = "ignored2"
      }
    }
    role {
      name = "deploy-role"
      description = "Role for use in argocli from pipleine"
      policies = [
        "p, proj:${var.argocd_project}:deploy-role, applications, *, ${var.argocd_project}/*, allow",
      ]
    }
    sync_window {
      kind         = "allow"
      applications = ["${var.service_name}"]
      namespaces   = ["${var.service_namespace}"]
      duration     = "12h"
      schedule     = "0 * * * *"
      manual_sync  = false
    }
  }
}

resource "argocd_project_token" "secret" {
  depends_on = [
    argocd_project.target_project
  ]
  count        = 1
  project      = "${var.argocd_project}"
  role         = "deploy-role"
  description  = "for deploy from pipline"
}

#output "argocd_jwt-token" {
#  value = argocd_project_token.secret
#  sensitive = true
#}

#resource "local_file" "private_key" {
#    content  = argocd_project_token.secret[0].jwt
#    filename = "argocd-token.jwt"
#}


resource "argocd_application" "app_argocd_application" {
  metadata {
    name      = "${var.service_name}-${var.service_env}"
    #namespace = "${var.service_namespace}"
    labels = {
      service    = "${var.service_name}-${var.service_env}-service"
      managed-by = "Terraform"
    }
  }

  depends_on = [
    argocd_project.target_project
  ]

  wait = false

  spec {
    project = argocd_project.target_project.metadata[0].name
    source {
      repo_url        = argocd_repository.private.repo
      path            = "charts/generic-service"
      target_revision = "${var.service_repo_ver}"
      #helm {
      #  parameter {
      #    name  = "fullnameOverride"
      #    value = "${var.service_name}"
      #  }
      #  parameter {
      #    name  = "vault.address"
      #    value = "${var.vault_address}"
      #  }
      #  parameter {
      #    name  = "vault.token"
      #    value = "${vault_token.app-service-token.client_token}"
      #  }
      #  parameter {
      #    name  = "namespace"
      #    value = "${var.service_namespace}"
      #  }
      #  value_files  = ["values.yaml"]
      #  release_name = var.service_name
      #}
      plugin {
        name = "vault-python-wrapper-helm"
        env {
          name = "AVP_SECRET"
          value = "${var.service_name}-vault-access"
        }
        env {
          name = "VAULT_ADDR"
          value = "${var.vault_address}"
        }
        #env {
        #  name = "AVP_TYPE"
        #  value = "vault"
        #}
        #env {
        #  name = "AVP_AUTH_TYPE"
        #  value = "token"
        #}
        env {
          name = "VAULT_TOKEN"
          value = "${vault_token.app-service-token.client_token}"
        }
        env {
          name = "PYDEBUG"
          value = 1
        }
        env {
          name = "HELM_VALUES"
          value = <<EOF
             {
               "namespace": "${var.service_namespace}",
               "fullnameOverride": "${var.service_name}",
               "podenv": "<path:${var.service_namespace}/${var.service_name}/${var.service_env}/env>",
               "image_repository": "<path:${var.service_namespace}/${var.service_name}/${var.service_env}/kv#image>",
               "image_tag": "<path:${var.service_namespace}/${var.service_name}/${var.service_env}/kv#tag>"
             }
          EOF
        }
      }
    }

    sync_policy {
      automated = {
        prune       = false
        self_heal   = false
        allow_empty = true
      }

      retry {
        limit = "5"
        backoff = {
          duration     = "30s"
          max_duration = "2m"
          factor       = "2"
        }
      }
    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "${var.service_namespace}"
    }
  }
}

