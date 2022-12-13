provider "argocd" {
  server_addr = "${var.argocd_address}"
  auth_token  = "${var.argocd_token}"
}

#resource "argocd_repository" "private" {
#  repo     = "${var.helm_repo}"
#}
#
#resource "argocd_project" "target_project" {
#  metadata {
#    name      = "${var.project_name}-${var.service_env}"
#    labels = {
#      acceptance = "true"
#    }
#    annotations = {
#      "this.is.a.really.long.nested.key" = ""
#    }
#  }
#
#  spec {
#    description  = "${var.project_name}-${var.service_env} project"
#    source_repos = ["${var.helm_repo}"]
#
#    destination {
#      server    = "https://kubernetes.default.svc"
#      namespace = "${var.project_name}-${var.service_env}" 
#    }
#    # need to be inspected to allow how to create namespaces
#    #cluster_resource_blacklist {
#    #  group = "*"
#    #  kind  = "*"
#    #}
#    cluster_resource_whitelist {
#      group = "rbac.authorization.k8s.io"
#      kind  = "ClusterRoleBinding"
#    }
#    cluster_resource_whitelist {
#      group = "rbac.authorization.k8s.io"
#      kind  = "ClusterRole"
#    }
#    cluster_resource_whitelist {
#      group = "*"
#      kind  = "Namespace"
#    }
#    namespace_resource_blacklist {
#      group = "networking.k8s.io"
#      kind  = "Ingress"
#    }
#    namespace_resource_whitelist {
#      group = "*"
#      kind  = "*"
#    }
#    orphaned_resources {
#      warn = true
#
#      ignore {
#        group = "apps/v1"
#        kind  = "Deployment"
#        name  = "ignored1"
#      }
#      ignore {
#        group = "apps/v1"
#        kind  = "Deployment"
#        name  = "ignored2"
#      }
#    }
#    role {
#      name = "deploy-role"
#      description = "Role for use in argocli from pipleine"
#      policies = [
#        "p, proj:${var.project_name}-${var.service_env}:deploy-role, applications, *, ${var.project_name}-${var.service_env}/*, allow",
#      ]
#    }
#    sync_window {
#      kind         = "allow"
#      applications = ["*"]
#      namespaces   = ["${var.project_name}-${var.service_env}"]
#      duration     = "12h"
#      schedule     = "0 * * * *"
#      manual_sync  = false
#    }
#  }
#}
#
#resource "argocd_project_token" "secret" {
#  depends_on = [
#    argocd_project.target_project
#  ]
#  count        = 1
#  project      = "${var.project_name}-${var.service_env}"
#  role         = "deploy-role"
#  description  = "for deploy from pipline"
#}

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
    name      = "${var.project_name}-${var.service_name}-${var.service_env}"
    labels = {
      service    = "${var.service_name}-${var.service_env}-service"
      managed-by = "Terraform"
    }
  }

  #depends_on = [
  #  argocd_project.target_project
  #]

  wait = false

  spec {
    project = "${var.project_name}-${var.service_env}"
    source {
      repo_url        = var.helm_repo
      path            = "charts/generic-service"
      target_revision = "${var.helm_repo_ver}"
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
          #value = "${vault_token.app-service-token.client_token}"
          value = "${var.vault_token_generated}"
        }
        env {
          name = "PYDEBUG"
          value = 1
        }
        env {
          name = "HELM_VALUES"
          value = <<EOF
             {
                "namespace": "${var.project_name}-${var.service_env}",
                "fullnameOverride": "${var.service_name}-${var.service_env}",
                "podenv": "<path:${var.project_name}/${var.service_name}/${var.service_env}/env>",
                "image_repository": "<path:${var.project_name}/${var.service_name}/${var.service_env}/kv#image>",
                "image_tag": "<path:${var.project_name}/${var.service_name}/${var.service_env}/kv#tag>",
                "ingress.hosts[0].host": "${var.ingress_host}"
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
      sync_options = ["Validate=false","CreateNamespace=true"]
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
      namespace = "${var.project_name}-${var.service_env}"
    }
  }
}
