module "harbor_module" {
  source = "./modules/harbor"
  harbor_username = var.harbor_username
  harbor_password = var.harbor_password
  harbor_project_name =  var.project_name
}


provider "argocd" {
  server_addr = var.argocd_address
  auth_token  = var.argocd_token
}

resource "argocd_repository" "private" {
  repo     = var.helm_repo
}

#output "service_namespace_var" {
#  value = "${var.project_name}-${var.project_env}"
#}

#output "argocd_repository_var" {
#  value = var.helm_repo
#}


resource "argocd_project" "target_project" {
  metadata {
    name      = "${var.project_name}-${var.project_env}"
    labels = {
      acceptance = "true"
    }
    annotations = {
      "this.is.a.really.long.nested.key" = ""
    }
  }

  spec {
    description  = "${var.project_name}-${var.project_env} project"
    source_repos = ["${var.helm_repo}"]

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "${var.project_name}-${var.project_env}" 
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
        "p, proj:${var.project_name}-${var.project_env}:deploy-role, applications, *, ${var.project_name}-${var.project_env}/*, allow",
      ]
    }
    sync_window {
      kind         = "allow"
      applications = ["*"]
      namespaces   = ["${var.project_name}-${var.project_env}"]
      duration     = "12h"
      schedule     = "0 * * * *"
      manual_sync  = false
    }
  }
}


provider "vault" {
  address   = var.vault_address
  token     = var.vault_token
}

resource "vault_mount" "service_name" {
  path        = "${var.project_name}"
  type        = "kv"
  options     = { version = "2" }
  description = "KV for namespace ${var.project_name}"
}
