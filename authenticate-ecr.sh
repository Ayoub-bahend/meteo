#!/bin/bash

# Script pour s'authentifier à AWS ECR
# Ce script doit être exécuté avant docker compose pull

set -e

REGION="${AWS_REGION:-us-east-1}"

echo "🔐 Authentification à AWS ECR..."

# Vérifier si AWS CLI est installé
if ! command -v aws &> /dev/null; then
    echo "❌ Erreur: AWS CLI n'est pas installé"
    echo ""
    echo "📦 Pour installer AWS CLI sur Debian/Ubuntu :"
    echo "   sudo apt update"
    echo "   sudo apt install awscli"
    echo ""
    echo "📦 Ou utilisez la méthode manuelle :"
    echo "   curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'"
    echo "   unzip awscliv2.zip"
    echo "   sudo ./aws/install"
    echo ""
    echo "💡 Alternative : Si vous connaissez votre AWS Account ID, vous pouvez :"
    echo "   docker login -u AWS -p \$(aws ecr get-login-password --region us-east-1) <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com"
    exit 1
fi

# Récupérer l'ID du compte AWS
echo "🔍 Récupération de l'ID du compte AWS..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ Erreur: Impossible de récupérer l'ID du compte AWS"
    echo "   Vérifiez que AWS CLI est configuré: aws configure"
    exit 1
fi

# Construire l'URI du registry ECR
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "✓ AWS Account ID: $AWS_ACCOUNT_ID"
echo "✓ Région: $REGION"
echo "✓ ECR Registry: $ECR_REGISTRY"
echo ""

# Authentifier Docker avec ECR
echo "🔑 Authentification en cours..."
aws ecr get-login-password --region $REGION | \
    docker login --username AWS --password-stdin $ECR_REGISTRY

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Authentification réussie !"
    echo ""
    echo "🚀 Vous pouvez maintenant :"
    echo "   docker compose pull   # Pull les images depuis ECR"
    echo "   docker compose up -d  # Lancer tous les services"
else
    echo ""
    echo "❌ Échec de l'authentification"
    echo "   Vérifiez vos credentials AWS: aws configure"
    exit 1
fi

