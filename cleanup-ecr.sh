#!/bin/bash

# Script de nettoyage AWS ECR
# Ce script supprime les repositories ECR et toutes leurs images
# ⚠️ ATTENTION : Cette action est irréversible !

set -e

REGION="${AWS_REGION:-us-east-1}"
REPOSITORY_PREFIX="${ECR_REPOSITORY_PREFIX:-meteo}"

REPOSITORIES=(
  "${REPOSITORY_PREFIX}-weather-service"
  "${REPOSITORY_PREFIX}-location-service"
  "${REPOSITORY_PREFIX}-weather-report-service"
)

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Script de Nettoyage AWS ECR ===${NC}"
echo ""
echo "Région AWS: $REGION"
echo "Préfixe des repositories: $REPOSITORY_PREFIX"
echo ""
echo "Repositories qui seront supprimés:"
for repo in "${REPOSITORIES[@]}"; do
  echo "  - $repo"
done
echo ""
echo -e "${RED}⚠️  ATTENTION : Cette action est irréversible !${NC}"
echo -e "${RED}   Toutes les images et repositories seront supprimés définitivement.${NC}"
echo ""

# Demander confirmation
read -p "Voulez-vous continuer ? (tapez 'yes' pour confirmer): " confirm

if [ "$confirm" != "yes" ]; then
  echo -e "${YELLOW}Annulé. Aucune action effectuée.${NC}"
  exit 0
fi

echo ""
echo "Début du nettoyage..."
echo ""

# Fonction pour supprimer un repository
delete_repository() {
  local repo=$1
  local exists=$(aws ecr describe-repositories --repository-names "$repo" --region "$REGION" 2>/dev/null || echo "NOT_FOUND")
  
  if [ "$exists" = "NOT_FOUND" ]; then
    echo -e "  ${YELLOW}⚠ $repo n'existe pas, ignoré${NC}"
    return
  fi
  
  echo -e "  ${YELLOW}Suppression de $repo...${NC}"
  
  # Supprimer toutes les images (obligatoire avant de supprimer le repository)
  IMAGE_IDS=$(aws ecr list-images \
    --repository-name "$repo" \
    --region "$REGION" \
    --query 'imageIds[*]' \
    --output json 2>/dev/null || echo "[]")
  
  if [ "$IMAGE_IDS" != "[]" ] && [ -n "$IMAGE_IDS" ]; then
    echo -e "    Suppression des images..."
    aws ecr batch-delete-image \
      --repository-name "$repo" \
      --region "$REGION" \
      --image-ids "$IMAGE_IDS" > /dev/null 2>&1 || true
  fi
  
  # Supprimer le repository
  aws ecr delete-repository \
    --repository-name "$repo" \
    --region "$REGION" \
    --force > /dev/null 2>&1
  
  echo -e "  ${GREEN}✓ $repo supprimé${NC}"
}

# Supprimer chaque repository
for repo in "${REPOSITORIES[@]}"; do
  delete_repository "$repo"
done

echo ""
echo -e "${GREEN}=== Nettoyage terminé avec succès ! ===${NC}"
echo ""
echo "Tous les repositories et leurs images ont été supprimés."
echo ""
echo "💡 Pour vérifier qu'il n'y a plus de repositories :"
echo "   aws ecr describe-repositories --region $REGION"
echo ""
echo "💡 Pour vérifier les coûts AWS :"
echo "   https://console.aws.amazon.com/billing/"

