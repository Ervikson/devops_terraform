#!/bin/bash
# deploy.sh

# Получаем значения из Terraform
export CLOUD_ID=$(terraform -chdir=terraform output -raw cloud_id)
export REGISTRY_ID=$(terraform -chdir=terraform output -raw registry_id)

# Создаем .env файл
cat > .env << EOF
CLOUD_ID=$CLOUD_ID
REGISTRY_ID=$REGISTRY_ID
EOF


docker compose up -d