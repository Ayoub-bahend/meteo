# Build stage
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copy parent pom.xml
COPY pom.xml /app/pom.xml

# Copy service pom.xml and source code
COPY microservices/weather-service/pom.xml /app/microservices/weather-service/pom.xml
COPY microservices/weather-service/src /app/microservices/weather-service/src

# Build the application
RUN mvn clean package -DskipTests -pl microservices/weather-service -am

# Runtime stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copy jar from build stage
COPY --from=build /app/microservices/weather-service/target/*.jar app.jar

# Expose port
EXPOSE 8081

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]