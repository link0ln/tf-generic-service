#!/bin/bash

terraform workspace select default
terraform init
terraform destroy -var-file="inigma-prod.tfvars" -auto-approve

terraform workspace select dev
terraform init
terraform destroy -var-file="inigma-dev.tfvars" -auto-approve


terraform workspace select default
terraform init 
terraform apply -var-file="inigma-prod.tfvars" -auto-approve

terraform workspace select dev
terraform init
terraform apply -var-file="inigma-dev.tfvars" -auto-approve
