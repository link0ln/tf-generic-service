terraform {
  backend "s3" {
    bucket = "wavesprotocol-tf-state"
    key    = "kubernetes/inigma/terraform-apply.tfstate"
    region = "eu-central-1"
    dynamodb_table = "wavesprotocol-terraform-state-locks"
    encrypt        = true
  }
  required_providers {
    argocd = {
      source  = "oboukili/argocd"
      version = "4.1.0"
    }
    vault = {
      source  = "vault"
      version = ">= 3.10.0"
    }
  }
}