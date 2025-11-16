# Guide de Test de l'Application avec Docker

Ce guide explique comment tester votre application en utilisant les images Docker depuis AWS ECR.

## 📋 Prérequis

1. **AWS CLI configuré** avec vos credentials
2. **Docker installé** sur votre machine
3. **Accès à AWS ECR** (vos repositories doivent exister)

## 🔐 Étape 1 : Authentification à AWS ECR

Avant de pouvoir pull les images, vous devez vous authentifier :

```bash
# Se connecter à ECR (remplacez us-east-1 par votre région)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Exemple concret :
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
```

**Note** : Remplacez `<AWS_ACCOUNT_ID>` par votre vrai ID de compte AWS. Vous pouvez le trouver avec :
```bash
aws sts get-caller-identity --query Account --output text
```

## 📥 Étape 2 : Pull les Images depuis ECR

Une fois authentifié, vous pouvez pull les images :

```bash
# Récupérer l'URI du registry
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
export IMAGE_TAG=latest  # ou utilisez un tag spécifique (SHA du commit)

# Pull les images
docker pull ${ECR_REGISTRY}/meteo-weather-service:${IMAGE_TAG}
docker pull ${ECR_REGISTRY}/meteo-location-service:${IMAGE_TAG}
docker pull ${ECR_REGISTRY}/meteo-weather-report-service:${IMAGE_TAG}
```

## 🚀 Étape 3 : Lancer les Services

### Option A : Lancer Manuellement (3 Terminaux)

**Terminal 1 - Weather Service :**
```bash
docker run -d \
  --name weather-service \
  -p 8081:8081 \
  ${ECR_REGISTRY}/meteo-weather-service:latest
```

**Terminal 2 - Location Service :**
```bash
docker run -d \
  --name location-service \
  -p 8082:8082 \
  ${ECR_REGISTRY}/meteo-location-service:latest
```

**Terminal 3 - Weather Report Service :**
```bash
docker run -d \
  --name weather-report-service \
  -p 8083:8083 \
  -e WEATHER_SERVICE_URL=http://host.docker.internal:8081 \
  -e LOCATION_SERVICE_URL=http://host.docker.internal:8082 \
  ${ECR_REGISTRY}/meteo-weather-report-service:latest
```

**⚠️ Problème avec l'Option A** : Le Weather Report Service ne pourra pas accéder aux autres services via `host.docker.internal` car ils tournent dans des containers séparés. Utilisez plutôt l'**Option B avec Docker Compose**.

### Option B : Docker Compose (Recommandé)

Je vais créer un fichier `docker-compose.yml` pour orchestrer tous les services ensemble.

## 🧪 Étape 4 : Tester les Endpoints

Une fois les services lancés, testez-les :

### Test Weather Service
```bash
curl http://localhost:8081/api/weather/Paris
```

**Réponse attendue :**
```json
{
  "city": "Paris",
  "temperature": 15.5,
  "condition": "Cloudy",
  "description": "Partly cloudy with light breeze"
}
```

### Test Location Service
```bash
curl http://localhost:8082/api/location/Paris
```

**Réponse attendue :**
```json
{
  "city": "Paris",
  "country": "France",
  "latitude": 48.8566,
  "longitude": 2.3522,
  "timezone": "Europe/Paris"
}
```

### Test Weather Report Service (Agrégation)
```bash
curl http://localhost:8083/api/report/Paris
```

**Réponse attendue :**
```json
{
  "city": "Paris",
  "country": "France",
  "temperature": 15.5,
  "condition": "Cloudy",
  "description": "Partly cloudy with light breeze",
  "latitude": 48.8566,
  "longitude": 2.3522,
  "timezone": "Europe/Paris",
  "reportDate": "2024-11-16T16:30:00"
}
```

## 🛠️ Script de Test Automatique

Pour tester automatiquement tous les services :

```bash
#!/bin/bash
# test-services.sh

echo "🧪 Test des Services Meteo"
echo ""

# Test Weather Service
echo "1️⃣  Test Weather Service..."
curl -s http://localhost:8081/api/weather/Paris | jq '.' || echo "❌ Weather Service ne répond pas"
echo ""

# Test Location Service
echo "2️⃣  Test Location Service..."
curl -s http://localhost:8082/api/location/Paris | jq '.' || echo "❌ Location Service ne répond pas"
echo ""

# Test Weather Report Service
echo "3️⃣  Test Weather Report Service (Agrégation)..."
curl -s http://localhost:8083/api/report/Paris | jq '.' || echo "❌ Weather Report Service ne répond pas"
echo ""

echo "✅ Tests terminés !"
```

## 🔍 Vérifier l'État des Containers

```bash
# Voir tous les containers en cours d'exécution
docker ps

# Voir les logs d'un service
docker logs weather-service
docker logs location-service
docker logs weather-report-service

# Suivre les logs en temps réel
docker logs -f weather-report-service
```

## 🛑 Arrêter les Services

```bash
# Arrêter tous les containers
docker stop weather-service location-service weather-report-service

# Supprimer les containers
docker rm weather-service location-service weather-report-service

# Ou avec Docker Compose
docker-compose down
```

## 🌐 Tester avec Différentes Villes

```bash
# Paris
curl http://localhost:8083/api/report/Paris

# London
curl http://localhost:8083/api/report/London

# New York
curl http://localhost:8083/api/report/New%20York

# Ville inconnue (génère des données aléatoires)
curl http://localhost:8083/api/report/Montreal
```

## 🔧 Dépannage

### Le Weather Report Service ne peut pas joindre les autres services

**Problème** : Les containers Docker sont isolés et ne peuvent pas communiquer entre eux.

**Solution** : Utilisez Docker Compose qui crée un réseau interne où tous les services peuvent communiquer.

### Les ports sont déjà utilisés

**Problème** : `Error: bind: address already in use`

**Solution** : 
```bash
# Trouver quel processus utilise le port
lsof -i :8081
lsof -i :8082
lsof -i :8083

# Tuer le processus ou utiliser d'autres ports
docker run -p 9081:8081 ...
```

### Les images ne sont pas trouvées localement

**Problème** : `Error: No such image`

**Solution** : 
```bash
# Vérifier que les images sont bien pullées
docker images | grep meteo

# Si elles n'existent pas, re-pull depuis ECR
docker pull ${ECR_REGISTRY}/meteo-weather-service:latest
```

## 📊 Monitoring avec Health Checks

Vérifier que les services sont en bonne santé :

```bash
# Weather Service
curl http://localhost:8081/actuator/health 2>/dev/null || echo "Actuator non configuré"

# Location Service  
curl http://localhost:8082/actuator/health 2>/dev/null || echo "Actuator non configuré"

# Weather Report Service
curl http://localhost:8083/actuator/health 2>/dev/null || echo "Actuator non configuré"
```

**Note** : Actuator n'est pas configuré dans ce projet simple, mais vous pourriez l'ajouter pour le monitoring.

## 🎯 Workflow Complet de Test

```bash
# 1. Authentification ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# 2. Pull les images
docker pull ${ECR_REGISTRY}/meteo-weather-service:latest
docker pull ${ECR_REGISTRY}/meteo-location-service:latest
docker pull ${ECR_REGISTRY}/meteo-weather-report-service:latest

# 3. Lancer avec Docker Compose
docker-compose up -d

# 4. Attendre que les services démarrent (5-10 secondes)
sleep 10

# 5. Tester les endpoints
./test-services.sh

# 6. Voir les logs
docker-compose logs -f

# 7. Arrêter tout
docker-compose down
```

---

**Prochaine étape** : Créez le fichier `docker-compose.yml` pour orchestrer facilement tous les services !

