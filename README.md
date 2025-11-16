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
cd weather-service
mvn clean install
```

## Running the Services

You need to run the services in the following order:

### 1. Start Weather Service
```bash
cd weather-service
mvn spring-boot:run
```
Service will start on port 8081

### 2. Start Location Service
```bash
cd location-service
mvn spring-boot:run
```
Service will start on port 8082

### 3. Start Weather Report Service
```bash
cd weather-report-service
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
├── weather-service/                 # Weather Service Module
│   ├── pom.xml
│   └── src/main/java/com/meteo/weather/
│       ├── WeatherServiceApplication.java
│       ├── controller/
│       │   └── WeatherController.java
│       ├── model/
│       │   └── Weather.java
│       └── service/
│           └── WeatherService.java
├── location-service/                # Location Service Module
│   ├── pom.xml
│   └── src/main/java/com/meteo/location/
│       ├── LocationServiceApplication.java
│       ├── controller/
│       │   └── LocationController.java
│       ├── model/
│       │   └── Location.java
│       └── service/
│           └── LocationService.java
└── weather-report-service/          # Weather Report Service Module
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

## License

This is a simple educational project.
