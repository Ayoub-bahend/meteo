# Build stage
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copy parent pom.xml
COPY pom.xml /app/pom.xml

# Create microservices directory structure
RUN mkdir -p /app/microservices

# Copy all service pom.xml files (required by parent POM validation)
COPY microservices/weather-service/pom.xml /app/microservices/weather-service/pom.xml
COPY microservices/location-service/pom.xml /app/microservices/location-service/pom.xml
COPY microservices/weather-report-service/pom.xml /app/microservices/weather-report-service/pom.xml

# Copy only the source code of the current service
COPY microservices/weather-service/src /app/microservices/weather-service/src

# Build the application
RUN mvn clean package -DskipTests -pl microservices/weather-service -am

# Runtime stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copy jar from build stage (Spring Boot creates a fat jar)
COPY --from=build /app/microservices/weather-service/target/weather-service-*.jar app.jar

# Expose port
EXPOSE 8081

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]