# Autenticação local (auth-mock)

## Contratos

| Contrato | Uso |
|----------|-----|
| OIDC discovery / JWKS RS256 | Resource server API/BFF |
| `iss` / `aud` (`10197_radar`) / `azp` | Validação JWT |
| Scopes Gelus `p~RECURSO~OPERACAO` | Converter → autorização |
| `GET /auth/login/authorize-url` + token | BFF / WEB login |
| Vínculo usuário/órgão (stub) | Gestão usuários |
| `GET /e2e/token?user=local-ok` | Smoke (não usar em prod) |

Chaves geradas em `docker/auth-mock/keys` (gitignored).

## Usuários sintéticos (`docker/auth-mock/server.py`)

| Key | Papel | Enrollment `CADASTRAR_LOTE` |
|-----|-------|----------------------------|
| `local-ok` | Gestor de Dispositivos + Agente + scopes DI | **Sim** |
| `local-403` | Agente sem gestor | Não |
| `local-missing` | Só LOGIN | Não |

Scopes DI em `local-ok`:

- `DISPOSITIVO_INSTITUCIONAL:CADASTRAR_LOTE`
- `DISPOSITIVO_INSTITUCIONAL:CONSULTAR`
- `DISPOSITIVO_INSTITUCIONAL:ATIVAR_DESATIVAR`

CPF sintético `39053344705` · CNPJ órgão `00000000000191` · IDs Compose `LOCAL_ORGAO_ID=919001` (seed 10).

## Ativação

```powershell
docker compose --env-file .env --profile auth-mock build auth-mock
docker compose --env-file .env --profile auth-mock up -d auth-mock
```

Preencher issuer/JWKS no `.env` (ver `.env.example`).

**Importante:** após atualizar `server.py`, **rebuild** a imagem. `docker cp` em container antigo é paliativo de ensaio, não o fluxo oficial.

## Fixture PG

Auth-mock emite JWT; a API resolve gestor/órgão no banco. Sem seed 10, create enrollment falha (“Gestor e órgão do contexto…”).

```powershell
.\scripts\seed-minimo.ps1 -Authorized
```

## Proibições

- Não reutilizar tokens reais / issuer de `sub`.
- Não desabilitar validação JWT na API/BFF.
- Não registrar tokens completos em relatórios.
- Não enfraquecer `@PreAuthorize` / scopes na API.
