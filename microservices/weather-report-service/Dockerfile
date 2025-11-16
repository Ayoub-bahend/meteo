# Build stage
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copy parent pom.xml
COPY pom.xml /app/pom.xml

# Copy service pom.xml and source code
COPY microservices/weather-report-service/pom.xml /app/microservices/weather-report-service/pom.xml
COPY microservices/weather-report-service/src /app/microservices/weather-report-service/src

# Build the application
RUN mvn clean package -DskipTests -pl microservices/weather-report-service -am

# Runtime stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copy jar from build stage
COPY --from=build /app/microservices/weather-report-service/target/*.jar app.jar

# Expose port
EXPOSE 8083

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]