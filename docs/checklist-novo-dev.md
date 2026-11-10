# Checklist — novo desenvolvedor (local-compose)

- [ ] Docker Desktop + Compose no Windows 11
- [ ] JDK 21+ / Maven; Node 20+; (opcional) FVM + Android SDK
- [ ] Clones irmãos na mesma pasta pai:
  - `autua-api` @ pin RC1 (`a079891a` ou tip acordado)
  - `autua-bff` @ `9a2009a`+
  - `autua-web-frontend` @ `09d676c`+
  - `autua-app` com **COR-QR** (HTTP local) disponível no clone — alteração local não commitada **não** conta como shareable
- [ ] `cd autua-local-compose` · `Copy-Item .env.example .env` · editar senhas
- [ ] `.\scripts\doctor.ps1`
- [ ] Obter dump sanitizado (fora do Git) · seguir `docs/restore.md` **só se** volume novo
- [ ] ` $env:AUTUA_LOCAL_START_AUTHORIZED=1; .\scripts\start.ps1 ` (ou `03-up.ps1` com Fase B)
- [ ] Rebuild auth-mock se `server.py` mudou: `docker compose --profile auth-mock build auth-mock`
- [ ] `.\scripts\seed-minimo.ps1 -Authorized` (fixture `local-ok` / 919001)
- [ ] `.\scripts\verify.ps1`
- [ ] WEB: `.\scripts\web-start.ps1` → http://127.0.0.1:14200 · login auth-mock `local-ok`
- [ ] APP: `.\scripts\android.ps1` · build com dart-defines documentados · install só com `-InstallConfirm`
- [ ] Enrollment: WEB Gerar QR → APP ler (QR HTTP só `ENV=local` debug)
- [ ] Ao sair: Ctrl+C no web-start (restaura tip) ou `.\scripts\web-stop.ps1`

## Não fazer

- Commit/push automático; `down -v`; restore em volume compartilhado sem auth; GD-48; apontar tip para `sub` neste fluxo.
