# Infrastructure Terraform pour EKS

Cette configuration Terraform crée un cluster EKS avec toutes les ressources nécessaires.

## Structure

```
terraform/
├── main.tf              # Configuration principale (VPC, EKS)
├── variables.tf         # Variables d'entrée
├── outputs.tf          # Sorties (cluster info, etc.)
├── terraform.tfvars.example  # Exemple de configuration
└── .gitignore          # Fichiers à ignorer
```

## Utilisation Rapide

### 1. Configuration Initiale

```bash
# Copier et éditer les variables
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec vos valeurs

# Initialiser Terraform
terraform init
```

### 2. Déploiement

```bash
# Voir ce qui sera créé
terraform plan

# Créer l'infrastructure
terraform apply
```

### 3. Nettoyage

```bash
# Supprimer toutes les ressources
terraform destroy

# Si vous obtenez des erreurs "AlreadyExistsException", nettoyez d'abord :
./cleanup-existing-resources.sh
```

## Variables Principales

Voir `variables.tf` pour la liste complète. Variables importantes :

- `cluster_name` : Nom du cluster EKS
- `kubernetes_version` : Version Kubernetes (défaut: 1.28)
- `node_group_desired_size` : Nombre de nodes (défaut: 2)
- `node_instance_types` : Type d'instances EC2 (défaut: ["c7i-flex.large"])

## Outputs

Après `terraform apply`, utilisez `terraform output` pour voir :
- `configure_kubectl` : Commande pour configurer kubectl
- `cluster_name` : Nom du cluster
- `cluster_endpoint` : URL du cluster

## Modules Utilisés

- **VPC Module** : `terraform-aws-modules/vpc/aws`
- **EKS Module** : `terraform-aws-modules/eks/aws`

Ces modules sont téléchargés automatiquement lors de `terraform init`.

## Dépannage

Si vous rencontrez des erreurs lors du déploiement, consultez `TROUBLESHOOTING.md` pour les solutions courantes.

**Erreur "AlreadyExistsException" ?** Utilisez le script de nettoyage :
```bash
export CLUSTER_NAME="meteo-cluster"  # ou meteo-cluster-dev
export AWS_REGION="us-east-1"
./cleanup-existing-resources.sh
```

## Coûts

Estimé ~$180-200/mois pour un environnement de développement.

Voir `EKS_DEPLOYMENT_GUIDE.md` pour plus de détails.

