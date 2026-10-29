FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /app

COPY pom.xml .

RUN mvn dependency:go-offline

COPY src ./src

RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

COPY --from=builder /app/target/*-jar-with-dependencies.jar ./app.jar

CMD ["java", "-jar", "app.jar"]

# Build the image:
#   docker build -t ascent-logs .
# Run the container (with env variables from .env):
#   docker run --env-file .env -p 8080:8080 ascent-logs
