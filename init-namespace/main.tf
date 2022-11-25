provider "argocd" {
  server_addr = "${var.argocd_address}"
  auth_token  = "${var.argocd_token}"
}

resource "argocd_repository" "private" {
  repo     = "${var.service_repo}"
}

output "argocd_project_var" {
  value = "${var.argocd_project}"
}

output "argocd_repository_var" {
  value = "${var.service_repo}"
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
      applications = ["*"]
      namespaces   = ["${var.service_namespace}"]
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
  path        = "${var.service_namespace}"
  type        = "kv"
  options     = { version = "2" }
  description = "KV for namespace ${var.service_namespace} "
}
