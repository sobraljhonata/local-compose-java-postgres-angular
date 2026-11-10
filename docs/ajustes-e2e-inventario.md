# Inventário de ajustes E2E (J01–J03) → consolidação

Fonte: `_snapshots/gd-mvp-rc1-app-e2e/local-e2e/06`–`15`.  
Objetivo: tornar cada ajuste **reproduzível** via `autua-local-compose` sem código de negócio.

| # | Problema | Solução na época | Arquivos | Ainda ativo? | Manual? | Como reproduzir |
|---|----------|------------------|----------|--------------|---------|-----------------|
| 1 | Portas 8080/8081/4200/5433 ocupadas | Remap `.env` → 18080/18081/14200/5434 | `.env` (local) | Sim (máquina E2E) | Sim (copiar example) | `.env.example` documenta remap |
| 2 | WEB tip → `:8080` | Override temporário `environment.ts` / bridge nginx | tip WEB / `_tmp-j03-web-bridge` | Bridge temp **não** shareable | Era manual | **`scripts/web-start.ps1`** + overlay/proxy |
| 3 | Auth-mock sem scopes DI no container antigo | `docker cp server.py` + restart | `docker/auth-mock/server.py` (já tem DI) | Host OK; imagem pode estar stale | Rebuild | `docker compose build auth-mock` + up |
| 4 | PG sanitizado sem usuário `local-ok` | Seed `10-*.sql` | `ensaios/.../10-seed-*.sql` | Dados na volume atual | Sim (explícito) | **`scripts/seed-minimo.ps1`** |
| 5 | QR APP exige HTTPS | Política HTTP só `ENV=local` debug | **AUTUA-APP** (fora deste repo) | Local dirty no clone | Depende commit APP | Documentar: clone APP com COR-QR + dart-defines |
| 6 | APK URLs | `--dart-define=ENV=local` + BFF `127.0.0.1:8081` + adb reverse | scripts android | APK local | Sim | **`scripts/android.ps1`** |
| 7 | `AUTUA_BFF_PUBLIC_BASE_URL` | `http://127.0.0.1:18081/autua-bff` | `.env` / compose | Sim | Config | `.env.example` |
| 8 | CORS WEB `:14200` | `AUTUA_BFF_CORS_ALLOWED_ORIGINS` | compose env | Sim na stack E2E | Config | `.env.example` |
| 9 | Compose web `npm ci` frágil no Windows | WEB no host via ng serve | — | Preferido | Script | `web-start.ps1` |
| 10 | GD-48 TLS bypass | **Proibido** | ensaios tls-proxy | Não usar | — | Fora do setup oficial |

## Dependências externas (não versionadas aqui)

| Dependência | Como obter | No Git? |
|-------------|------------|---------|
| Dump sanitizado B.2 | Artefato interno + `docs/restore.md` | **Não** (só `incoming/.gitkeep`) |
| Clones API/BFF/WEB/APP nos pins RC1 | Git corporativo | Separados |
| Chaves auth-mock | Geradas no volume `docker/auth-mock/keys` | Ignoradas (`.gitignore`) |
| COR-QR no APP | Branch/commit com política HTTP local | Precisa estar no clone APP compartilhado |
| Android SDK / FVM / Node / JDK | Máquina do dev | — |
