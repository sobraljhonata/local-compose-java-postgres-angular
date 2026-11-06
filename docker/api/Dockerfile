# Build AUTUA API from local clone context (../autua-api). JDK 25.
# Não executa git checkout/pull. Usa o working tree presente no contexto.

FROM eclipse-temurin:25-jdk AS build
WORKDIR /workspace

COPY mvnw pom.xml ./
COPY .mvn .mvn
COPY settings.xml* ./
COPY .maven .maven
# Clones Windows podem trazer CRLF no shebang → "not found" no Linux
RUN sed -i 's/\r$//' mvnw && chmod +x mvnw

# Cache Maven; offline só se o cache estiver completo
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
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
