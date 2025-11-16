# Guide d'Utilisation du Workflow GitHub Actions pour EKS

Ce guide explique comment utiliser le workflow GitHub Actions `deploy-eks.yaml` pour déployer automatiquement vos microservices sur EKS.

## 📋 Vue d'Ensemble

Le workflow `deploy-eks.yaml` automatise :
1. ✅ Planification Terraform (voir ce qui sera créé)
2. ✅ Création du cluster EKS avec Terraform
3. ✅ Configuration de kubectl
4. ✅ Déploiement avec Helm
5. ✅ Vérification du déploiement
6. ✅ Destruction de l'infrastructure (optionnel)

## 🚀 Utilisation

### Méthode 1 : Via GitHub UI (Workflow Dispatch)

1. **Aller sur GitHub** → Actions → "Deploy to EKS"
2. **Cliquer sur "Run workflow"**
3. **Choisir les options** :
   - **Action** : `plan`, `apply`, `deploy-helm`, `all`, ou `destroy`
   - **Environment** : `dev`, `staging`, ou `prod`
   - **Image Tag** : Tag de l'image Docker (ex: `latest`, `abc123def`)
4. **Cliquer sur "Run workflow"**

### Méthode 2 : Via Push (Automatique)

Le workflow se déclenche automatiquement quand vous push sur `main` avec des changements dans :
- `terraform/**`
- `helm/**`
- `.github/workflows/deploy-eks.yaml`

**Note** : Pour déclencher Terraform ou Helm spécifiquement, incluez dans le message de commit :
- `[terraform]` → Lance Terraform plan/apply
- `[helm]` → Lance le déploiement Helm

Exemple :
```bash
git commit -m "Update Helm chart [helm]"
git push origin main
```

## 📝 Actions Disponibles

### `plan` - Planification Terraform

**Quand utiliser** : Avant de créer l'infrastructure pour voir ce qui sera créé

**Ce que ça fait** :
- Initialise Terraform
- Exécute `terraform plan`
- Sauvegarde le plan dans un artifact

**Résultat** : Vous pouvez voir tous les changements qui seront appliqués

### `apply` - Création du Cluster EKS

**Quand utiliser** : Pour créer l'infrastructure EKS

**Ce que ça fait** :
- Télécharge le plan Terraform
- Exécute `terraform apply`
- Crée le cluster EKS (15-20 minutes)
- Configure kubectl
- Vérifie la connexion au cluster

**Résultat** : Cluster EKS créé et prêt

### `deploy-helm` - Déploiement avec Helm

**Quand utiliser** : Pour déployer/mettre à jour l'application sur le cluster existant

**Ce que ça fait** :
- Récupère les infos du cluster
- Configure kubectl
- Crée le secret ECR
- Déploie l'application avec Helm
- Vérifie le déploiement
- Affiche l'URL du LoadBalancer

**Résultat** : Application déployée et accessible

### `all` - Tout en Une

**Quand utiliser** : Pour créer le cluster ET déployer l'application en une fois

**Ce que ça fait** :
- Exécute `plan`
- Exécute `apply`
- Exécute `deploy-helm`

**Résultat** : Cluster créé + Application déployée

### `destroy` - Destruction

**Quand utiliser** : Pour supprimer complètement l'infrastructure

**Ce que ça fait** :
- Désinstalle Helm release
- Supprime le namespace
- Exécute `terraform destroy`
- Supprime toutes les ressources AWS

**⚠️ ATTENTION** : Cette action est irréversible !

## 🔐 Secrets GitHub Requis

Le workflow nécessite ces secrets dans GitHub :

1. **`AWS_ACCESS_KEY_ID`** : Votre clé d'accès AWS
2. **`AWS_SECRET_ACCESS_KEY`** : Votre clé secrète AWS

**Pour configurer** :
- GitHub → Settings → Secrets and variables → Actions
- New repository secret
- Ajouter les deux secrets

## 📊 Jobs et Étapes

### Job 1 : `terraform-plan`

- ✅ Checkout code
- ✅ Configure AWS credentials
- ✅ Setup Terraform
- ✅ Terraform Init
- ✅ Terraform Plan
- ✅ Upload plan artifact

### Job 2 : `terraform-apply` (dépend de terraform-plan)

- ✅ Checkout code
- ✅ Configure AWS credentials
- ✅ Download Terraform plan
- ✅ Terraform Apply
- ✅ Configure kubectl
- ✅ Verify connection

### Job 3 : `deploy-helm` (peut s'exécuter indépendamment)

- ✅ Checkout code
- ✅ Configure AWS credentials
- ✅ Get cluster info from Terraform
- ✅ Configure kubectl
- ✅ Setup Helm
- ✅ Get AWS Account ID
- ✅ Get ECR Token
- ✅ Create ECR Secret
- ✅ Deploy with Helm
- ✅ Verify Deployment
- ✅ Get LoadBalancer URL

### Job 4 : `terraform-destroy`

- ✅ Checkout code
- ✅ Configure AWS credentials
- ✅ Uninstall Helm release
- ✅ Terraform Destroy

## 🎯 Scénarios d'Utilisation

### Scénario 1 : Premier Déploiement

```bash
# 1. Via GitHub UI
# Action: all
# Environment: dev
# Image Tag: latest

# Ou via commit
git commit -m "Initial EKS deployment [terraform] [helm]"
git push origin main
```

### Scénario 2 : Mise à Jour de l'Application

```bash
# Après avoir push une nouvelle image Docker vers ECR
# Via GitHub UI
# Action: deploy-helm
# Image Tag: <nouveau-sha-ou-tag>

# Ou via commit
git commit -m "Update application [helm]"
git push origin main
```

### Scénario 3 : Mise à Jour de l'Infrastructure

```bash
# Après avoir modifié terraform/
# Via GitHub UI
# Action: apply
# Environment: dev

# Ou via commit
git commit -m "Update EKS configuration [terraform]"
git push origin main
```

### Scénario 4 : Vérification avant Déploiement

```bash
# Via GitHub UI
# Action: plan
# Environment: dev

# Voir ce qui sera créé/modifié sans rien changer
```

## 📈 Monitoring du Workflow

### Voir les Logs

1. Aller sur GitHub → Actions
2. Cliquer sur le workflow en cours
3. Cliquer sur le job pour voir les logs

### Vérifier le Déploiement

Après le job `deploy-helm`, les logs affichent :
- État des pods
- État des services
- URL du LoadBalancer (si disponible)

## 🔧 Configuration Avancée

### Variables d'Environnement

Le workflow utilise ces variables par défaut :
- `AWS_REGION`: `us-east-1`
- `TERRAFORM_DIR`: `terraform`
- `HELM_CHART_DIR`: `helm/meteo-app`
- `NAMESPACE`: `meteo`

Vous pouvez les modifier dans le fichier `deploy-eks.yaml`.

### Conditions de Déclenchement

Le workflow se déclenche :
- **Manuellement** : Via `workflow_dispatch`
- **Automatiquement** : Sur push vers `main` si changements dans `terraform/`, `helm/`, ou le workflow lui-même

### Personnalisation

Pour modifier le comportement :
1. Éditer `.github/workflows/deploy-eks.yaml`
2. Modifier les conditions `if:`
3. Ajouter des étapes supplémentaires

## ⚠️ Bonnes Pratiques

1. **Toujours faire `plan` avant `apply`** pour voir les changements
2. **Utiliser des tags d'image spécifiques** (SHA du commit) plutôt que `latest` en production
3. **Vérifier les logs** après chaque déploiement
4. **Ne pas utiliser `destroy`** sauf si vous voulez vraiment tout supprimer
5. **Tester d'abord en `dev`** avant de déployer en production

## 🐛 Dépannage

### Workflow échoue sur "Cluster not found"

**Problème** : Le cluster EKS n'existe pas encore

**Solution** : Exécutez d'abord l'action `apply` pour créer le cluster

### Workflow échoue sur "Image pull error"

**Problème** : Le secret ECR n'est pas valide ou l'image n'existe pas

**Solution** :
1. Vérifier que les images sont bien dans ECR
2. Vérifier que le secret ECR est créé correctement
3. Vérifier que le token ECR n'a pas expiré

### Workflow échoue sur "Terraform plan failed"

**Problème** : Erreur dans la configuration Terraform

**Solution** :
1. Vérifier les logs du workflow
2. Vérifier `terraform/terraform.tfvars`
3. Tester localement avec `terraform plan`

## 📚 Ressources

- [Documentation GitHub Actions](https://docs.github.com/en/actions)
- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [Helm Documentation](https://helm.sh/docs/)

