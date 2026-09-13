FROM public.ecr.aws/amazoncorretto/amazoncorretto:21-al2023-headless

ARG APP_VERSION=dev

WORKDIR /app
COPY target/shipstack-eks-app.jar /app/app.jar

USER 10001
ENV APP_VERSION="$APP_VERSION" \
    JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:+UseContainerSupport"
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
