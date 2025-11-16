# Meteo Services

A simple Spring Boot microservices project that demonstrates inter-service communication with three services working together to provide comprehensive weather reports.

## Architecture

This project consists of three independent Spring Boot services:

1. **Weather Service** (Port 8081) - Provides weather data including temperature, condition, and description
2. **Location Service** (Port 8082) - Provides location information including city, country, coordinates, and timezone
3. **Weather Report Service** (Port 8083) - Aggregates data from both Weather and Location services to create comprehensive weather reports

## Services Overview

### Weather Service
- **Port**: 8081
- **Endpoint**: `GET /api/weather/{city}`
- **Functionality**: Returns weather information (temperature, condition, description) for a given city
- **Sample Data**: Pre-configured data for Paris, London, New York, Tokyo, and Dubai. Generates random weather for unknown cities.

### Location Service
- **Port**: 8082
- **Endpoint**: `GET /api/location/{city}`
- **Functionality**: Returns location details (city, country, latitude, longitude, timezone) for a given city
- **Sample Data**: Pre-configured data for Paris, London, New York, Tokyo, and Dubai. Generates random coordinates for unknown cities.

### Weather Report Service
- **Port**: 8083
- **Endpoint**: `GET /api/report/{city}`
- **Functionality**: Combines data from Weather Service and Location Service to create a comprehensive weather report
- **Communication**: Uses RestTemplate to call both Weather Service and Location Service, then aggregates the responses

## Prerequisites

- Java 17 or higher
- Maven 3.6+ (or use Maven Wrapper if provided)

## Building the Project

To build all services:

```bash
mvn clean install
```

To build a specific service:

```bash
cd microservices/weather-service
mvn clean install
```

## Running the Services

You need to run the services in the following order:

### 1. Start Weather Service
```bash
cd microservices/weather-service
mvn spring-boot:run
```
Service will start on port 8081

### 2. Start Location Service
```bash
cd microservices/location-service
mvn spring-boot:run
```
Service will start on port 8082

### 3. Start Weather Report Service
```bash
cd microservices/weather-report-service
mvn spring-boot:run
```
Service will start on port 8083

**Note**: The Weather Report Service depends on both Weather Service and Location Service. Make sure they are running before starting the Weather Report Service.

## API Usage Examples

### Get Weather Data
```bash
curl http://localhost:8081/api/weather/Paris
```

Response:
```json
{
  "city": "Paris",
  "temperature": 15.5,
  "condition": "Cloudy",
  "description": "Partly cloudy with light breeze"
}
```

### Get Location Data
```bash
curl http://localhost:8082/api/location/Paris
```

Response:
```json
{
  "city": "Paris",
  "country": "France",
  "latitude": 48.8566,
  "longitude": 2.3522,
  "timezone": "Europe/Paris"
}
```

### Get Weather Report (Combined Data)
```bash
curl http://localhost:8083/api/report/Paris
```

Response:
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
  "reportDate": "2024-01-15T10:30:00"
}
```

## Project Structure

```
meteo/
├── pom.xml                          # Parent POM
└── microservices/                   # Microservices directory
    ├── weather-service/             # Weather Service Module
    │   ├── pom.xml
    │   └── src/main/java/com/meteo/weather/
    │       ├── WeatherServiceApplication.java
    │       ├── controller/
    │       │   └── WeatherController.java
    │       ├── model/
    │       │   └── Weather.java
    │       └── service/
    │           └── WeatherService.java
    ├── location-service/            # Location Service Module
    │   ├── pom.xml
    │   └── src/main/java/com/meteo/location/
    │       ├── LocationServiceApplication.java
    │       ├── controller/
    │       │   └── LocationController.java
    │       ├── model/
    │       │   └── Location.java
    │       └── service/
    │           └── LocationService.java
    └── weather-report-service/      # Weather Report Service Module
        ├── pom.xml
        └── src/main/java/com/meteo/report/
            ├── WeatherReportServiceApplication.java
            ├── controller/
            │   └── WeatherReportController.java
            ├── model/
            │   ├── WeatherReport.java
            │   ├── Weather.java
            │   └── Location.java
            └── service/
                └── WeatherReportService.java
```

## Configuration

Each service has its own `application.properties` file where you can configure:
- Server port (default: 8081, 8082, 8083)
- Service URLs for inter-service communication (in weather-report-service)

## Technology Stack

- **Spring Boot 3.2.0**
- **Java 17**
- **Maven** (Multi-module project)
- **Spring Web** (REST APIs)
- **RestTemplate** (HTTP client for inter-service communication)

## Future Enhancements

Potential improvements:
- Add service discovery (Eureka, Consul)
- Add API Gateway
- Add centralized configuration (Spring Cloud Config)
- Add distributed tracing
- Add database persistence
- Add caching
- Add error handling and circuit breakers
- Add unit and integration tests

## Docker and AWS ECR Deployment

The project includes Docker support and GitHub Actions workflow for building and pushing images to AWS ECR.

### Docker Files

Each microservice has its own Dockerfile located in:
- `microservices/weather-service/Dockerfile`
- `microservices/location-service/Dockerfile`
- `microservices/weather-report-service/Dockerfile`

### Building Docker Images Locally

To build a Docker image for a service:

```bash
# From the project root
docker build -f microservices/weather-service/Dockerfile -t meteo-weather-service:latest .
docker build -f microservices/location-service/Dockerfile -t meteo-location-service:latest .
docker build -f microservices/weather-report-service/Dockerfile -t meteo-weather-report-service:latest .
```

### GitHub Actions Workflow for ECR

The workflow file `.github/workflows/client.yaml` (or `client.yaml` at root) automatically:

1. **Builds Maven projects** for each microservice
2. **Creates Docker images** for each service
3. **Pushes images to AWS ECR** with tags:
   - Commit SHA (e.g., `meteo-weather-service:abc123`)
   - `latest` tag

#### Prerequisites for ECR Deployment

1. **AWS Credentials**: Set up GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

2. **AWS Region**: Configure in workflow file (default: `us-east-1`)

3. **ECR Repository Prefix**: Configure in workflow file (default: `meteo`)

#### Workflow Triggers

The workflow runs on:
- Push to `main` or `dev` branches
- Pull requests to `main`
- Manual trigger (`workflow_dispatch`)

#### ECR Repositories

The workflow automatically creates these ECR repositories if they don't exist:
- `meteo-weather-service`
- `meteo-location-service`
- `meteo-weather-report-service`

#### Image Tags

Images are tagged with:
- **Commit SHA**: For traceability (e.g., `meteo-weather-service:abc123def`)
- **Latest**: For convenience (e.g., `meteo-weather-service:latest`)

#### Example Image URIs

After successful deployment, images will be available at:
```
<AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/meteo-weather-service:<TAG>
<AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/meteo-location-service:<TAG>
<AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/meteo-weather-report-service:<TAG>
```

### Running from Docker Images

After pulling images from ECR:

```bash
# Pull images
docker pull <ECR_URI>/meteo-weather-service:latest
docker pull <ECR_URI>/meteo-location-service:latest
docker pull <ECR_URI>/meteo-weather-report-service:latest

# Run containers
docker run -p 8081:8081 <ECR_URI>/meteo-weather-service:latest
docker run -p 8082:8082 <ECR_URI>/meteo-location-service:latest
docker run -p 8083:8083 <ECR_URI>/meteo-weather-report-service:latest
```

## Configuration AWS CLI

Avant de pouvoir utiliser les images Docker depuis ECR, vous devez configurer AWS CLI.

**Configuration rapide :**
```bash
# Méthode automatique (interactive)
./configure-aws.sh

# OU méthode manuelle
aws configure
```

📖 **Guide complet** : Consultez `AWS_CONFIGURATION_GUIDE.md` pour plus de détails.

## Tester l'Application avec Docker

Une fois que vos images sont poussées vers AWS ECR, vous pouvez les tester localement.

**⚠️ Si les containers s'arrêtent immédiatement**, consultez :
- `FIX_CONTAINER_EXIT.md` pour le diagnostic
- `./diagnose-containers.sh` pour un diagnostic automatique

### Méthode Rapide (Recommandée)

```bash
# 1. Configurer l'environnement ECR automatiquement
./setup-ecr-env.sh

# 2. Authentifier à AWS ECR (OBLIGATOIRE avant de pull)
./authenticate-ecr.sh

# 3. Pull et lancer tous les services
docker compose pull
docker compose up -d

# 4. Attendre 10 secondes que les services démarrent
sleep 10

# 5. Tester tous les services
./test-services.sh

# 6. Voir les logs
docker compose logs -f

# 7. Arrêter tout
docker compose down
```

### Méthode Manuelle

```bash
# 1. Configurer l'environnement ECR
./setup-ecr-env.sh

# 2. Authentifier à AWS ECR (OBLIGATOIRE)
./authenticate-ecr.sh
# OU manuellement :
# aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# 3. Pull et lancer avec Docker Compose
docker compose pull
docker compose up -d

# 4. Tester
curl http://localhost:8083/api/report/Paris
```

📖 **Guide complet** : Consultez `TESTING_GUIDE.md` pour plus de détails et d'options de test.

## Déploiement EKS avec Terraform et Helm

Déployez vos microservices sur AWS EKS (Elastic Kubernetes Service) avec Terraform et Helm.

### Déploiement via GitHub Actions (Recommandé)

Le workflow GitHub Actions automatise tout le processus de déploiement :

1. **Via GitHub UI** :
   - Aller sur Actions → "Deploy to EKS"
   - Cliquer sur "Run workflow"
   - Choisir l'action (`plan`, `apply`, `deploy-helm`, `all`, ou `destroy`)
   - Choisir l'environnement (`dev`, `staging`, `prod`)
   - Choisir le tag d'image Docker
   - Cliquer sur "Run workflow"

2. **Via Push automatique** :
   ```bash
   # Pour déclencher Terraform
   git commit -m "Update infrastructure [terraform]"
   git push origin main
   
   # Pour déclencher Helm (nécessite que le cluster existe déjà)
   git commit -m "Update application [helm]"
   git push origin main
   ```

**Note** : Le workflow garantit l'ordre d'exécution :
- `terraform-apply` attend que `terraform-plan` soit terminé
- `deploy-helm` attend que `terraform-apply` soit terminé
- Si les outputs Terraform ne sont pas disponibles, le workflow utilise la variable d'environnement `EKS_CLUSTER_NAME` comme fallback

📖 **Guide complet** : Consultez `.github/workflows/EKS_WORKFLOW_GUIDE.md` pour toutes les options.

### Déploiement Manuel (Terraform + Helm)

Si vous préférez déployer manuellement sans GitHub Actions :

```bash
# 1. Créer le cluster EKS
cd terraform
terraform init
terraform plan
terraform apply

# 2. Configurer kubectl
aws eks update-kubeconfig --region us-east-1 --name meteo-cluster

# 3. Créer le secret ECR
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_TOKEN=$(aws ecr get-login-password --region us-east-1)
kubectl create namespace meteo
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=${ECR_TOKEN} \
  --namespace=meteo

# 4. Déployer avec Helm
cd ..
helm upgrade --install meteo-app ./helm/meteo-app \
  --namespace meteo \
  --create-namespace \
  --set global.awsAccountId=$AWS_ACCOUNT_ID \
  --set global.awsRegion=us-east-1 \
  --set global.imageTag=latest \
  --set global.ecrToken=$ECR_TOKEN
```

### Structure du Déploiement

- **Terraform** (`terraform/`) : Configuration de l'infrastructure EKS
  - VPC avec sous-réseaux publics/privés
  - Cluster EKS avec node groups
  - Security groups et networking
  
- **Helm** (`helm/meteo-app/`) : Charts pour déployer les microservices
  - Weather Service (Deployment + Service)
  - Location Service (Deployment + Service)
  - Weather Report Service (Deployment + LoadBalancer Service)

📖 **Guide complet** : Consultez `EKS_DEPLOYMENT_GUIDE.md` pour les instructions détaillées étape par étape.

### Prérequis

- AWS CLI configuré
- Terraform >= 1.0
- kubectl installé
- Helm >= 3.0

## Nettoyage AWS ECR

Quand vous avez fini d'utiliser AWS ECR, consultez le guide `CLEANUP_AWS.md` pour éviter des coûts inutiles.

**Nettoyage rapide :**
```bash
# Exécuter le script de nettoyage (demande confirmation)
./cleanup-ecr.sh

# Ou supprimer manuellement via AWS CLI
aws ecr delete-repository --reposi  tory-name meteo-weather-service --region us-east-1 --force
```

## License

This is a simple educational project.
