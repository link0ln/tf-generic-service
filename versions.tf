terraform {
  backend "s3" {
    bucket = "wavesprotocol-tf-state"
    key    = "kubernetes/inigma/terraform.tfstate"
    region = "eu-central-1"
    dynamodb_table = "wavesprotocol-terraform-state-locks"
    encrypt        = true
  }

  required_providers {
    vault = {
      source  = "vault"
      version = ">= 3.10.0"
    }
    argocd = {
      source  = "oboukili/argocd"
      version = "4.1.0"
    }
  }
}
