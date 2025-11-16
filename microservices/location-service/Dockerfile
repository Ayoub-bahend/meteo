# Build stage
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copy parent pom.xml
COPY pom.xml /app/pom.xml

# Copy service pom.xml and source code
COPY microservices/location-service/pom.xml /app/microservices/location-service/pom.xml
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