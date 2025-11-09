#!/bin/bash
# Script to remove all the terraform files and folders
set -e
cd terraform
rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup
cd ..
echo --- Terraform state and config files removed ---