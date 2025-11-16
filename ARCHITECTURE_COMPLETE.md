# 🏗️ Architecture Complète du Projet Meteo

Ce document présente l'architecture complète et détaillée du projet Meteo, depuis les microservices jusqu'au déploiement sur AWS EKS.

---

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Architecture des Microservices](#architecture-des-microservices)
3. [Communication Inter-Services](#communication-inter-services)
4. [Infrastructure Locale (Docker Compose)](#infrastructure-locale-docker-compose)
5. [Infrastructure AWS](#infrastructure-aws)
6. [Déploiement sur EKS](#déploiement-sur-eks)
7. [Flux de Données](#flux-de-données)
8. [Sécurité et Authentification](#sécurité-et-authentification)
9. [CI/CD Pipeline](#cicd-pipeline)
10. [Schémas Visuels](#schémas-visuels)

---

## Vue d'Ensemble

### Description du Projet

Le projet Meteo est une application de microservices Spring Boot qui fournit des informations météorologiques. Il est composé de 3 services indépendants qui communiquent entre eux via des API REST.

### Stack Technologique

- **Backend** : Spring Boot 3.x, Java 17
- **Build** : Maven (Multi-module)
- **Containerisation** : Docker
- **Orchestration Locale** : Docker Compose
- **Orchestration Cloud** : Kubernetes (EKS)
- **Infrastructure as Code** : Terraform
- **Gestion de Déploiement** : Helm
- **CI/CD** : GitHub Actions
- **Registry** : AWS ECR (Elastic Container Registry)
- **Cloud Provider** : AWS

---

## Architecture des Microservices

### 1. Weather Service (Service Météo)

**Rôle** : Fournit les données météorologiques pour une ville donnée.

#### Configuration

- **Port** : `8081`
- **Application Name** : `weather-service`
- **Package** : `com.meteo.weather`
- **Base Path** : `/api/weather`

#### Endpoints

| Méthode | Endpoint | Description | Réponse |
|---------|----------|-------------|---------|
| GET | `/api/weather/{city}` | Obtenir la météo d'une ville | `{"city": "Paris", "temperature": 15, "condition": "Sunny"}` |

#### Modèle de Données

```java
public class Weather {
    private String city;
    private Integer temperature;
    private String condition;
}
```

#### Ressources

- **CPU Request** : 250m
- **CPU Limit** : 500m
- **Memory Request** : 256Mi
- **Memory Limit** : 512Mi

#### Image Docker

- **Repository ECR** : `{accountId}.dkr.ecr.us-east-1.amazonaws.com/meteo-weather-service`
- **Tag** : `latest` ou SHA du commit
- **Base Image** : `eclipse-temurin:17-jre-alpine`

---

### 2. Location Service (Service de Localisation)

**Rôle** : Fournit les informations de localisation (coordonnées, pays, etc.) pour une ville.

#### Configuration

- **Port** : `8082`
- **Application Name** : `location-service`
- **Package** : `com.meteo.location`
- **Base Path** : `/api/location`

#### Endpoints

| Méthode | Endpoint | Description | Réponse |
|---------|----------|-------------|---------|
| GET | `/api/location/{city}` | Obtenir les infos de localisation | `{"city": "Paris", "country": "France", "latitude": 48.8566, "longitude": 2.3522}` |

#### Modèle de Données

```java
public class Location {
    private String city;
    private String country;
    private Double latitude;
    private Double longitude;
}
```

#### Ressources

- **CPU Request** : 250m
- **CPU Limit** : 500m
- **Memory Request** : 256Mi
- **Memory Limit** : 512Mi

#### Image Docker

- **Repository ECR** : `{accountId}.dkr.ecr.us-east-1.amazonaws.com/meteo-location-service`
- **Tag** : `latest` ou SHA du commit
- **Base Image** : `eclipse-temurin:17-jre-alpine`

---

### 3. Weather Report Service (Service de Rapport Météo)

**Rôle** : Service agrégateur qui combine les données de Weather Service et Location Service pour créer un rapport météorologique complet.

#### Configuration

- **Port** : `8083`
- **Application Name** : `weather-report-service`
- **Package** : `com.meteo.report`
- **Base Path** : `/api/report`

#### Endpoints

| Méthode | Endpoint | Description | Réponse |
|---------|----------|-------------|---------|
| GET | `/api/report/{city}` | Obtenir un rapport météo complet | `{"location": {...}, "weather": {...}}` |

#### Modèle de Données

```java
public class WeatherReport {
    private Location location;
    private Weather weather;
}
```

#### Configuration des Services Externes

```properties
weather.service.url=http://localhost:8081
location.service.url=http://localhost:8082
```

**En Kubernetes** :
```yaml
weatherServiceUrl: "http://weather-service:8081"
locationServiceUrl: "http://location-service:8082"
```

#### Communication

- Utilise `RestTemplate` pour appeler les autres services
- Gère les erreurs HTTP (timeout, 404, etc.)
- Retourne un rapport combiné

#### Ressources

- **CPU Request** : 250m
- **CPU Limit** : 500m
- **Memory Request** : 256Mi
- **Memory Limit** : 512Mi

#### Image Docker

- **Repository ECR** : `{accountId}.dkr.ecr.us-east-1.amazonaws.com/meteo-weather-report-service`
- **Tag** : `latest` ou SHA du commit
- **Base Image** : `eclipse-temurin:17-jre-alpine`

---

## Communication Inter-Services

### Schéma de Communication

```
┌─────────────────────────────────────────────────────────────┐
│                    Client (Navigateur/API)                   │
└───────────────────────────┬─────────────────────────────────┘
                             │
                             │ HTTP GET /api/report/Paris
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│         Weather Report Service (Port 8083)                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ 1. Reçoit la requête                                │   │
│  │ 2. Appelle Location Service                         │   │
│  │ 3. Appelle Weather Service                          │   │
│  │ 4. Combine les résultats                            │   │
│  │ 5. Retourne le rapport complet                      │   │
│  └──────────────────────────────────────────────────────┘   │
└───────┬───────────────────────────────┬─────────────────────┘
        │                               │
        │ HTTP GET                      │ HTTP GET
        │ /api/location/Paris           │ /api/weather/Paris
        │                               │
        ▼                               ▼
┌──────────────────────┐    ┌──────────────────────┐
│ Location Service     │    │ Weather Service      │
│ (Port 8082)          │    │ (Port 8081)          │
│                      │    │                      │
│ - city: Paris        │    │ - temperature: 15    │
│ - country: France     │    │ - condition: Sunny   │
│ - coordinates        │    │                      │
└──────────────────────┘    └──────────────────────┘
```

### Détails Techniques

#### En Local (Docker Compose)

- **Réseau** : `meteo-network` (bridge)
- **DNS** : Les services se résolvent par leur nom de conteneur
  - `weather-service:8081`
  - `location-service:8082`
  - `weather-report-service:8083`

#### En Kubernetes (EKS)

- **Namespace** : `meteo`
- **DNS** : Kubernetes Service Discovery
  - `weather-service.meteo.svc.cluster.local:8081`
  - `location-service.meteo.svc.cluster.local:8082`
  - `weather-report-service.meteo.svc.cluster.local:8083`
- **Format court** : `weather-service:8081` (dans le même namespace)

---

## Infrastructure Locale (Docker Compose)

### Architecture Locale

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Host (Local Machine)              │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐ │
│  │           Network: meteo-network (bridge)            │ │
│  │                                                       │ │
│  │  ┌────────────────┐  ┌────────────────┐           │ │
│  │  │ Weather Service│  │Location Service│           │ │
│  │  │   :8081        │  │   :8082         │           │ │
│  │  │                │  │                 │           │ │
│  │  └────────┬───────┘  └────────┬────────┘          │ │
│  │           │                   │                    │ │
│  │           └───────────┬─────────┘                    │ │
│  │                       │                             │ │
│  │  ┌────────────────────▼──────────────┐             │ │
│  │  │  Weather Report Service :8083      │             │ │
│  │  │  (Exposé sur host:8083)          │             │ │
│  │  └───────────────────────────────────┘             │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                             │
│  Ports exposés:                                            │
│  - 8081:8081 (Weather Service)                             │
│  - 8082:8082 (Location Service)                            │
│  - 8083:8083 (Weather Report Service)                      │
└─────────────────────────────────────────────────────────────┘
```

### Configuration Docker Compose

#### Services

1. **weather-service**
   - Image : `{ECR_REGISTRY}/meteo-weather-service:{TAG}`
   - Port : `8081:8081`
   - Healthcheck : `GET /api/weather/Paris`
   - DNS : `8.8.8.8`, `8.8.4.4`

2. **location-service**
   - Image : `{ECR_REGISTRY}/meteo-location-service:{TAG}`
   - Port : `8082:8082`
   - Healthcheck : `GET /api/location/Paris`
   - DNS : `8.8.8.8`, `8.8.4.4`

3. **weather-report-service**
   - Image : `{ECR_REGISTRY}/meteo-weather-report-service:{TAG}`
   - Port : `8083:8083`
   - Healthcheck : `GET /api/report/Paris`
   - Variables d'environnement :
     - `WEATHER_SERVICE_URL=http://weather-service:8081`
     - `LOCATION_SERVICE_URL=http://location-service:8082`
   - Dépendances : `weather-service`, `location-service`

#### Réseau

- **Nom** : `meteo-network`
- **Type** : `bridge`
- **Isolation** : Les conteneurs peuvent communiquer entre eux

---

## Infrastructure AWS

### Architecture AWS Complète

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS Cloud (us-east-1)                        │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    AWS ECR (Container Registry)              │   │
│  │                                                               │   │
│  │  ┌──────────────────┐  ┌──────────────────┐                │   │
│  │  │ meteo-weather-   │  │ meteo-location-   │                │   │
│  │  │ service          │  │ service          │                │   │
│  │  │                  │  │                  │                │   │
│  │  │ Images Docker    │  │ Images Docker    │                │   │
│  │  │ - latest         │  │ - latest         │                │   │
│  │  │ - {commit-sha}   │  │ - {commit-sha}   │                │   │
│  │  └──────────────────┘  └──────────────────┘                │   │
│  │                                                               │   │
│  │  ┌──────────────────────────────────────────┐                │   │
│  │  │ meteo-weather-report-service             │                │   │
│  │  │                                          │                │   │
│  │  │ Images Docker                            │                │   │
│  │  │ - latest                                  │                │   │
│  │  │ - {commit-sha}                           │                │   │
│  │  └──────────────────────────────────────────┘                │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    VPC (10.0.0.0/16)                         │   │
│  │                                                               │   │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │   │
│  │  │ Public Subnets       │  │ Private Subnets      │         │   │
│  │  │ 10.0.101.0/24        │  │ 10.0.1.0/24          │         │   │
│  │  │ 10.0.102.0/24        │  │ 10.0.2.0/24          │         │   │
│  │  │                      │  │                      │         │   │
│  │  │ - Internet Gateway   │  │ - NAT Gateway        │         │   │
│  │  │ - Load Balancer      │  │ - EKS Nodes          │         │   │
│  │  │                      │  │                      │         │   │
│  │  └──────────────────────┘  └──────────────────────┘         │   │
│  │                                                               │   │
│  │  ┌──────────────────────────────────────────────────────┐    │   │
│  │  │              EKS Cluster (meteo-cluster)            │    │   │
│  │  │                                                       │    │   │
│  │  │  ┌──────────────────────────────────────────────┐    │    │   │
│  │  │  │         Control Plane (Managed)             │    │    │   │
│  │  │  │  - API Server                                │    │    │   │
│  │  │  │  - etcd                                      │    │    │   │
│  │  │  │  - Scheduler                                 │    │    │   │
│  │  │  │  - Controller Manager                        │    │    │   │
│  │  │  └──────────────────────────────────────────────┘    │    │   │
│  │  │                                                       │    │   │
│  │  │  ┌──────────────────────────────────────────────┐    │    │   │
│  │  │  │         Node Group (t3.medium)              │    │    │   │
│  │  │  │  - Min: 1, Desired: 2, Max: 3                │    │    │   │
│  │  │  │  - Instance Type: t3.medium                   │    │    │   │
│  │  │  │  - Capacity: ON_DEMAND                       │    │    │   │
│  │  │  │                                               │    │   │
│  │  │  │  ┌──────────────────────────────────────┐    │    │   │
│  │  │  │  │  Namespace: meteo                    │    │    │   │
│  │  │  │  │                                      │    │    │   │
│  │  │  │  │  ┌──────────────┐  ┌──────────────┐ │    │    │   │
│  │  │  │  │  │ Weather      │  │ Location     │ │    │    │   │
│  │  │  │  │  │ Service      │  │ Service      │ │    │    │   │
│  │  │  │  │  │ Pod          │  │ Pod          │ │    │    │   │
│  │  │  │  │  │ :8081        │  │ :8082        │ │    │    │   │
│  │  │  │  │  └──────┬───────┘  └──────┬───────┘ │    │    │   │
│  │  │  │  │         │                  │         │    │    │   │
│  │  │  │  │         └────────┬─────────┘         │    │    │   │
│  │  │  │  │                  │                   │    │    │   │
│  │  │  │  │  ┌───────────────▼───────────────┐   │    │    │   │
│  │  │  │  │  │ Weather Report Service        │   │    │    │   │
│  │  │  │  │  │ Pod                          │   │    │    │   │
│  │  │  │  │  │ :8083                        │   │    │    │   │
│  │  │  │  │  └──────────────────────────────┘   │    │    │   │
│  │  │  │  │                                      │    │    │   │
│  │  │  │  │  Services:                          │    │    │   │
│  │  │  │  │  - weather-service (ClusterIP)      │    │    │   │
│  │  │  │  │  - location-service (ClusterIP)     │    │    │   │
│  │  │  │  │  - weather-report-service (LB)      │    │    │   │
│  │  │  │  └──────────────────────────────────────┘    │    │   │
│  │  │  └──────────────────────────────────────────────┘    │   │
│  │  └───────────────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │              Network Load Balancer (NLB)                    │   │
│  │  - Type: Network Load Balancer                               │   │
│  │  - Port: 8083                                                │   │
│  │  - Target: weather-report-service                           │   │
│  │  - DNS: {lb-id}.us-east-1.elb.amazonaws.com                 │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │              CloudWatch Logs                                  │   │
│  │  - /aws/eks/meteo-cluster/cluster                            │   │
│  │  - Logs des pods (via Fluentd/DaemonSet)                     │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │              KMS (Key Management Service)                     │   │
│  │  - Alias: alias/eks/meteo-cluster                             │   │
│  │  - Encryption des données EKS                                │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### Composants AWS Détaillés

#### 1. VPC (Virtual Private Cloud)

- **CIDR** : `10.0.0.0/16`
- **Availability Zones** : 2 (us-east-1a, us-east-1b)
- **Public Subnets** :
  - `10.0.101.0/24` (AZ-1)
  - `10.0.102.0/24` (AZ-2)
- **Private Subnets** :
  - `10.0.1.0/24` (AZ-1)
  - `10.0.2.0/24` (AZ-2)
- **Internet Gateway** : 1 (pour les subnets publics)
- **NAT Gateway** : 1 (pour les subnets privés, mode dev)
- **DNS** : Activé (`enable_dns_hostnames`, `enable_dns_support`)

#### 2. EKS Cluster

- **Nom** : `meteo-cluster` (ou `meteo-cluster-{env}`)
- **Version Kubernetes** : `1.28`
- **Endpoint Access** :
  - Public : `true`
  - Private : `true`
- **Addons** :
  - `coredns` : DNS interne
  - `kube-proxy` : Proxy réseau
  - `vpc-cni` : Plugin réseau VPC
  - `aws-ebs-csi-driver` : Stockage persistant

#### 3. Node Group

- **Nom** : `main`
- **Instance Type** : `t3.medium`
- **Capacity Type** : `ON_DEMAND`
- **Scaling** :
  - Min : 1
  - Desired : 2
  - Max : 3
- **Labels** :
  - `Environment: dev`
  - `NodeGroup: main`

#### 4. ECR (Elastic Container Registry)

- **Région** : `us-east-1`
- **Repositories** :
  - `meteo-weather-service`
  - `meteo-location-service`
  - `meteo-weather-report-service`
- **Image Scanning** : Activé (`scanOnPush: true`)
- **Lifecycle Policy** : Aucune (images conservées indéfiniment)

#### 5. Load Balancer

- **Type** : Network Load Balancer (NLB)
- **Service** : `weather-report-service`
- **Port** : `8083`
- **Annotation** : `service.beta.kubernetes.io/aws-load-balancer-type: "nlb"`
- **DNS** : `{lb-id}.us-east-1.elb.amazonaws.com`

#### 6. CloudWatch

- **Log Group** : `/aws/eks/meteo-cluster/cluster`
- **Log Types** :
  - `api`
  - `audit`
  - `authenticator`
  - `controllerManager`
  - `scheduler`

#### 7. KMS

- **Alias** : `alias/eks/meteo-cluster`
- **Usage** : Chiffrement des données EKS
- **Deletion Window** : 7 jours

---

## Déploiement sur EKS

### Architecture Kubernetes

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Namespace: meteo               │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Service Account                         │   │
│  │  Name: meteo-service-account                         │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Secret: ecr-registry-secret             │   │
│  │  Type: docker-registry                               │   │
│  │  Server: {accountId}.dkr.ecr.us-east-1.amazonaws.com │   │
│  │  Username: AWS                                       │   │
│  │  Password: {ecr-token}                               │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Deployment: weather-service                   │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │ Pod: weather-service-{hash}                  │    │   │
│  │  │  - Image: meteo-weather-service:latest        │    │   │
│  │  │  - Port: 8081                                 │    │   │
│  │  │  - Resources: 250m CPU, 256Mi Memory          │    │   │
│  │  │  - ImagePullSecret: ecr-registry-secret       │    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  │                                                       │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │ Service: weather-service                      │    │   │
│  │  │  - Type: ClusterIP                             │    │   │
│  │  │  - Port: 8081                                  │    │   │
│  │  │  - Selector: app=weather-service               │    │   │
│  │  │  - DNS: weather-service.meteo.svc.cluster.local│    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Deployment: location-service                  │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │ Pod: location-service-{hash}                 │    │   │
│  │  │  - Image: meteo-location-service:latest      │    │   │
│  │  │  - Port: 8082                                 │    │   │
│  │  │  - Resources: 250m CPU, 256Mi Memory         │    │   │
│  │  │  - ImagePullSecret: ecr-registry-secret      │    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  │                                                       │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │ Service: location-service                     │    │   │
│  │  │  - Type: ClusterIP                            │    │   │
│  │  │  - Port: 8082                                 │    │   │
│  │  │  - Selector: app=location-service            │    │   │
│  │  │  - DNS: location-service.meteo.svc.cluster.local│   │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Deployment: weather-report-service             │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │ Pod: weather-report-service-{hash}           │    │   │
│  │  │  - Image: meteo-weather-report-service:latest│    │   │
│  │  │  - Port: 8083                                 │    │   │
│  │  │  - Resources: 250m CPU, 256Mi Memory         │    │   │
│  │  │  - Env:                                        │    │   │
│  │  │    WEATHER_SERVICE_URL=http://weather-service:8081│ │   │
│  │  │    LOCATION_SERVICE_URL=http://location-service:8082│ │ │
│  │  │  - ImagePullSecret: ecr-registry-secret      │    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  │                                                       │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │ Service: weather-report-service              │    │   │
│  │  │  - Type: LoadBalancer                        │    │   │
│  │  │  - Port: 8083                                │    │   │
│  │  │  - Selector: app=weather-report-service      │    │   │
│  │  │  - External IP: {lb-dns}                      │    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

### Configuration Helm

#### Chart Structure

```
helm/meteo-app/
├── Chart.yaml              # Métadonnées du chart
├── values.yaml             # Valeurs par défaut
└── templates/
    ├── _helpers.tpl        # Helpers Helm
    ├── namespace.yaml       # Namespace Kubernetes
    ├── secret.yaml         # Secret ECR
    ├── serviceaccount.yaml # Service Account
    ├── weather-service.yaml # Deployment + Service Weather
    ├── location-service.yaml # Deployment + Service Location
    └── weather-report-service.yaml # Deployment + Service Report
```

#### Variables Helm

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `global.awsRegion` | Région AWS | `us-east-1` |
| `global.awsAccountId` | ID du compte AWS | Auto-détecté |
| `global.ecrRepositoryPrefix` | Préfixe ECR | `meteo` |
| `global.imageTag` | Tag des images | `latest` |
| `global.ecrToken` | Token ECR | Requis |
| `weatherService.replicaCount` | Nombre de répliques | `1` |
| `locationService.replicaCount` | Nombre de répliques | `1` |
| `weatherReportService.replicaCount` | Nombre de répliques | `1` |

---

## Flux de Données

### Flux Complet : Requête Client → Réponse

```
1. Client
   │
   │ HTTP GET http://{lb-dns}:8083/api/report/Paris
   │
   ▼
2. Network Load Balancer (AWS)
   │
   │ Route vers le service Kubernetes
   │
   ▼
3. Service: weather-report-service (LoadBalancer)
   │
   │ Route vers un pod
   │
   ▼
4. Pod: weather-report-service-{hash}
   │
   │ Controller reçoit la requête
   │
   ▼
5. WeatherReportService
   │
   │ ┌─────────────────────────────────────┐
   │ │ 1. Appelle Location Service         │
   │ │    GET http://location-service:8082 │
   │ │    /api/location/Paris              │
   │ └──────────────┬──────────────────────┘
   │                │
   │                ▼
   │        6. Service: location-service (ClusterIP)
   │                │
   │                ▼
   │        7. Pod: location-service-{hash}
   │                │
   │                ▼
   │        8. LocationController
   │                │
   │                ▼
   │        9. Retourne: {"city": "Paris", "country": "France", ...}
   │                │
   │                └──────────────────┐
   │                                   │
   │ ┌─────────────────────────────────┘
   │ │
   │ │ ┌─────────────────────────────────────┐
   │ │ │ 2. Appelle Weather Service           │
   │ │ │    GET http://weather-service:8081   │
   │ │ │    /api/weather/Paris                │
   │ │ └──────────────┬──────────────────────┘
   │ │                │
   │ │                ▼
   │ │        10. Service: weather-service (ClusterIP)
   │ │                │
   │ │                ▼
   │ │        11. Pod: weather-service-{hash}
   │ │                │
   │ │                ▼
   │ │        12. WeatherController
   │ │                │
   │ │                ▼
   │ │        13. Retourne: {"city": "Paris", "temperature": 15, ...}
   │ │                │
   │ │                └──────────────────┐
   │ │                                   │
   │ └───────────────────────────────────┘
   │
   │ ┌─────────────────────────────────────┐
   │ │ 3. Combine les résultats            │
   │ │    WeatherReport {                  │
   │ │      location: {...},               │
   │ │      weather: {...}                 │
   │ │    }                                │
   │ └──────────────┬──────────────────────┘
   │                │
   │                ▼
14. Retourne la réponse au client
   │
   │ HTTP 200 OK
   │ {
   │   "location": {...},
   │   "weather": {...}
   │ }
   │
   ▼
15. Client reçoit le rapport complet
```

### Séquence Temporelle

```
Temps    Action
─────────────────────────────────────────────────────────────
T+0ms    Client envoie GET /api/report/Paris
T+5ms    LoadBalancer route vers weather-report-service pod
T+10ms   WeatherReportService reçoit la requête
T+15ms   WeatherReportService appelle location-service
T+20ms   LocationService traite et retourne les données
T+25ms   WeatherReportService reçoit la réponse location
T+30ms   WeatherReportService appelle weather-service
T+35ms   WeatherService traite et retourne les données
T+40ms   WeatherReportService reçoit la réponse weather
T+45ms   WeatherReportService combine les résultats
T+50ms   Réponse envoyée au client
T+55ms   Client reçoit le rapport complet
```

---

## Sécurité et Authentification

### ECR Authentication

- **Méthode** : Token ECR temporaire (valide 12h)
- **Génération** : `aws ecr get-login-password --region us-east-1`
- **Stockage** : Kubernetes Secret (`ecr-registry-secret`)
- **Usage** : Pull des images Docker depuis ECR

### Kubernetes Secrets

- **Type** : `docker-registry`
- **Namespace** : `meteo`
- **Nom** : `ecr-registry-secret`
- **Contenu** :
  - Server : `{accountId}.dkr.ecr.us-east-1.amazonaws.com`
  - Username : `AWS`
  - Password : `{ecr-token}`

### Network Policies

- **Actuellement** : Aucune (tous les pods peuvent communiquer)
- **Recommandation** : Implémenter des Network Policies pour isoler les services

### Encryption

- **EKS** : Chiffrement au repos avec KMS
- **Trafic** : HTTPS recommandé pour la production (non implémenté actuellement)

---

## CI/CD Pipeline

### GitHub Actions Workflows

#### 1. Build and Push to ECR (`client.yaml`)

```
Trigger: Push sur main/dev ou Pull Request
Jobs:
  1. create-ecr-repositories
     - Crée les repositories ECR s'ils n'existent pas
  2. build-and-push (Matrix: 3 services)
     - Checkout code
     - Setup JDK 17
     - Configure AWS credentials
     - Login to ECR
     - Build Maven project
     - Build Docker image
     - Tag image (SHA + latest)
     - Push to ECR
```

#### 2. Deploy to EKS (`deploy-eks.yaml`)

```
Trigger: Workflow dispatch ou Push sur main
Jobs:
  1. terraform-plan
     - Plan Terraform
     - Upload plan artifact
  2. terraform-apply (dépend de terraform-plan)
     - Download plan
     - Apply Terraform
     - Get cluster name
     - Configure kubectl
  3. deploy-helm (dépend de terraform-apply)
     - Get cluster info
     - Configure kubectl
     - Setup Helm
     - Get AWS Account ID
     - Get ECR Token
     - Create ECR Secret
     - Deploy with Helm
     - Verify deployment
     - Get LoadBalancer URL
  4. terraform-destroy (optionnel)
     - Uninstall Helm
     - Destroy infrastructure
```

### Flux CI/CD Complet

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer                                  │
│                                                              │
│  git commit -m "Update service"                              │
│  git push origin main                                        │
└───────────────────────┬───────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Repository                               │
│                                                              │
│  Push event déclenche les workflows                          │
└───────────────────────┬───────────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
        ▼                               ▼
┌──────────────────┐          ┌──────────────────┐
│ client.yaml      │          │ deploy-eks.yaml  │
│ (Build & Push)   │          │ (Deploy)         │
└────────┬─────────┘          └────────┬─────────┘
         │                              │
         ▼                              │
┌──────────────────────────────────────┐│
│ 1. Build Maven                       ││
│ 2. Build Docker Images                ││
│ 3. Push to ECR                        ││
│    - meteo-weather-service:abc123    ││
│    - meteo-location-service:abc123   ││
│    - meteo-weather-report-service:abc123││
└────────┬─────────────────────────────┘│
         │                              │
         │                              │
         └──────────────┬───────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    AWS ECR                                   │
│                                                              │
│  Images disponibles:                                        │
│  - meteo-weather-service:abc123                             │
│  - meteo-location-service:abc123                            │
│  - meteo-weather-report-service:abc123                      │
└───────────────────────┬───────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Actions (deploy-eks.yaml)               │
│                                                              │
│  1. terraform-plan → Créer le plan                          │
│  2. terraform-apply → Créer le cluster EKS                  │
│  3. deploy-helm → Déployer les services                     │
│     - Pull images depuis ECR                                │
│     - Créer les pods                                        │
│     - Exposer les services                                 │
└───────────────────────┬───────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              AWS EKS Cluster                                │
│                                                              │
│  Services déployés et running                               │
│  LoadBalancer URL disponible                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Schémas Visuels

### Schéma de Déploiement Complet

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          INTERNET                                        │
└───────────────────────────────┬─────────────────────────────────────────┘
                                  │
                                  │ HTTP GET
                                  │ {lb-dns}:8083/api/report/Paris
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    AWS Network Load Balancer                             │
│                    {lb-id}.us-east-1.elb.amazonaws.com                   │
└───────────────────────────────┬─────────────────────────────────────────┘
                                  │
                                  │ Route vers
                                  │ weather-report-service
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    AWS EKS Cluster (meteo-cluster)                      │
│                                                                           │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                    VPC: 10.0.0.0/16                              │  │
│  │                                                                   │  │
│  │  ┌────────────────────┐        ┌────────────────────┐           │  │
│  │  │ Public Subnet      │        │ Private Subnet     │           │  │
│  │  │ 10.0.101.0/24      │        │ 10.0.1.0/24        │           │  │
│  │  │                    │        │                    │           │  │
│  │  │ - Internet Gateway │        │ - NAT Gateway      │           │  │
│  │  │ - Load Balancer    │        │ - EKS Nodes         │           │  │
│  │  └────────────────────┘        └─────────┬──────────┘           │  │
│  │                                           │                       │  │
│  │                                           │                       │  │
│  │  ┌───────────────────────────────────────▼───────────────────┐   │  │
│  │  │         EKS Node Group (t3.medium)                        │   │  │
│  │  │                                                           │   │  │
│  │  │  ┌───────────────────────────────────────────────────┐  │   │  │
│  │  │  │  Namespace: meteo                                  │  │   │  │
│  │  │  │                                                     │  │   │  │
│  │  │  │  ┌──────────────┐  ┌──────────────┐               │  │   │  │
│  │  │  │  │ Weather      │  │ Location     │               │  │   │  │
│  │  │  │  │ Service      │  │ Service      │               │  │   │  │
│  │  │  │  │ Pod:8081     │  │ Pod:8082     │               │  │   │  │
│  │  │  │  │              │  │              │               │  │   │  │
│  │  │  │  │ ClusterIP    │  │ ClusterIP   │               │  │   │  │
│  │  │  │  └──────┬───────┘  └──────┬───────┘               │  │   │  │
│  │  │  │         │                 │                        │  │   │  │
│  │  │  │         └────────┬────────┘                        │  │   │  │
│  │  │  │                  │                                 │  │   │  │
│  │  │  │  ┌───────────────▼───────────────┐               │  │   │  │
│  │  │  │  │ Weather Report Service        │               │  │   │  │
│  │  │  │  │ Pod:8083                      │               │  │   │  │
│  │  │  │  │                               │               │  │   │  │
│  │  │  │  │ LoadBalancer Service          │               │  │   │  │
│  │  │  │  │ → Exposé via NLB              │               │  │   │  │
│  │  │  │  └───────────────────────────────┘               │  │   │  │
│  │  │  └───────────────────────────────────────────────────┘  │   │  │
│  │  └───────────────────────────────────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────┘
                                  │
                                  │ Pull images
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    AWS ECR                                              │
│                    {accountId}.dkr.ecr.us-east-1.amazonaws.com          │
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐     │
│  │ meteo-weather-   │  │ meteo-location- │  │ meteo-weather-   │     │
│  │ service          │  │ service         │  │ report-service   │     │
│  │                  │  │                 │  │                  │     │
│  │ :latest          │  │ :latest         │  │ :latest          │     │
│  │ :abc123          │  │ :abc123         │  │ :abc123          │     │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘     │
└─────────────────────────────────────────────────────────────────────────┘
```

### Ports et Endpoints Résumé

| Service | Port Local | Port Container | Port Kubernetes | Type Service | Endpoint Public |
|---------|-----------|----------------|-----------------|--------------|----------------|
| Weather Service | - | 8081 | 8081 | ClusterIP | Non |
| Location Service | - | 8082 | 8082 | ClusterIP | Non |
| Weather Report Service | - | 8083 | 8083 | LoadBalancer | Oui (via NLB) |

### URLs d'Accès

#### En Local (Docker Compose)
- Weather Service : `http://localhost:8081/api/weather/{city}`
- Location Service : `http://localhost:8082/api/location/{city}`
- Weather Report Service : `http://localhost:8083/api/report/{city}`

#### En Kubernetes (EKS)
- Weather Service (interne) : `http://weather-service:8081/api/weather/{city}`
- Location Service (interne) : `http://location-service:8082/api/location/{city}`
- Weather Report Service (public) : `http://{lb-dns}:8083/api/report/{city}`

---

## Résumé des Technologies et Versions

### Backend
- **Java** : 17
- **Spring Boot** : 3.x
- **Maven** : 3.9+
- **Build Tool** : Maven Multi-module

### Containerisation
- **Docker** : Latest
- **Base Image** : `eclipse-temurin:17-jre-alpine`
- **Registry** : AWS ECR

### Infrastructure
- **Kubernetes** : 1.28
- **Terraform** : >= 1.0
- **Helm** : 3.13.0
- **AWS Provider** : ~> 5.0

### Cloud
- **AWS Region** : us-east-1
- **EKS Module** : ~> 20.0
- **VPC Module** : ~> 5.0

### CI/CD
- **GitHub Actions** : Latest
- **AWS CLI** : Latest
- **kubectl** : Latest

---

## Coûts Estimés AWS

| Ressource | Coût Mensuel | Description |
|-----------|--------------|-------------|
| EKS Cluster | ~$72 | $0.10/heure × 24h × 30j |
| NAT Gateway | ~$32 | $0.045/heure × 24h × 30j |
| EC2 Instances (2x t3.medium) | ~$60 | $0.0416/heure × 2 × 24h × 30j |
| Network Load Balancer | ~$16 | $0.0225/heure + trafic |
| ECR Storage | ~$1-5 | Selon le nombre d'images |
| CloudWatch Logs | ~$5-10 | Selon le volume de logs |
| **Total** | **~$186-200/mois** | Environnement de développement |

---

## Commandes Utiles

### Local

```bash
# Lancer avec Docker Compose
docker compose up -d

# Voir les logs
docker compose logs -f

# Arrêter
docker compose down
```

### Kubernetes

```bash
# Configurer kubectl
aws eks update-kubeconfig --region us-east-1 --name meteo-cluster

# Voir les pods
kubectl get pods -n meteo

# Voir les services
kubectl get svc -n meteo

# Voir les logs
kubectl logs -n meteo deployment/weather-service

# Scale un service
kubectl scale deployment weather-service --replicas=3 -n meteo
```

### Terraform

```bash
# Initialiser
terraform init

# Planifier
terraform plan

# Appliquer
terraform apply

# Détruire
terraform destroy
```

### Helm

```bash
# Déployer
helm upgrade --install meteo-app ./helm/meteo-app \
  --namespace meteo \
  --create-namespace

# Mettre à jour
helm upgrade meteo-app ./helm/meteo-app \
  --namespace meteo \
  --set global.imageTag=abc123

# Désinstaller
helm uninstall meteo-app -n meteo
```

---

## Conclusion

Ce document présente l'architecture complète du projet Meteo, depuis les microservices Spring Boot jusqu'au déploiement sur AWS EKS. Tous les composants, ports, configurations et flux de données sont documentés pour faciliter la compréhension et la maintenance du système.

Pour plus de détails sur un composant spécifique, consultez :
- `README.md` : Vue d'ensemble du projet
- `EKS_DEPLOYMENT_GUIDE.md` : Guide de déploiement EKS
- `terraform/README.md` : Configuration Terraform
- `helm/README.md` : Configuration Helm
- `terraform/TROUBLESHOOTING.md` : Dépannage

