FROM eclipse-temurin:21-jre

ARG APP_VERSION=dev

WORKDIR /app
COPY target/shipstack-batch-app.jar /app/app.jar

ENV APP_VERSION="$APP_VERSION"
CMD ["java", "-jar", "/app/app.jar"]
