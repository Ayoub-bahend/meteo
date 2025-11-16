#!/bin/bash

# Script pour configurer l'environnement ECR automatiquement
# Ce script configure les variables d'environnement nécessaires pour Docker Compose

set -e

REGION="${AWS_REGION:-us-east-1}"

echo "🔧 Configuration de l'environnement ECR..."

# Récupérer l'ID du compte AWS
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

# Créer le fichier .env
cat > .env <<EOF
# Configuration générée automatiquement
ECR_REGISTRY=$ECR_REGISTRY
IMAGE_TAG=latest
EOF

echo "✅ Fichier .env créé avec succès !"
echo ""
echo "📝 Pour utiliser un tag spécifique, modifiez IMAGE_TAG dans .env"
echo "   Exemple: IMAGE_TAG=abc123def"
echo ""

# Option: Authentifier automatiquement
read -p "Voulez-vous vous authentifier à ECR maintenant ? (y/n): " auth
if [ "$auth" = "y" ] || [ "$auth" = "Y" ]; then
    echo "🔐 Authentification à ECR..."
    aws ecr get-login-password --region $REGION | \
        docker login --username AWS --password-stdin $ECR_REGISTRY
    echo "✅ Authentifié avec succès !"
else
    echo "💡 Pour vous authentifier plus tard, exécutez :"
    echo "   aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY"
fi

echo ""
echo "🚀 Vous pouvez maintenant utiliser :"
echo "   docker compose pull   # Pull les images depuis ECR"
echo "   docker compose up -d  # Lancer tous les services"
echo "   ./test-services.sh    # Tester les services"

