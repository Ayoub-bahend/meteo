# Quick Start : Déploiement EKS

Guide rapide pour déployer les microservices Meteo sur EKS.

## 🚀 Déploiement en 5 Minutes

### Méthode 1 : Via GitHub Actions (Recommandé)

1. **Aller sur GitHub** → Actions → "Deploy to EKS"
2. **Cliquer sur "Run workflow"**
3. **Choisir** :
   - Action: `all`
   - Environment: `dev`
   - Image Tag: `latest`
4. **Cliquer sur "Run workflow"**

Cela va automatiquement :
1. ✅ Planifier Terraform
2. ✅ Créer le cluster EKS (15-20 minutes)
3. ✅ Configurer kubectl
4. ✅ Créer le secret ECR
5. ✅ Déployer l'application avec Helm

### Méthode 2 : Manuellement

#### Étape 1 : Configuration Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars si nécessaire
terraform init
terraform plan
terraform apply
cd ..
```

#### Étape 2 : Configurer kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name meteo-cluster
kubectl get nodes
```

#### Étape 3 : Créer le Secret ECR

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_TOKEN=$(aws ecr get-login-password --region us-east-1)
kubectl create namespace meteo
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=${ECR_TOKEN} \
  --namespace=meteo
```

#### Étape 4 : Déployer avec Helm

```bash
helm upgrade --install meteo-app ./helm/meteo-app \
  --namespace meteo \
  --create-namespace \
  --set global.awsAccountId=$AWS_ACCOUNT_ID \
  --set global.awsRegion=us-east-1 \
  --set global.imageTag=latest \
  --set global.ecrToken=$ECR_TOKEN
```

### Étape 5 : Vérifier le Déploiement

```bash
# Voir les pods
kubectl get pods -n meteo

# Voir les services
kubectl get svc -n meteo

# Obtenir l'URL du LoadBalancer
kubectl get svc weather-report-service -n meteo
```

### Étape 5 : Tester l'Application

```bash
# Via port-forward
kubectl port-forward -n meteo svc/weather-report-service 8083:8083

# Dans un autre terminal
curl http://localhost:8083/api/report/Paris
```

## 📋 Structure Créée

Après le déploiement, vous aurez :

```
AWS EKS Cluster (meteo-cluster)
└── Namespace: meteo
    ├── Deployment: weather-service (1 pod)
    ├── Deployment: location-service (1 pod)
    ├── Deployment: weather-report-service (1 pod)
    ├── Service: weather-service (ClusterIP)
    ├── Service: location-service (ClusterIP)
    ├── Service: weather-report-service (LoadBalancer)
    └── Secret: ecr-registry-secret
```

## 🔧 Commandes Utiles

```bash
# Voir les logs
kubectl logs -n meteo deployment/weather-service
kubectl logs -n meteo deployment/location-service
kubectl logs -n meteo deployment/weather-report-service

# Scale un service
kubectl scale deployment weather-service --replicas=3 -n meteo

# Mettre à jour une image
helm upgrade meteo-app ./helm/meteo-app \
  --namespace meteo \
  --set global.imageTag=<nouveau-tag> \
  --reuse-values

# Supprimer le déploiement
helm uninstall meteo-app -n meteo
```

## 🧹 Nettoyage

```bash
# Supprimer l'application
helm uninstall meteo-app -n meteo
kubectl delete namespace meteo

# Supprimer le cluster EKS
cd terraform
terraform destroy
```

## ⚠️ Coûts

- **EKS Cluster** : ~$72/mois
- **NAT Gateway** : ~$32/mois
- **EC2 Instances (2x t3.medium)** : ~$60/mois
- **LoadBalancer** : ~$16/mois

**Total** : ~$180-200/mois

💡 **Conseil** : Utilisez `terraform destroy` quand vous n'utilisez pas le cluster pour économiser.

