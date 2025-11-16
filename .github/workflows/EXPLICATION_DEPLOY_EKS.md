# 📖 Explication Simple du Workflow `deploy-eks.yaml`

Ce document explique **simplement** comment fonctionne le workflow GitHub Actions pour déployer votre application sur AWS EKS.

---

## 🎯 Vue d'Ensemble

Le fichier `deploy-eks.yaml` est un **workflow GitHub Actions** qui automatise le déploiement de vos microservices sur AWS EKS (Kubernetes).

**En résumé** : Quand vous cliquez sur "Run workflow" dans GitHub, ce fichier dit à GitHub :
1. "Va créer un cluster Kubernetes sur AWS"
2. "Va déployer mes 3 microservices dessus"
3. "Va me donner l'URL pour y accéder"

---

## 📋 Structure du Fichier

Le fichier est divisé en **4 sections principales** :

```
1. Déclencheurs (on:)          → Quand le workflow se lance
2. Variables d'environnement    → Configuration globale
3. Jobs (tâches)               → Ce qui est fait
4. Steps (étapes)              → Comment c'est fait
```

---

## 1️⃣ Section `on:` - Quand le Workflow se Lance

```yaml
on:
  workflow_dispatch:    # Déclenchement manuel
    inputs:             # Paramètres que vous choisissez
      action:           # Quelle action faire ?
      environment:      # Dans quel environnement ?
      image_tag:        # Quelle version d'image Docker ?
  push:                 # Déclenchement automatique
    branches: [main]    # Quand vous poussez sur main
    paths:              # Si vous modifiez ces fichiers
      - 'terraform/**'
      - 'helm/**'
```

### 🎬 Exemple Concret

**Scénario 1 : Déclenchement manuel**
```
Vous allez sur GitHub → Actions → "Deploy to EKS" → "Run workflow"
Vous choisissez :
  - Action: "all"          → Faire tout (plan + apply + deploy)
  - Environment: "dev"     → Environnement de développement
  - Image Tag: "latest"    → Utiliser la dernière image Docker
```

**Scénario 2 : Déclenchement automatique**
```
Vous modifiez un fichier dans terraform/ ou helm/
Vous faites : git push origin main
→ Le workflow se lance automatiquement !
```

---

## 2️⃣ Section `env:` - Variables Globales

```yaml
env:
  AWS_REGION: us-east-1           # Région AWS
  TERRAFORM_DIR: terraform        # Dossier Terraform
  HELM_CHART_DIR: helm/meteo-app  # Dossier Helm
  NAMESPACE: meteo                # Namespace Kubernetes
```

### 💡 Pourquoi ?

Ces variables sont utilisées **partout** dans le workflow. Si vous changez la région, vous changez juste ici !

**Exemple** : Si vous voulez déployer en Europe :
```yaml
AWS_REGION: eu-west-1  # Au lieu de us-east-1
```

---

## 3️⃣ Section `jobs:` - Les Tâches Principales

Le workflow contient **4 jobs** (tâches) :

### Job 1 : `terraform-plan` 📋

**Rôle** : Créer un **plan** Terraform (simulation, ne crée rien)

```yaml
terraform-plan:
  if: action == 'plan' || action == 'all'
  steps:
    1. Checkout code              # Télécharger le code
    2. Configure AWS credentials # Se connecter à AWS
    3. Setup Terraform            # Installer Terraform
    4. Terraform Init             # Initialiser Terraform
    5. Terraform Plan             # Créer le plan
    6. Upload Plan                # Sauvegarder le plan
```

**Exemple concret** :
```
Terraform Plan va dire :
"Je vais créer :
  - 1 VPC (réseau virtuel)
  - 1 cluster EKS
  - 2 node groups (machines)
  - 1 LoadBalancer
Coût estimé : ~$180/mois"
```

**Résultat** : Un fichier `tfplan` qui contient ce qui sera créé (sans le créer encore)

---

### Job 2 : `terraform-apply` 🏗️

**Rôle** : **Créer réellement** le cluster EKS sur AWS

```yaml
terraform-apply:
  needs: terraform-plan  # Attendre que le plan soit fait
  if: action == 'apply' || action == 'all'
  steps:
    1. Download Plan              # Récupérer le plan
    2. Terraform Apply            # CRÉER le cluster (15-20 min)
    3. Get Cluster Name           # Récupérer le nom du cluster
    4. Configure kubectl          # Configurer kubectl
    5. Verify connection          # Vérifier que ça marche
```

**Exemple concret** :
```
Terraform Apply va :
1. Créer un VPC sur AWS
2. Créer un cluster EKS (Kubernetes)
3. Créer 2 machines EC2 pour les pods
4. Configurer la sécurité réseau
5. Attendre 15-20 minutes ⏳
```

**Résultat** : Un cluster EKS fonctionnel sur AWS !

---

### Job 3 : `deploy-helm` 🚀

**Rôle** : **Déployer vos microservices** sur le cluster EKS

```yaml
deploy-helm:
  if: action == 'deploy-helm' || action == 'all'
  steps:
    1. Get Cluster Info           # Récupérer les infos du cluster
    2. Configure kubectl          # Se connecter au cluster
    3. Setup Helm                 # Installer Helm
    4. Get AWS Account ID          # Récupérer l'ID du compte AWS
    5. Get ECR Token              # Token pour accéder à ECR
    6. Create ECR Secret          # Secret Kubernetes pour ECR
    7. Deploy with Helm           # DÉPLOYER les services
    8. Verify Deployment          # Vérifier que tout est OK
    9. Get LoadBalancer URL       # Récupérer l'URL publique
```

**Exemple concret** :
```
Deploy Helm va :
1. Se connecter au cluster EKS créé
2. Créer un secret pour accéder aux images Docker dans ECR
3. Déployer weather-service (1 pod)
4. Déployer location-service (1 pod)
5. Déployer weather-report-service (1 pod + LoadBalancer)
6. Attendre que tous les pods soient prêts
7. Vous donner l'URL : http://a1b2c3d4.us-east-1.elb.amazonaws.com:8083
```

**Résultat** : Vos 3 microservices tournent sur Kubernetes !

---

### Job 4 : `terraform-destroy` 🗑️

**Rôle** : **Supprimer** tout ce qui a été créé (pour économiser de l'argent)

```yaml
terraform-destroy:
  if: action == 'destroy'
  steps:
    1. Uninstall Helm Release     # Supprimer les services
    2. Delete Namespace           # Supprimer le namespace
    3. Terraform Destroy          # SUPPRIMER le cluster
```

**Exemple concret** :
```
Terraform Destroy va :
1. Supprimer tous les pods Kubernetes
2. Supprimer le namespace "meteo"
3. Supprimer le cluster EKS
4. Supprimer le VPC
5. Supprimer les machines EC2
→ Plus de coûts ! 💰
```

**Résultat** : Tout est supprimé, vous ne payez plus rien

---

## 🔄 Ordre d'Exécution des Jobs

Quand vous choisissez `action: 'all'`, voici l'ordre :

```
1. terraform-plan      (2 minutes)
   ↓
2. terraform-apply     (15-20 minutes) - Attendre que plan soit fini
   ↓
3. deploy-helm         (5 minutes) - Attendre que apply soit fini
```

**Total** : ~20-25 minutes pour tout déployer

---

## 🔑 Concepts Importants

### 1. `needs:` - Dépendances

```yaml
terraform-apply:
  needs: terraform-plan  # Ne peut pas commencer avant que plan soit fini
```

**Exemple** : Vous ne pouvez pas construire une maison (`apply`) avant d'avoir le plan (`plan`)

---

### 2. `if:` - Conditions

```yaml
terraform-apply:
  if: action == 'apply' || action == 'all'
```

**Exemple** :
- Si vous choisissez `action: 'plan'` → Seul `terraform-plan` s'exécute
- Si vous choisissez `action: 'all'` → Tous les jobs s'exécutent

---

### 3. `${{ }}` - Variables GitHub Actions

```yaml
aws-region: ${{ env.AWS_REGION }}  # Utilise la variable AWS_REGION
imageTag: ${{ github.event.inputs.image_tag || 'latest' }}
```

**Exemple** :
- `${{ env.AWS_REGION }}` → `us-east-1`
- `${{ github.event.inputs.image_tag || 'latest' }}` → `latest` (par défaut) ou ce que vous avez choisi

---

### 4. Secrets GitHub

```yaml
aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Exemple** : Ces secrets sont stockés dans GitHub → Settings → Secrets
- Ils ne sont **jamais** affichés dans les logs
- Seul GitHub peut les utiliser

---

## 📊 Exemple Complet de Déploiement

### Scénario : Déployer pour la première fois

**1. Vous allez sur GitHub Actions**
```
Actions → "Deploy to EKS" → "Run workflow"
```

**2. Vous choisissez** :
```
Action: all
Environment: dev
Image Tag: latest
```

**3. Le workflow s'exécute** :

```
⏱️ 00:00 - Démarrage
   └─ Job terraform-plan commence
      └─ "Je vais créer un cluster EKS..."

⏱️ 02:00 - Plan terminé
   └─ Job terraform-apply commence
      └─ "Création du cluster en cours..."
      └─ ⏳ Attente 15-20 minutes

⏱️ 20:00 - Cluster créé !
   └─ Job deploy-helm commence
      └─ "Déploiement des services..."
      └─ weather-service: ✅ Running
      └─ location-service: ✅ Running
      └─ weather-report-service: ✅ Running

⏱️ 25:00 - Terminé !
   └─ URL: http://a1b2c3d4.us-east-1.elb.amazonaws.com:8083
```

**4. Vous testez** :
```bash
curl http://a1b2c3d4.us-east-1.elb.amazonaws.com:8083/api/report/Paris
```

---

## 🎯 Actions Disponibles

| Action | Description | Exemple |
|--------|-------------|---------|
| `plan` | Simuler la création (ne crée rien) | Voir ce qui sera créé |
| `apply` | Créer le cluster EKS | Créer l'infrastructure |
| `deploy-helm` | Déployer les services | Mettre les apps sur Kubernetes |
| `all` | Faire tout (plan + apply + deploy) | Déploiement complet |
| `destroy` | Tout supprimer | Nettoyer pour économiser |

---

## 🔍 Détails Techniques par Section

### Section `workflow_dispatch` (Déclenchement Manuel)

```yaml
workflow_dispatch:
  inputs:
    action:
      type: choice
      options: [plan, apply, destroy, deploy-helm, all]
```

**Explication** : Crée un menu déroulant dans GitHub Actions avec ces options

---

### Section `push` (Déclenchement Automatique)

```yaml
push:
  branches: [main]
  paths:
    - 'terraform/**'
    - 'helm/**'
```

**Explication** : Se lance automatiquement si vous modifiez des fichiers Terraform ou Helm et poussez sur `main`

---

### Section `terraform-plan` - Étapes Détaillées

```yaml
- name: Checkout code
  uses: actions/checkout@v4
```
**Fait** : Télécharge votre code depuis GitHub

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
```
**Fait** : Configure les identifiants AWS pour que GitHub puisse parler à AWS

```yaml
- name: Setup Terraform
  uses: hashicorp/setup-terraform@v3
```
**Fait** : Installe Terraform sur la machine GitHub Actions

```yaml
- name: Terraform Plan
  run: terraform plan -out=tfplan
```
**Fait** : Crée un plan (simulation) et le sauvegarde dans `tfplan`

---

### Section `terraform-apply` - Étapes Détaillées

```yaml
- name: Download Terraform Plan
  uses: actions/download-artifact@v4
```
**Fait** : Récupère le plan créé par `terraform-plan`

```yaml
- name: Terraform Apply
  run: terraform apply -auto-approve tfplan
```
**Fait** : **Crée réellement** le cluster EKS (15-20 minutes)

```yaml
- name: Get Cluster Name
  run: CLUSTER_NAME=$(terraform output -raw cluster_name)
```
**Fait** : Récupère le nom du cluster créé (ex: `meteo-cluster-dev`)

```yaml
- name: Configure kubectl
  run: aws eks update-kubeconfig --name $CLUSTER_NAME
```
**Fait** : Configure `kubectl` pour se connecter au cluster

---

### Section `deploy-helm` - Étapes Détaillées

```yaml
- name: Get AWS Account ID
  run: AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account)
```
**Fait** : Récupère votre ID de compte AWS (ex: `864522970972`)

```yaml
- name: Get ECR Token
  run: ECR_TOKEN=$(aws ecr get-login-password)
```
**Fait** : Récupère un token pour accéder aux images Docker dans ECR

```yaml
- name: Create ECR Secret
  run: kubectl create secret docker-registry ecr-registry-secret ...
```
**Fait** : Crée un secret Kubernetes pour que les pods puissent télécharger les images depuis ECR

```yaml
- name: Deploy with Helm
  run: helm upgrade --install meteo-app ...
```
**Fait** : Déploie vos 3 microservices sur Kubernetes

**Détail** : `helm upgrade --install` signifie :
- Si `meteo-app` existe → Mettre à jour
- Si `meteo-app` n'existe pas → Créer

```yaml
- name: Get LoadBalancer URL
  run: kubectl get svc weather-report-service -o jsonpath='...'
```
**Fait** : Récupère l'URL publique du LoadBalancer (ex: `a1b2c3d4.us-east-1.elb.amazonaws.com`)

---

## 🎓 Analogie Simple

Imaginez que vous construisez une maison :

1. **`terraform-plan`** = L'architecte fait les plans
   - "Voici ce qu'on va construire"
   - Ne construit rien encore

2. **`terraform-apply`** = Le constructeur construit la maison
   - Crée les fondations, les murs, le toit
   - Prend du temps (15-20 min)

3. **`deploy-helm`** = Vous emménagez avec vos meubles
   - Mettez vos microservices dans la maison
   - Connectez tout

4. **`terraform-destroy`** = Vous démolissez la maison
   - Pour ne plus payer les factures

---

## 🚨 Erreurs Courantes et Solutions

### Erreur : "AWS credentials not configured"

**Cause** : Les secrets GitHub ne sont pas configurés

**Solution** :
```
GitHub → Settings → Secrets and variables → Actions
Ajouter :
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
```

---

### Erreur : "Cluster not found"

**Cause** : Vous essayez de déployer (`deploy-helm`) avant de créer le cluster (`apply`)

**Solution** : Utilisez `action: 'all'` ou faites `apply` avant `deploy-helm`

---

### Erreur : "Image pull failed"

**Cause** : Le secret ECR n'est pas créé ou le token a expiré

**Solution** : Le workflow crée automatiquement le secret, mais vérifiez que les images existent dans ECR

---

## 📝 Résumé en 3 Points

1. **`terraform-plan`** → Simule la création du cluster
2. **`terraform-apply`** → Crée réellement le cluster EKS
3. **`deploy-helm`** → Déploie vos microservices sur le cluster

**Tout est automatisé** : Vous cliquez sur "Run workflow" et tout se fait tout seul ! 🎉

---

## 🔗 Liens Utiles

- [Documentation GitHub Actions](https://docs.github.com/en/actions)
- [Documentation Terraform](https://www.terraform.io/docs)
- [Documentation Helm](https://helm.sh/docs)
- [Documentation AWS EKS](https://docs.aws.amazon.com/eks/)

---

**Questions ?** Consultez les autres guides :
- `EKS_DEPLOYMENT_GUIDE.md` - Guide complet
- `QUICK_START_EKS.md` - Démarrage rapide
- `EKS_WORKFLOW_GUIDE.md` - Guide du workflow

