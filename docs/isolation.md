# Isolamento de ambientes

| Ambiente | Compose / processo | Portas típicas | Volume PG |
|----------|-------------------|----------------|-----------|
| Stack host GD (I2–I5) | Java + `autua-postgres-gd-local` | 8080/8081/4200/5433 | `autua_gd_pgdata_local` |
| `autua-local-e2e` | JARs pré-build + identity | 18080/18081/5435/18082 | `autua-e2e-pgdata` |
| **autua-local-compose** | Build dos clones | 8080/8081/4200/5433 (configurável) | `autua_local_compose_pgdata` |
| subcontratacao | remoto | — | **proibido** |

## Regras

1. Rede Docker `autua-local-net` — sem `network_mode: host`.
2. Postgres bind apenas `127.0.0.1`.
3. Sem Docker socket montado; sem privileged.
4. Variáveis de upstream BFF **vazias** por padrão — preencher só destinos locais (auth-mock / API).
5. Não versionar `.env`, dumps, PEM, tokens.
6. Auth-mock issuer `http://auth-mock:8080/realms/autua-local` — chaves geradas localmente; **não** confiar em tokens de ambientes compartilhados.
7. APP fora do escopo.
