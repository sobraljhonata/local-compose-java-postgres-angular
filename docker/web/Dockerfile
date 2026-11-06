# syntax=docker/dockerfile:1
# AUTUA WEB — modo desenvolvimento em container.
# O navegador no HOST usa localhost:8080/8081 (portas publicadas).
# NÃO embute hostnames Docker (autua-api/autua-bff) no bundle Angular.

FROM node:22-bookworm

WORKDIR /web

ENV HUSKY=0 \
    NG_CLI_ANALYTICS=false \
    CHOKIDAR_USEPOLLING=true

EXPOSE 4200

# Em desenvolvimento o código é montado via volume (compose.dev / profile web-bind).
# Homologação local: build stage separado (ver Dockerfile.homolog).

CMD ["sh", "-c", "npm ci --ignore-scripts && npm run start -- --host 0.0.0.0 --port 4200"]
