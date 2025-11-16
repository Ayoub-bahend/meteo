#!/bin/bash

# Script pour nettoyer les ressources EKS existantes qui empêchent Terraform de créer le cluster
# Utilisez ce script si vous obtenez des erreurs "AlreadyExistsException"

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-meteo-cluster}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo -e "${YELLOW}🧹 Nettoyage des ressources EKS existantes${NC}"
echo "Cluster: $CLUSTER_NAME"
echo "Région: $AWS_REGION"
echo ""

# 1. Supprimer l'alias KMS
echo -e "${YELLOW}1. Suppression de l'alias KMS...${NC}"
ALIAS_NAME="alias/eks/$CLUSTER_NAME"
if aws kms list-aliases --region $AWS_REGION --query "Aliases[?AliasName=='$ALIAS_NAME'].AliasName" --output text | grep -q "$ALIAS_NAME"; then
    echo "   Alias trouvé: $ALIAS_NAME"
    # Récupérer la clé KMS associée
    KEY_ID=$(aws kms list-aliases --region $AWS_REGION --query "Aliases[?AliasName=='$ALIAS_NAME'].TargetKeyId" --output text)
    if [ -n "$KEY_ID" ]; then
        echo "   Clé KMS associée: $KEY_ID"
        # Supprimer l'alias
        aws kms delete-alias --alias-name "$ALIAS_NAME" --region $AWS_REGION
        echo -e "   ${GREEN}✓ Alias KMS supprimé${NC}"
    fi
else
    echo -e "   ${GREEN}✓ Aucun alias KMS trouvé${NC}"
fi

# 2. Supprimer le groupe de logs CloudWatch
echo -e "${YELLOW}2. Suppression du groupe de logs CloudWatch...${NC}"
LOG_GROUP_NAME="/aws/eks/$CLUSTER_NAME/cluster"
if aws logs describe-log-groups --region $AWS_REGION --log-group-name-prefix "$LOG_GROUP_NAME" --query "logGroups[?logGroupName=='$LOG_GROUP_NAME'].logGroupName" --output text | grep -q "$LOG_GROUP_NAME"; then
    echo "   Groupe de logs trouvé: $LOG_GROUP_NAME"
    aws logs delete-log-group --log-group-name "$LOG_GROUP_NAME" --region $AWS_REGION
    echo -e "   ${GREEN}✓ Groupe de logs CloudWatch supprimé${NC}"
else
    echo -e "   ${GREEN}✓ Aucun groupe de logs trouvé${NC}"
fi

# 3. Vérifier s'il existe un cluster EKS
echo -e "${YELLOW}3. Vérification du cluster EKS...${NC}"
if aws eks describe-cluster --name "$CLUSTER_NAME" --region $AWS_REGION >/dev/null 2>&1; then
    echo -e "   ${RED}⚠️  ATTENTION: Un cluster EKS existe déjà avec le nom '$CLUSTER_NAME'${NC}"
    echo "   Vous devez le supprimer manuellement ou utiliser un nom différent."
    echo "   Commande: aws eks delete-cluster --name $CLUSTER_NAME --region $AWS_REGION"
    exit 1
else
    echo -e "   ${GREEN}✓ Aucun cluster EKS existant${NC}"
fi

echo ""
echo -e "${GREEN}✅ Nettoyage terminé !${NC}"
echo ""
echo "Vous pouvez maintenant relancer:"
echo "  terraform plan"
echo "  terraform apply"

