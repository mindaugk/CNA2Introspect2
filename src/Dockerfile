FROM maven:3.9.6-eclipse-temurin-17 AS build

WORKDIR /app
COPY pom.xml /app/pom.xml
COPY src /app/src
RUN mvn -q -e -DskipTests package

FROM eclipse-temurin:17-jre

WORKDIR /app
COPY --from=build /app/target/claim-status-api.jar /app/claim-status-api.jar

EXPOSE 8080
CMD ["java", "-jar", "/app/claim-status-api.jar"]
