FROM public.ecr.aws/docker/library/maven:3.9.6-eclipse-temurin-21 AS build

WORKDIR /app
COPY pom.xml /app/pom.xml
COPY src /app/src
RUN mvn -q -e -DskipTests package

FROM public.ecr.aws/docker/library/eclipse-temurin:21-jre

WORKDIR /app
COPY --from=build /app/target/claim-status-api.jar /app/claim-status-api.jar

EXPOSE 8080
CMD ["java", "-jar", "/app/claim-status-api.jar"]
