#!/bin/bash
#
# This script stops and removes any local Docker containers
# created from the project's image, and then removes the
# project image AND its base image for a complete local cleanup.
#

set -e
echo "--- Starting local Docker cleanup ---"

# 1. Get Region from terraform/variables.tf
export AWS_REGION=$(grep -A 3 'variable "region"' terraform/variables.tf | grep 'default' | cut -d '"' -f 2)

# 2. Get AWS Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 3. Get App Name from terraform/variables.tf
export APP_NAME=$(grep -A 3 'variable "app_name"' terraform/variables.tf | grep 'default' | cut -d '"' -f 2)

# 4. Construct the full image URLs
export APP_IMAGE_TAG="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}-backend-repo:latest"
export BASE_IMAGE_TAG="public.ecr.aws/lambda/python:3.10"

echo "Cleaning up containers and images for:"
echo "  App: $APP_IMAGE_TAG"
echo "  Base: $BASE_IMAGE_TAG"

# 5. Find, stop, and remove containers based on the app image
CONTAINER_IDS=$(docker ps -a -q --filter "ancestor=$APP_IMAGE_TAG")

if [ -z "$CONTAINER_IDS" ]; then
  echo "No local containers found for the app image."
else
  echo "Found app containers. Stopping and removing them..."
  docker stop $CONTAINER_IDS
  docker rm $CONTAINER_IDS
fi

# 6. Remove the local images
echo "Removing local app image..."
docker rmi -f $APP_IMAGE_TAG

echo "Removing local base image..."
docker rmi -f $BASE_IMAGE_TAG

echo "--- Local Docker cleanup complete ---"