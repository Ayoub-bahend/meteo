# 🔧 Dépannage Terraform EKS

Ce guide vous aide à résoudre les erreurs courantes lors du déploiement EKS avec Terraform.

## ❌ Erreur : "AlreadyExistsException" pour KMS Alias ou CloudWatch Log Group

### Symptômes

```
Error: creating KMS Alias (alias/eks/meteo-cluster): AlreadyExistsException
Error: creating CloudWatch Logs Log Group: ResourceAlreadyExistsException
```

### Cause

Ces ressources existent déjà d'un déploiement précédent qui n'a pas été complètement supprimé.

### Solution 1 : Nettoyer les ressources existantes (Recommandé)

Utilisez le script de nettoyage :

```bash
cd terraform
export CLUSTER_NAME="meteo-cluster"  # ou meteo-cluster-dev selon votre environnement
export AWS_REGION="us-east-1"
./cleanup-existing-resources.sh
```

Puis relancez :

```bash
terraform plan
terraform apply
```

### Solution 2 : Supprimer manuellement

```bash
# 1. Supprimer l'alias KMS
aws kms delete-alias --alias-name alias/eks/meteo-cluster --region us-east-1

# 2. Supprimer le groupe de logs CloudWatch
aws logs delete-log-group --log-group-name /aws/eks/meteo-cluster/cluster --region us-east-1

# 3. Vérifier qu'il n'y a pas de cluster EKS existant
aws eks describe-cluster --name meteo-cluster --region us-east-1
# Si le cluster existe, vous devez le supprimer d'abord :
# aws eks delete-cluster --name meteo-cluster --region us-east-1
```

### Solution 3 : Utiliser un nom de cluster différent

Modifiez `terraform.tfvars` :

```hcl
cluster_name = "meteo-cluster-v2"
```

Puis relancez `terraform apply`.

---

## ❌ Erreur : "No outputs found"

### Symptômes

```
Error: Unable to process file command 'output' successfully.
Error: Invalid format '│ Warning: No outputs found'
```

### Cause

Le workflow GitHub Actions essaie de récupérer des outputs Terraform avant que le cluster soit créé.

### Solution

Le workflow a été mis à jour pour gérer ce cas automatiquement avec un système de fallback. Si l'erreur persiste :

1. Vérifiez que `terraform apply` a réussi
2. Vérifiez que le cluster existe : `aws eks describe-cluster --name meteo-cluster --region us-east-1`
3. Relancez le workflow GitHub Actions

---

## ❌ Erreur : "Duplicate output definition"

### Symptômes

```
Error: Duplicate output definition
An output named "cluster_name" was already defined
```

### Cause

Les outputs sont définis à la fois dans `main.tf` et `outputs.tf`.

### Solution

Les outputs doivent être uniquement dans `outputs.tf`. Vérifiez que `main.tf` ne contient pas de blocs `output`.

---

## ❌ Erreur : "couldn't find resource" pour data.aws_eks_cluster

### Symptômes

```
Error: reading EKS Cluster (meteo-cluster): couldn't find resource
with data.aws_eks_cluster.cluster
```

### Cause

Les data sources et providers Kubernetes/Helm essaient de lire un cluster qui n'existe pas encore.

### Solution

Cette erreur a été corrigée en supprimant les data sources et providers Kubernetes/Helm de `main.tf`. Le workflow GitHub Actions configure `kubectl` et `helm` séparément après la création du cluster.

---

## ❌ Erreur : "Permission denied" lors de terraform apply

### Symptômes

```
Error: operation error EKS: CreateCluster, https response error StatusCode: 403
```

### Cause

Vos credentials AWS n'ont pas les permissions nécessaires pour créer un cluster EKS.

### Solution

Vérifiez que votre utilisateur AWS a les permissions suivantes :
- `eks:CreateCluster`
- `eks:DescribeCluster`
- `ec2:CreateVpc`
- `ec2:CreateSubnet`
- `iam:CreateRole`
- `iam:AttachRolePolicy`
- Et d'autres permissions EKS/EC2/IAM

Consultez la [documentation AWS EKS](https://docs.aws.amazon.com/eks/latest/userguide/security_iam_id-based-policy-examples.html) pour la liste complète.

---

## ❌ Erreur : "VPC not found" ou problèmes de réseau

### Symptômes

```
Error: creating EKS Cluster: InvalidParameterException: VPC doesn't exist
```

### Cause

Le VPC n'a pas été créé correctement ou les sous-réseaux ne sont pas configurés.

### Solution

1. Vérifiez que le VPC existe : `aws ec2 describe-vpcs --region us-east-1`
2. Vérifiez les sous-réseaux : `aws ec2 describe-subnets --region us-east-1`
3. Relancez `terraform plan` pour voir ce qui sera créé

---

## 🔍 Commandes Utiles pour le Dépannage

### Vérifier l'état Terraform

```bash
cd terraform
terraform state list          # Voir toutes les ressources gérées
terraform state show <resource> # Voir les détails d'une ressource
terraform refresh              # Rafraîchir l'état
```

### Vérifier les ressources AWS

```bash
# Vérifier le cluster EKS
aws eks list-clusters --region us-east-1
aws eks describe-cluster --name meteo-cluster --region us-east-1

# Vérifier les VPCs
aws ec2 describe-vpcs --region us-east-1

# Vérifier les groupes de logs
aws logs describe-log-groups --region us-east-1

# Vérifier les alias KMS
aws kms list-aliases --region us-east-1
```

### Nettoyer complètement

```bash
# 1. Supprimer avec Terraform
cd terraform
terraform destroy

# 2. Nettoyer les ressources orphelines
./cleanup-existing-resources.sh

# 3. Vérifier qu'il ne reste rien
aws eks list-clusters --region us-east-1
```

---

## 📚 Ressources

- [Documentation Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [Documentation AWS EKS](https://docs.aws.amazon.com/eks/)
- [Troubleshooting EKS](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)

---

## 💡 Conseils

1. **Toujours faire `terraform plan` avant `terraform apply`** pour voir ce qui sera créé
2. **Utiliser des noms de cluster uniques** si vous testez plusieurs environnements
3. **Nettoyer les ressources orphelines** avant de recréer un cluster avec le même nom
4. **Vérifier les permissions AWS** avant de commencer
5. **Utiliser le script de nettoyage** si vous obtenez des erreurs "AlreadyExistsException"

