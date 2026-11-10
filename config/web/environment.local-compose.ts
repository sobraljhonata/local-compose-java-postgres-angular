/**
 * Overlay LOCAL COMPOSE — NÃO versionar em autua-web-frontend.
 * Aplicado em runtime por scripts/web-start.ps1 (backup + restore do environment.ts tip).
 *
 * BASE_URL_BFF relativo: o proxy Angular (proxy.local-compose.conf.js) encaminha
 * /autua-bff → 127.0.0.1:${BFF_HOST_PORT} (padrão documentado 18081).
 */
export const environment = {
  production: false,
  deployTarget: 'local' as const,
  API_URL_CORE_REST: '/autua-api',
  API_URL_REPORT: 'https://val-radarv2.np.estaleiro.serpro.gov.br/report',
  API_URL: '/autua-api',
  FRONTEND_URL: 'http://127.0.0.1:14200',
  ROLE_URL: 'https://val-radarv2.np.estaleiro.serpro.gov.br/core-rest/gip-rest/usuario/perfis',
  BASE_URL_BFF: '/autua-bff',
};
