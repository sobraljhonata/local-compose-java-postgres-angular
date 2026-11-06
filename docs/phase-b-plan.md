# Plano Fase B — autorização necessária

## Pré-condições

1. **Escolher um dump** entre os quatro candidatos (ver `restore.md`).
2. Confirmar se há PII e se sanitização é exigida antes do restore.
3. Liberar portas **ou** alterar `.env` (`API_HOST_PORT`, etc.) para não colidir com:
   - `autua-postgres-gd-local` :5433
   - Java API :8080 / BFF :8081
   - Angular :4200  
   **Scripts não encerram esses processos automaticamente.**
4. Copiar `.env.example` → `.env` com senha local.
5. Definir se `auth-mock` entra no primeiro boot.
6. Decidir Flyway on/off após inspeção do dump vs API `6e89e8ae`.

## Destinos

| Recurso | Valor |
|---------|-------|
| Projeto Compose | `autua-local` |
| Volume PG | `autua_local_compose_pgdata` |
| Containers | `autua-local-postgres`, `autua-local-api`, `autua-local-bff`, (+ web/auth-mock) |
| Rede | `autua-local-net` |

## Sequência proposta

1. `.\scripts\00-prereqs.ps1`
2. `.\scripts\01-git-status.ps1` (registrar SHAs)
3. `.\scripts\02-build.ps1` (já permitido na Fase A se Docker/Nexus OK)
4. Com autorização: `$env:AUTUA_PHASE_B_AUTHORIZED=1`
5. `docker compose up -d postgres` apenas
6. Restore **manual** documentado do dump escolhido → evidência em `evidence/`
7. Validar schemas / contagens
8. `docker compose up -d autua-api autua-bff` (+ profiles)
9. `.\scripts\08-smoke.ps1` (GET-only)
10. Testes de negócio autenticados **somente** com identidades fictícias do auth-mock

## Rollback

- `.\scripts\06-down.ps1` (preserva volume)
- Volume wipe: comando explícito separado, nunca em script de rotina
- Stack host GD permanece disponível se não for parada manualmente

## Critérios GO Fase B

- [ ] Dump único identificado pelo usuário
- [ ] Plano de PII/sanitização aceito
- [ ] Portas definidas sem overwrite silencioso
- [ ] Volume novo vazio confirmado
- [ ] `AUTUA_PHASE_B_AUTHORIZED=1` emitido pelo usuário
- [ ] Sem push/deploy/subcontratacao
