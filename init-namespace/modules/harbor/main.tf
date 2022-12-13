provider "harbor" {
  url      = var.harbor_url
  username = var.harbor_username
  password = var.harbor_password
}

resource "harbor_project" "hproject" {
    name                    = var.harbor_project_name
    public                  = false 
    vulnerability_scanning  = true  
    #enable_content_trust    = true
    storage_quota           = 5
}

resource "harbor_retention_policy" "main" {
    scope = harbor_project.hproject.id
    schedule = "daily"
    rule {
        n_days_since_last_pull = 30
        repo_matching = "**"
        tag_matching = "latest"
    }
}

resource "random_string" "readuser" {
  length           = 16
  special          = false
  override_special = ""
}

resource "random_string" "writeuser" {
  length           = 16
  special          = false
  override_special = ""
}

resource "harbor_robot_account" "read" {
  name        = "${var.harbor_project_name}-read"
  description = "Read access project ${var.harbor_project_name} robot account"
  secret      = random_string.readuser.result
  level       = "project"
  permissions {
    access {
      action   = "pull"
      resource = "repository"
    }
    kind      = "project"
    namespace = harbor_project.hproject.name
  }
}

resource "harbor_robot_account" "write" {
  name        = "${var.harbor_project_name}-write"
  description = "Write access project ${var.harbor_project_name} robot account"
  secret      = random_string.writeuser.result
  level       = "project"
  permissions {
    access {
      action   = "push"
      resource = "repository"
    }
    kind      = "project"
    namespace = harbor_project.hproject.name
  }
}


#resource "harbor_user" "read" {
#  username = "${var.harbor_project}-read"
#  password = random_string.readuser.result
#  full_name = "Read user for k8s, project ${var.harbor_project}"
#  email = "admin@wavesplatform.com"
#}
#
#resource "harbor_user" "write" {
#  username = "${var.harbor_project}-write"
#  password = random_string.writeuser.result
#  full_name = "Write user for k8s, project ${var.harbor_project}"
#  email = "admin@wavesplatform.com"
#}
#
#
#resource "harbor_project_member_user" "read" {
#  project_id    = harbor_project.hproject.id
#  user_name     = harbor_user.read.username
#  role          = "guest"
#}
#
#resource "harbor_project_member_user" "write" {
#  project_id    = harbor_project.hproject.id
#  user_name     = harbor_user.write.username
#  role          = "projectadmin"
#}


output "harbor_user_name_read" {
  description = "Read access user name"
  value       = harbor_robot_account.read.name
}

output "harbor_user_name_write" {
  description = "Write access user name"
  value       = harbor_robot_account.write.name
}

output "harbor_user_password_read" {
  description = "Read access user password"
  value       = random_string.readuser.result
}

output "harbor_user_password_write" {
  description = "Write access user password"
  value       = random_string.writeuser.result
}
