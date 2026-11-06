# Autenticação local (auth-mock)

## Contratos confirmados (código)

Fonte: `autua-local-e2e` identity + `autua-bff` `application.yml` + API Gelus/JWT.

| Contrato | Uso |
|----------|-----|
| OIDC discovery / JWKS RS256 | Resource server API/BFF |
| `iss` / `aud` (`10197_radar`) / `azp` | Validação JWT |
| Scopes Gelus `p~RECURSO~OPERACAO` | Converter → `OPERACAO RECURSO` |
| `GET /auth/login/authorize-url` + `POST .../token` | BFF / WEB login |
| Vínculo usuário/órgão (stub) | Gestão usuários |

Claims fictícios usados pelo mock: CPF sintético, `orgao` CNPJ fictício, scopes de dispositivo (CONSULTAR, AUTORIZAR, ATIVAR_DESATIVAR, …). Tokens **curta duração**, assinados com chave **gerada no volume local** (`docker/auth-mock/keys`).

## Ativação explícita

```powershell
docker compose --profile auth-mock up -d auth-mock
```

Preencher no `.env` (exemplo):

```env
GELUS_ISSUER_URI=http://auth-mock:8080/realms/autua-local
JWT_ISSUER_URI=http://auth-mock:8080/realms/autua-local
JWT_JWK_SET_URI=http://auth-mock:8080/realms/autua-local/protocol/openid-connect/certs
AUTUA_BFF_AUTH_LOGIN_BASE_URL=http://auth-mock:8080/auth/login
AUTUA_BFF_AUTENTICACAO_API_BASE_URL=http://auth-mock:8080
GELUS_CLIENT_ID=autua-local
GELUS_CLIENT_SECRET=autua-local-secret
LOCAL_PUBLIC_BASE=http://127.0.0.1:18082
```

## Proibições

- Não reutilizar token expirado real como credencial.
- Não desabilitar validação de assinatura/exp/iss/aud.
- Não aceitar issuer de VAL/subcontratacao neste profile.
- Não registrar tokens completos em relatórios.
- Não alterar security de produção nos repositórios de aplicação para acomodar o mock (somente env Compose).

## Nota

Implementação adaptada do servidor E2E existente (contratos já exercitados). Profile **opcional**; stack API/BFF sobe sem ele, com auth externa se configurada — preferível local-only na Fase B.
