FROM eclipse-temurin:21-jre

ARG APP_VERSION=dev

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --create-home --uid 10001 appuser

WORKDIR /app
COPY target/ecs-platform-demo.jar /app/app.jar
RUN chown appuser:appuser /app/app.jar

USER appuser
ENV APP_VERSION="$APP_VERSION" \
    JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:+UseContainerSupport"
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
