# Guide de Déploiement EKS avec Terraform et Helm

Ce guide explique comment déployer vos microservices Meteo sur AWS EKS (Elastic Kubernetes Service) en utilisant Terraform pour créer le cluster et Helm pour déployer les applications.

## 📋 Table des Matières

1. [Prérequis](#prérequis)
2. [Architecture](#architecture)
3. [Étape 1 : Configuration Terraform](#étape-1--configuration-terraform)
4. [Étape 2 : Création du Cluster EKS](#étape-2--création-du-cluster-eks)
5. [Étape 3 : Configuration de kubectl](#étape-3--configuration-de-kubectl)
6. [Étape 4 : Configuration ECR pour Kubernetes](#étape-4--configuration-ecr-pour-kubernetes)
7. [Étape 5 : Déploiement avec Helm](#étape-5--déploiement-avec-helm)
8. [Étape 6 : Vérification et Tests](#étape-6--vérification-et-tests)
9. [Maintenance et Mises à Jour](#maintenance-et-mises-à-jour)
10. [Dépannage](#dépannage)

---

## Prérequis

### Outils Nécessaires

1. **AWS CLI** configuré avec les bonnes permissions
   ```bash
   aws --version
   aws configure list
   ```

2. **Terraform** >= 1.0
   ```bash
   terraform version
   # Installation: https://www.terraform.io/downloads
   ```

3. **kubectl** (Kubernetes CLI)
   ```bash
   kubectl version --client
   # Installation: https://kubernetes.io/docs/tasks/tools/
   ```

4. **Helm** >= 3.0
   ```bash
   helm version
   # Installation: https://helm.sh/docs/intro/install/
   ```

### Permissions AWS Requises

Votre utilisateur AWS doit avoir les permissions pour :
- Créer des VPC, sous-réseaux, NAT Gateways
- Créer et gérer des clusters EKS
- Créer des groupes de sécurité
- Créer des rôles IAM
- Accéder à ECR

**Rôle IAM recommandé** : `AdministratorAccess` (pour développement) ou un rôle personnalisé avec les permissions EKS/VPC/EC2/ECR.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS EKS Cluster                      │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Namespace: meteo                   │   │
│  │                                                 │   │
│  │  ┌──────────────┐  ┌──────────────┐           │   │
│  │  │   Weather    │  │  Location    │           │   │
│  │  │   Service    │  │   Service    │           │   │
│  │  │  (Port 8081) │  │  (Port 8082) │           │   │
│  │  └──────┬───────┘  └──────┬───────┘           │   │
│  │         │                  │                   │   │
│  │         └────────┬─────────┘                   │   │
│  │                  │                             │   │
│  │         ┌────────▼─────────┐                   │   │
│  │         │ Weather Report   │                   │   │
│  │         │    Service       │                   │   │
│  │         │  (Port 8083)     │                   │   │
│  │         │    └─> NLB       │                   │   │
│  │         └──────────────────┘                   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │           Node Group (EC2 Instances)            │   │
│  │         m6gd.medium (2-3 instances)              │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
                    AWS ECR (Images)
```

---

## Étape 1 : Configuration Terraform

### 1.1 Naviguer vers le répertoire Terraform

```bash
cd terraform
```

### 1.2 Copier et configurer terraform.tfvars

```bash
# Copier l'exemple
cp terraform.tfvars.example terraform.tfvars

# Éditer avec vos valeurs
nano terraform.tfvars
# ou
vim terraform.tfvars
```

**Variables importantes à configurer** :
```hcl
aws_region = "us-east-1"          # Votre région AWS
environment = "dev"                # dev, staging, prod
cluster_name = "meteo-cluster"     # Nom du cluster
kubernetes_version = "1.28"        # Version Kubernetes
node_instance_types = ["m6gd.medium"] # Type d'instances
```

### 1.3 Initialiser Terraform

```bash
# Télécharger les providers
terraform init
```

Cela va télécharger :
- Provider AWS
- Provider Kubernetes
- Provider Helm
- Module VPC
- Module EKS

---

## Étape 2 : Création du Cluster EKS

### 2.1 Planifier les Changements

```bash
# Voir ce qui sera créé
terraform plan
```

**Vérifiez** :
- ✅ VPC et sous-réseaux
- ✅ Cluster EKS
- ✅ Node Groups
- ✅ Security Groups
- ✅ NAT Gateways (coûts ~$0.045/heure)

**Temps estimé** : 15-20 minutes pour créer le cluster

### 2.2 Créer le Cluster

```bash
# Créer toutes les ressources
terraform apply
```

Tapez `yes` pour confirmer.

**⏱️ Temps d'attente** : 15-20 minutes

**Ressources créées** :
- ✅ 1 VPC avec 2 sous-réseaux publics et 2 privés
- ✅ 1 NAT Gateway
- ✅ 1 Cluster EKS
- ✅ 1 Node Group avec 2 instances EC2 (m6gd.medium)
- ✅ Security Groups et règles de sécurité

### 2.3 Vérifier les Outputs

```bash
# Voir les outputs importants
terraform output

# Sauvegarder les informations importantes
terraform output -json > ../eks-outputs.json
```

**Outputs importants** :
- `cluster_name` : Nom du cluster
- `configure_kubectl` : Commande pour configurer kubectl
- `cluster_endpoint` : URL du cluster

---

## Étape 3 : Configuration de kubectl

### 3.1 Configurer kubectl pour le Cluster

```bash
# Récupérer la commande depuis Terraform
terraform output configure_kubectl

# Ou directement :
aws eks update-kubeconfig --region us-east-1 --name meteo-cluster
```

### 3.2 Vérifier la Connexion

```bash
# Vérifier que vous pouvez communiquer avec le cluster
kubectl cluster-info

# Voir les nodes
kubectl get nodes

# Devrait afficher 2 nodes (si desired_size = 2)
```

**Exemple de sortie** :
```
NAME                                            STATUS   ROLES    AGE   VERSION
ip-10-0-1-xxx.ec2.internal                      Ready    <none>   5m    v1.28.x
ip-10-0-2-xxx.ec2.internal                      Ready    <none>   5m    v1.28.x
```

---

## Étape 4 : Configuration ECR pour Kubernetes

### 4.1 Obtenir le Token ECR

Kubernetes a besoin d'un secret pour pull les images depuis ECR :

```bash
# Récupérer l'ID du compte AWS
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")

# Obtenir le token ECR
export ECR_TOKEN=$(aws ecr get-login-password --region $AWS_REGION)

# Créer le secret Kubernetes
kubectl create namespace meteo

kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com \
  --docker-username=AWS \
  --docker-password=${ECR_TOKEN} \
  --namespace=meteo
```

### 4.2 Vérifier le Secret

```bash
kubectl get secret ecr-registry-secret -n meteo
```

---

## Étape 5 : Déploiement avec Helm

### 5.1 Préparer les Variables Helm

```bash
# Retourner à la racine du projet
cd ..

# Récupérer les valeurs nécessaires
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-east-1"
export IMAGE_TAG="latest"  # ou utiliser un SHA spécifique
```

### 5.2 Installer le Chart Helm

```bash
# Obtenir le token ECR (requis pour le secret)
export ECR_TOKEN=$(aws ecr get-login-password --region $AWS_REGION)

# Option 1 : Installation simple
helm upgrade --install meteo-app ./helm/meteo-app \
  --namespace meteo \
  --create-namespace \
  --set global.awsAccountId=$AWS_ACCOUNT_ID \
  --set global.awsRegion=$AWS_REGION \
  --set global.imageTag=$IMAGE_TAG \
  --set global.ecrToken=$ECR_TOKEN

# Option 2 : Utiliser un fichier values personnalisé
helm upgrade --install meteo-app ./helm/meteo-app \
  --namespace meteo \
  --create-namespace \
  --set global.awsAccountId=$AWS_ACCOUNT_ID \
  --set global.awsRegion=$AWS_REGION \
  --set global.ecrToken=$ECR_TOKEN \
  -f helm/meteo-app/values.yaml
```

### 5.3 Vérifier le Déploiement

```bash
# Voir les pods
kubectl get pods -n meteo

# Devrait afficher :
# NAME                                    READY   STATUS    RESTARTS   AGE
# location-service-xxx                    1/1     Running   0          2m
# weather-report-service-xxx              1/1     Running   0          2m
# weather-service-xxx                     1/1     Running   0          2m

# Voir les services
kubectl get svc -n meteo

# Voir les déploiements
kubectl get deployments -n meteo
```

**⏱️ Temps d'attente** : 2-5 minutes pour que tous les pods soient `Running`

---

## Étape 6 : Vérification et Tests

### 6.1 Vérifier l'État des Services

```bash
# Voir les logs d'un service
kubectl logs -n meteo deployment/weather-service
kubectl logs -n meteo deployment/location-service
kubectl logs -n meteo deployment/weather-report-service

# Voir les événements
kubectl get events -n meteo --sort-by='.lastTimestamp'
```

### 6.2 Accéder aux Services

#### Via Port-Forward (Développement)

```bash
# Terminal 1 - Weather Service
kubectl port-forward -n meteo svc/weather-service 8081:8081

# Terminal 2 - Location Service
kubectl port-forward -n meteo svc/location-service 8082:8082

# Terminal 3 - Weather Report Service
kubectl port-forward -n meteo svc/weather-report-service 8083:8083
```

#### Via LoadBalancer (Production)

Le service `weather-report-service` est configuré en type `LoadBalancer` :

```bash
# Obtenir l'URL du LoadBalancer
kubectl get svc weather-report-service -n meteo

# Attendre que EXTERNAL-IP soit assigné (peut prendre 2-5 minutes)
# Puis tester :
curl http://<EXTERNAL-IP>:8083/api/report/Paris
```

### 6.3 Tests des Endpoints

```bash
# Via port-forward ou LoadBalancer
curl http://localhost:8081/api/weather/Paris
curl http://localhost:8082/api/location/Paris
curl http://localhost:8083/api/report/Paris
```

---

## Maintenance et Mises à Jour

### Mettre à Jour une Image Docker

```bash
# 1. Build et push une nouvelle image vers ECR (via GitHub Actions ou manuellement)

# 2. Mettre à jour le déploiement Helm
helm upgrade meteo-app ./helm/meteo-app \
  --namespace meteo \
  --set global.awsAccountId=$AWS_ACCOUNT_ID \
  --set global.awsRegion=$AWS_REGION \
  --set global.imageTag=<nouveau-tag>

# 3. Vérifier le rollout
kubectl rollout status deployment/weather-service -n meteo
```

### Scale les Services

```bash
# Scale un service spécifique
kubectl scale deployment weather-service --replicas=3 -n meteo

# Ou via Helm
helm upgrade meteo-app ./helm/meteo-app \
  --namespace meteo \
  --set weatherService.replicaCount=3 \
  --reuse-values
```

### Scale le Node Group

```bash
# Modifier terraform.tfvars
node_group_desired_size = 3

# Appliquer
terraform apply
```

---

## Dépannage

### Erreurs Terraform

#### Erreur "AlreadyExistsException" pour KMS ou CloudWatch

Si vous obtenez des erreurs lors de `terraform apply` :

```
Error: creating KMS Alias: AlreadyExistsException
Error: creating CloudWatch Logs Log Group: ResourceAlreadyExistsException
```

**Solution** : Utilisez le script de nettoyage :

```bash
cd terraform
export CLUSTER_NAME="meteo-cluster"  # ou "meteo-cluster-dev"
export AWS_REGION="us-east-1"
./cleanup-existing-resources.sh
```

Puis relancez `terraform apply`.

📖 **Guide complet** : Consultez `terraform/TROUBLESHOOTING.md` pour toutes les solutions aux erreurs Terraform.

#### Autres Erreurs Terraform

- **Outputs non trouvés** : Le workflow GitHub Actions gère automatiquement ce cas
- **Permissions AWS** : Vérifiez que votre utilisateur a les permissions EKS/EC2/IAM
- **Cluster existe déjà** : Supprimez-le d'abord ou utilisez un nom différent

### Pods en Erreur

```bash
# Voir les logs d'un pod
kubectl logs <pod-name> -n meteo

# Décrire un pod pour voir les événements
kubectl describe pod <pod-name> -n meteo

# Problèmes courants :
# - Image pull errors → Vérifier le secret ECR
# - CrashLoopBackOff → Vérifier les logs
# - OutOfMemory → Augmenter les resources dans values.yaml
```

### Images ne se pullent pas depuis ECR

```bash
# Vérifier le secret
kubectl get secret ecr-registry-secret -n meteo

# Recréer le secret si nécessaire (voir Étape 4)
```

### Services non accessibles

```bash
# Vérifier les services
kubectl get svc -n meteo

# Vérifier les endpoints
kubectl get endpoints -n meteo

# Tester depuis un pod
kubectl run -it --rm debug --image=busybox --restart=Never -n meteo -- wget -O- http://weather-service:8081/api/weather/Paris
```

---

## Coûts Estimés

### Infrastructure AWS (environ)

- **EKS Cluster** : ~$0.10/heure (~$72/mois)
- **NAT Gateway** : ~$0.045/heure (~$32/mois)
- **EC2 Instances (2x m6gd.medium)** : ~$0.0416/heure × 2 (~$60/mois)
- **LoadBalancer (NLB)** : ~$0.0225/heure + trafic (~$16/mois)

**Total estimé** : ~$180-200/mois pour un environnement de développement

💡 **Conseil** : Arrêtez le cluster quand vous ne l'utilisez pas pour économiser :
```bash
terraform destroy  # ⚠️ Supprime tout
```

---

## Dépannage

### Erreur "AlreadyExistsException" pour KMS ou CloudWatch

Si vous obtenez des erreurs comme :
```
Error: creating KMS Alias: AlreadyExistsException
Error: creating CloudWatch Logs Log Group: ResourceAlreadyExistsException
```

**Solution** : Utilisez le script de nettoyage dans `terraform/` :

```bash
cd terraform
export CLUSTER_NAME="meteo-cluster"  # ou "meteo-cluster-dev"
export AWS_REGION="us-east-1"
./cleanup-existing-resources.sh
```

Puis relancez `terraform apply`.

📖 **Guide complet** : Consultez `terraform/TROUBLESHOOTING.md` pour toutes les solutions aux erreurs courantes.

### Autres Problèmes

- **Outputs Terraform non trouvés** : Le workflow GitHub Actions gère automatiquement ce cas avec un système de fallback
- **Permissions AWS** : Vérifiez que votre utilisateur a les permissions EKS/EC2/IAM nécessaires
- **Cluster existe déjà** : Supprimez-le d'abord ou utilisez un nom différent

## Nettoyage

### Supprimer les Déploiements Helm

```bash
helm uninstall meteo-app -n meteo
kubectl delete namespace meteo
```

### Supprimer le Cluster EKS

```bash
cd terraform
terraform destroy
```

**⚠️ ATTENTION** : Cela supprime TOUT (VPC, EKS, instances EC2, etc.)

### Nettoyer les Ressources Orphelines

Si `terraform destroy` échoue ou laisse des ressources orphelines :

```bash
cd terraform
./cleanup-existing-resources.sh
```

Ce script supprime :
- Les alias KMS orphelins
- Les groupes de logs CloudWatch orphelins
- Vérifie s'il reste un cluster EKS

---

## Prochaines Étapes

- [ ] Configurer Ingress Controller (ALB/NLB)
- [ ] Ajouter HTTPS/SSL avec cert-manager
- [ ] Configurer HPA (Horizontal Pod Autoscaler)
- [ ] Ajouter monitoring avec Prometheus/Grafana
- [ ] Configurer des backups avec Velero
- [ ] Ajouter CI/CD avec ArgoCD

