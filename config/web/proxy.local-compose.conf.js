/**
 * Proxy host ng serve → stack autua-local-compose (portas do .env / defaults remapeados).
 * Não aponta para subcontratacao. Strip Origin evita CORS cruzado :14200 → BFF.
 *
 * Alvo padrão: BFF 18081 / API 18080 / auth-mock 18082 (sobrescrever via env se necessário).
 */
const bff = process.env.AUTUA_LOCAL_BFF_PROXY || 'http://127.0.0.1:18081';
const api = process.env.AUTUA_LOCAL_API_PROXY || 'http://127.0.0.1:18080';

const stripOrigin = (proxy) => {
  proxy.on('proxyReq', (proxyReq) => {
    proxyReq.removeHeader('origin');
  });
};

module.exports = {
  '/autua-bff': {
    target: bff,
    secure: false,
    changeOrigin: true,
    configure: stripOrigin,
  },
  '/autua-api': {
    target: api,
    secure: false,
    changeOrigin: true,
    configure: stripOrigin,
  },
};
