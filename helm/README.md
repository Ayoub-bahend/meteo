# Helm Charts pour Meteo Microservices

Ce répertoire contient les Helm charts pour déployer les microservices Meteo sur Kubernetes.

## Structure

```
helm/meteo-app/
├── Chart.yaml                    # Métadonnées du chart
├── values.yaml                   # Valeurs par défaut
├── templates/
│   ├── _helpers.tpl             # Templates helpers
│   ├── namespace.yaml           # Namespace Kubernetes
│   ├── secret.yaml              # Secret pour ECR
│   ├── serviceaccount.yaml      # Service Account
│   ├── weather-service.yaml     # Déploiement Weather Service
│   ├── location-service.yaml    # Déploiement Location Service
│   └── weather-report-service.yaml  # Déploiement Weather Report Service
└── README.md                     # Ce fichier
```

## Installation

### Prérequis

1. Kubernetes cluster configuré (EKS)
2. `kubectl` configuré pour le cluster
3. `helm` installé (>= 3.0)
4. Secret ECR créé dans le namespace

### Installation Simple

```bash
# Variables nécessaires
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-east-1"
export ECR_TOKEN=$(aws ecr get-login-password --region $AWS_REGION)

# Installer le chart
helm upgrade --install meteo-app ./helm/meteo-app \
  --namespace meteo \
  --create-namespace \
  --set global.awsAccountId=$AWS_ACCOUNT_ID \
  --set global.awsRegion=$AWS_REGION \
  --set global.ecrToken=$ECR_TOKEN \
  --set global.imageTag=latest
```

### Installation avec Fichier Values Personnalisé

```bash
# Créer un fichier values-personnalise.yaml
cat > values-personnalise.yaml <<EOF
global:
  awsAccountId: "$AWS_ACCOUNT_ID"
  awsRegion: "$AWS_REGION"
  ecrToken: "$ECR_TOKEN"
  imageTag: "latest"

weatherService:
  replicaCount: 2

locationService:
  replicaCount: 2

weatherReportService:
  replicaCount: 2
EOF

# Installer
helm upgrade --install meteo-app ./helm/meteo-app \
  --namespace meteo \
  --create-namespace \
  -f values-personnalise.yaml
```

## Mise à Jour

```bash
# Mettre à jour vers une nouvelle version d'image
helm upgrade meteo-app ./helm/meteo-app \
  --namespace meteo \
  --set global.imageTag=<nouveau-tag> \
  --reuse-values

# Ou mettre à jour avec un nouveau token ECR
export ECR_TOKEN=$(aws ecr get-login-password --region us-east-1)
helm upgrade meteo-app ./helm/meteo-app \
  --namespace meteo \
  --set global.ecrToken=$ECR_TOKEN \
  --reuse-values
```

## Désinstallation

```bash
helm uninstall meteo-app -n meteo
```

## Configuration

Voir `values.yaml` pour toutes les options de configuration disponibles.

## Valeurs Importantes

- `global.awsAccountId` : ID du compte AWS (requis)
- `global.awsRegion` : Région AWS (requis)
- `global.ecrToken` : Token ECR pour pull les images (requis)
- `global.imageTag` : Tag de l'image Docker (défaut: latest)
- `weatherService.replicaCount` : Nombre de replicas Weather Service
- `locationService.replicaCount` : Nombre de replicas Location Service
- `weatherReportService.replicaCount` : Nombre de replicas Weather Report Service

## Vérification

```bash
# Voir les pods
kubectl get pods -n meteo

# Voir les services
kubectl get svc -n meteo

# Voir les logs
kubectl logs -n meteo deployment/weather-service
```

