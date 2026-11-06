# Build AUTUA BFF from local clone context (../autua-bff). JDK 25.

FROM eclipse-temurin:25-jdk AS build
WORKDIR /workspace

COPY mvnw pom.xml ./
COPY .mvn .mvn
COPY .maven .maven
RUN sed -i 's/\r$//' mvnw && chmod +x mvnw

RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw -B -DskipTests dependency:go-offline || true

COPY src ./src
COPY lombok.config* ./

RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw -B -DskipTests package \
 && JAR=$(ls target/*.jar | grep -v '\.original$' | head -n 1) \
 && cp "$JAR" /workspace/app.jar

FROM eclipse-temurin:25-jre AS runtime
WORKDIR /app
RUN useradd -r -u 10001 autua \
 && mkdir -p /app/logs \
 && chown -R autua:autua /app
COPY --from=build /workspace/app.jar /app/app.jar
USER autua
EXPOSE 8081
ENTRYPOINT ["java","-jar","/app/app.jar"]
