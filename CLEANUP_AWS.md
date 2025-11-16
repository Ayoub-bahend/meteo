# Guide de Nettoyage AWS ECR - Éviter les Coûts

Ce guide explique comment nettoyer vos ressources AWS ECR pour éviter des coûts inutiles.

## 📊 Coûts AWS ECR

### Ce qui est gratuit :
- ✅ Création des repositories (gratuit)
- ✅ Push/Pull d'images (gratuit)
- ✅ Premiers 500 MB de stockage par mois (gratuit)

### Ce qui coûte de l'argent :
- 💰 **Stockage d'images** : ~$0.10 par GB/mois après les 500 MB gratuits
- 💰 **Transfert de données** : si vous pull beaucoup d'images (généralement négligeable pour des tests)

## 🧹 Comment Nettoyer AWS ECR

### Option 1 : Supprimer les Images (Recommandé pour Tests)

Si vous voulez garder les repositories mais supprimer les images :

```bash
# 1. Lister tous les repositories
aws ecr describe-repositories --region us-east-1

# 2. Lister toutes les images dans un repository
aws ecr list-images --repository-name meteo-weather-service --region us-east-1

# 3. Supprimer toutes les images d'un repository (ATTENTION : irréversible !)
aws ecr batch-delete-image \
  --repository-name meteo-weather-service \
  --image-ids imageTag=latest \
  --region us-east-1

# Supprimer toutes les images d'un repository
aws ecr list-images --repository-name meteo-weather-service --region us-east-1 \
  --query 'imageIds[*]' --output json | \
  aws ecr batch-delete-image --repository-name meteo-weather-service --region us-east-1 --image-ids file:///dev/stdin
```

**Méthode plus simple - supprimer toutes les images :**
```bash
# Pour weather-service
aws ecr list-images --repository-name meteo-weather-service --region us-east-1 \
  | jq -r '.imageIds[] | [.imageDigest] | @json' | \
  while read imageId; do
    aws ecr batch-delete-image \
      --repository-name meteo-weather-service \
      --region us-east-1 \
      --image-ids "$imageId"
  done

# Répéter pour location-service et weather-report-service
```

### Option 2 : Supprimer Complètement les Repositories (Recommandé si Fin de Projet)

⚠️ **ATTENTION : Cette action est irréversible !**

```bash
# 1. Supprimer toutes les images d'abord (obligatoire)
aws ecr list-images --repository-name meteo-weather-service --region us-east-1 \
  --query 'imageIds[*]' --output json > image-ids.json

aws ecr batch-delete-image \
  --repository-name meteo-weather-service \
  --region us-east-1 \
  --image-ids file://image-ids.json

# 2. Supprimer le repository
aws ecr delete-repository \
  --repository-name meteo-weather-service \
  --region us-east-1 \
  --force  # Force la suppression même s'il y a des images

# Répéter pour les autres services
aws ecr delete-repository --repository-name meteo-location-service --region us-east-1 --force
aws ecr delete-repository --repository-name meteo-weather-report-service --region us-east-1 --force
```

**Script complet pour tout supprimer :**
```bash
#!/bin/bash
REGION="us-east-1"
REPOSITORIES=(
  "meteo-weather-service"
  "meteo-location-service"
  "meteo-weather-report-service"
)

for repo in "${REPOSITORIES[@]}"; do
  echo "Suppression de $repo..."
  
  # Supprimer toutes les images
  IMAGE_IDS=$(aws ecr list-images --repository-name $repo --region $REGION --query 'imageIds[*]' --output json)
  if [ "$IMAGE_IDS" != "[]" ] && [ "$IMAGE_IDS" != "null" ]; then
    echo "  Suppression des images..."
    aws ecr batch-delete-image \
      --repository-name $repo \
      --region $REGION \
      --image-ids "$IMAGE_IDS"
  fi
  
  # Supprimer le repository
  echo "  Suppression du repository..."
  aws ecr delete-repository \
    --repository-name $repo \
    --region $REGION \
    --force
  
  echo "✓ $repo supprimé"
done

echo "Tous les repositories ont été supprimés !"
```

### Option 3 : Via la Console AWS (Interface Graphique)

1. **Aller sur AWS Console** → ECR (Elastic Container Registry)
2. **Sélectionner la région** (us-east-1 par défaut)
3. **Pour chaque repository** :
   - Cliquer sur le repository
   - Sélectionner toutes les images
   - Cliquer sur "Delete"
   - Confirmer la suppression
   - Optionnel : Supprimer le repository entier

## 🔍 Vérifier les Coûts Actuels

```bash
# Voir la taille totale de stockage
aws ecr describe-repositories --region us-east-1 \
  --query 'repositories[*].[repositoryName,repositoryUri]' \
  --output table

# Voir le nombre d'images par repository
for repo in meteo-weather-service meteo-location-service meteo-weather-report-service; do
  echo "$repo: $(aws ecr list-images --repository-name $repo --region us-east-1 --query 'length(imageIds)') images"
done
```

## 📋 Checklist de Nettoyage Complète

Quand vous avez fini avec le projet :

- [ ] **1. Supprimer les images Docker** dans ECR
- [ ] **2. Supprimer les repositories ECR** (ou les garder vides si vous voulez les réutiliser)
- [ ] **3. Vérifier les coûts AWS** dans AWS Billing Console
- [ ] **4. (Optionnel) Désactiver le workflow GitHub Actions** si vous ne l'utilisez plus
  - Aller dans GitHub → Settings → Actions → Disable workflows
  - Ou supprimer le fichier `.github/workflows/client.yaml`
- [ ] **5. (Optionnel) Supprimer les secrets GitHub** (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
  - GitHub → Settings → Secrets and variables → Actions

## 🎯 Recommandation par Cas d'Usage

### Si vous faites juste des tests :
→ **Supprimer toutes les images** (Option 1)
- Les repositories vides sont gratuits
- Vous pouvez les réutiliser plus tard

### Si vous avez fini le projet :
→ **Supprimer complètement les repositories** (Option 2)
- Nettoyage complet
- Pas de traces dans AWS
- Aucun coût résiduel

### Si vous voulez garder pour référence :
→ **Garder uniquement les images importantes**
- Supprimer les tags `latest` et ne garder que des versions spécifiques
- Limiter à 2-3 images par repository

## ⚠️ Attention : Lifecycle Policies

AWS ECR supporte les **Lifecycle Policies** qui suppriment automatiquement les images anciennes :

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Supprimer les images de plus de 30 jours",
      "selection": {
        "tagStatus": "any",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 30
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

Pour créer une lifecycle policy :
```bash
aws ecr put-lifecycle-policy \
  --repository-name meteo-weather-service \
  --region us-east-1 \
  --lifecycle-policy-text file://lifecycle-policy.json
```

## 💡 Astuce : Estimation des Coûts

**Pour ce projet (3 services, ~150 MB par image) :**
- 3 images × 150 MB = 450 MB total
- **Coût mensuel : $0** (en dessous de 500 MB gratuit)

Si vous avez beaucoup d'images :
- 10 images × 150 MB = 1.5 GB
- Coût : (1.5 GB - 0.5 GB) × $0.10 = **$0.10/mois**

## 🚨 En Cas d'Urgence : Suppression Rapide

Si vous voyez des coûts inattendus et voulez tout supprimer rapidement :

```bash
# Script rapide - SUPPRIME TOUT SANS CONFIRMATION
REGION="us-east-1"
for repo in meteo-weather-service meteo-location-service meteo-weather-report-service; do
  aws ecr delete-repository --repository-name $repo --region $REGION --force 2>/dev/null || true
done
echo "Nettoyage terminé !"
```

## 📚 Ressources Utiles

- [AWS ECR Pricing](https://aws.amazon.com/ecr/pricing/)
- [AWS ECR CLI Documentation](https://docs.aws.amazon.com/cli/latest/reference/ecr/)
- [AWS Billing Console](https://console.aws.amazon.com/billing/)

---

**Note** : Les repositories ECR vides (sans images) sont **gratuits** et ne génèrent aucun coût. Vous pouvez les laisser si vous prévoyez de les réutiliser.

