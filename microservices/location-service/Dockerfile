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
COPY microservices/location-service/src /app/microservices/location-service/src

# Build the application
RUN mvn clean package -DskipTests -pl microservices/location-service -am

# Runtime stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copy jar from build stage
COPY --from=build /app/microservices/location-service/target/*.jar app.jar

# Expose port
EXPOSE 8082

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]