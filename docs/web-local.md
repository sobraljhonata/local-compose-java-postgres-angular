# WEB local (sem editar tip permanente)

## Problema (J03)

`environment.ts` do tip aponta `BASE_URL_BFF` para `http://localhost:8080/autua-bff`.  
Com portas remapeadas (`BFF_HOST_PORT=18081`), o browser não alcança o BFF Compose sem override.

## Solução consolidada

1. Overlay versionado **neste** repositório: `config/web/environment.local-compose.ts`  
   - `BASE_URL_BFF: '/autua-bff'` (relativo)  
   - `FRONTEND_URL: 'http://127.0.0.1:14200'`
2. Proxy versionado: `config/web/proxy.local-compose.conf.js` → `127.0.0.1:18081` / `18080`
3. Script `scripts/web-start.ps1`:
   - faz backup de `../autua-web-frontend/.../environment.ts`
   - aplica o overlay
   - sobe `ng serve --host 127.0.0.1 --port 14200 --proxy-config <proxy do compose>`
   - restaura o tip ao encerrar (Ctrl+C / `web-stop.ps1`)

**Não** altera `angular.json` nem commits no WEB.  
**Não** muda profiles `sub` / `sub.local`.

## CORS BFF

No `.env` local, incluir origens do WEB:

```env
AUTUA_BFF_CORS_ALLOWED_ORIGINS=http://localhost:14200,http://127.0.0.1:14200
```

Reinício do BFF só quando alterar essa env (não feito automaticamente pelos scripts de seed).

## Alternativa (não preferida)

Override absoluto `http://127.0.0.1:18081/autua-bff` no overlay — exige CORS e não usa o proxy. O caminho relativo + proxy é o padrão documentado.
