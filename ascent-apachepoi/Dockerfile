FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn clean package -DskipTests

# Imagem final — alpine com AWS CLI instalado
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Instala AWS CLI via pip (método suportado em alpine)
RUN apk add --no-cache python3 py3-pip curl && \
    pip3 install --no-cache-dir --break-system-packages awscli && \
    aws --version

COPY --from=builder /app/target/*-jar-with-dependencies.jar ./app.jar

CMD ["java", "-Xmx2g", "-jar", "app.jar"]
