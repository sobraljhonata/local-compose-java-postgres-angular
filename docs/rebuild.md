# Rebuild a partir dos clones locais

## Princípios

- Context Docker = diretório do clone (`autua-api`, `autua-bff`, `autua-web-frontend`).
- **Não** executa `git checkout`, `pull`, `stash` ou `reset`.
- Working tree sujo é preservado (modo `dev`).
- Modo `homolog` (`AUTUA_MODE=homolog`) exige árvore limpa ou `AUTUA_ALLOW_DIRTY=1` + evidência.

## Comandos

```powershell
cd C:\dev\Projetos\serpro\autua-local-compose
.\scripts\01-git-status.ps1
.\scripts\02-build.ps1
.\scripts\07-rebuild-service.ps1 -Service autua-api
```

## .dockerignore

Se o clone ainda não tiver `.dockerignore`, `02-build.ps1` copia o template de `docker/*/dockerignore` **somente quando ausente**.

## Cache Maven

BuildKit `--mount=type=cache,target=/root/.m2`. Nexus Serpro pode ser necessário na primeira build (sem `-o` forçado no Dockerfile).

## WEB

- Profile `web`: volume bind do clone → preserva I5.1 + WIP MAD; browser usa `localhost:8080/8081`.
- Profile `web-homolog`: multi-stage nginx; context `serpro/`; mesma regra de URLs localhost no bundle.
