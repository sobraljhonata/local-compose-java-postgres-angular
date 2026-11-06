#!/usr/bin/env python3
"""AUTUA local-compose identity mock (OIDC/Gelus/auth-login). LOCAL ONLY — not for shared envs.

Not a generic IdP. Covers only the AUTUA E2E contracts:
- OIDC discovery / JWKS / token (RS256)
- GET /auth/login/authorize-url  POST /auth/login/token
- UMA ticket (client_credentials + uma-ticket)
- GET /api/v1/usuarios/orgaos/{orgaoId}/cpf/{cpf}/vinculo
"""
from __future__ import annotations

import json
import os
import re
import time
import uuid
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
import jwt
from jwt.algorithms import RSAAlgorithm

ISSUER = os.environ.get("LOCAL_ISSUER", "http://auth-mock:8080/realms/autua-local")
PUBLIC_BASE = os.environ.get("LOCAL_PUBLIC_BASE", "http://127.0.0.1:18082").rstrip("/")
LISTEN_PORT = int(os.environ.get("PORT", "8080"))
AZP = os.environ.get("LOCAL_AZP", "10197_radar")
CLIENT_ID = os.environ.get("LOCAL_CLIENT_ID", "autua-local")
CLIENT_SECRET = os.environ.get("LOCAL_CLIENT_SECRET", "autua-local-secret")
ORGAO_CNPJ = os.environ.get("LOCAL_ORGAO_CNPJ", "00000000000191")
ORGAO_ID = int(os.environ.get("LOCAL_ORGAO_ID", "9001"))
UNIDADE_ID = int(os.environ.get("LOCAL_UNIDADE_ID", "9001"))

# Gelus Autentikus: p~RECURSO~OPERACAO → API JwtAuthenticationConverter
# ("OPERACAO RECURSO"). GET IMEI exige DISPOSITIVO:CONSULTAR; login-app
# exige DISPOSITIVO_MOBILE:LOGIN; sinc-dados exige DISPOSITIVO:SINCRONIZAR;
# GET motivos-medida-administrativa exige MEDIDA_ADMINISTRATIVA:CONSULTAR.
# Não é bypass: cada user permanece distinto.
SCOPE_LOGIN = "p~DISPOSITIVO_MOBILE~LOGIN"
SCOPE_CONSULTAR = "p~DISPOSITIVO~CONSULTAR"
SCOPE_CADASTRAR = "p~DISPOSITIVO~CADASTRAR"
SCOPE_ATIVAR = "p~DISPOSITIVO~ATIVAR_DESATIVAR"
SCOPE_AUTORIZAR = "p~DISPOSITIVO~AUTORIZAR"
SCOPE_SINCRONIZAR = "p~DISPOSITIVO~SINCRONIZAR"
SCOPE_MEDIDA_CONSULTAR = "p~MEDIDA_ADMINISTRATIVA~CONSULTAR"
# Enrollment / QR Pré-Cadastro (API: DISPOSITIVO_INSTITUCIONAL:CADASTRAR_LOTE).
# Necessário no ensaio RC1 — criação de enrollment NÃO usa o bypass Autentikus da gestão.
SCOPE_DI_CADASTRAR_LOTE = "p~DISPOSITIVO_INSTITUCIONAL~CADASTRAR_LOTE"
SCOPE_DI_CONSULTAR = "p~DISPOSITIVO_INSTITUCIONAL~CONSULTAR"
SCOPE_DI_ATIVAR = "p~DISPOSITIVO_INSTITUCIONAL~ATIVAR_DESATIVAR"

# Roles OAuth (resource_access[azp].roles) — alinhado a
# autua-api PapeisClienteOAuth.GESTOR_DISPOSITIVOS ("Gestor de Dispositivos").
# local-ok: gestor E2E local. local-403: autenticado sem papel gestor (nega Gestão).
ROLE_AGENTE = "Agente de Fiscalização"
ROLE_GESTOR_DISPOSITIVOS = "Gestor de Dispositivos"

USERS = {
    "local-ok": {
        "cpf": "39053344705",
        "name": "Agente Local Autorizado",
        "roles": [ROLE_GESTOR_DISPOSITIVOS, ROLE_AGENTE],
        "scopes": [
            SCOPE_LOGIN,
            SCOPE_CONSULTAR,
            SCOPE_CADASTRAR,
            SCOPE_ATIVAR,
            SCOPE_AUTORIZAR,
            SCOPE_SINCRONIZAR,
            SCOPE_MEDIDA_CONSULTAR,
            SCOPE_DI_CADASTRAR_LOTE,
            SCOPE_DI_CONSULTAR,
            SCOPE_DI_ATIVAR,
        ],
    },
    "local-403": {
        "cpf": "52998224725",
        "name": "Agente Local Sem Permissao",
        "roles": [ROLE_AGENTE],
        "scopes": [SCOPE_CONSULTAR],
    },
    "local-missing": {
        "cpf": "11144477735",
        "name": "Agente Local Inexistente",
        "roles": [ROLE_AGENTE],
        "scopes": [SCOPE_LOGIN],
    },
}
USERS_BY_CPF = {u["cpf"]: {**u, "key": k} for k, u in USERS.items()}

CODES: dict[str, dict] = {}
# Contrato BFF AuthLoginCallbackParser: state UUID (gov.br/Autentikus).
UUID_STATE = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)


def new_oauth_state() -> str:
    return str(uuid.uuid4())


def new_oauth_code() -> str:
    return str(uuid.uuid4())


def is_valid_oauth_state(value: str | None) -> bool:
    return bool(value) and UUID_STATE.match(value.strip()) is not None


KEY_DIR = Path(os.environ.get("LOCAL_KEY_DIR", "/var/lib/autua-local-keys"))


def load_or_create_key():
    KEY_DIR.mkdir(parents=True, exist_ok=True)
    priv_path = KEY_DIR / "rsa.pem"
    if priv_path.exists():
        private = serialization.load_pem_private_key(priv_path.read_bytes(), password=None)
    else:
        private = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        priv_path.write_bytes(
            private.private_bytes(
                serialization.Encoding.PEM,
                serialization.PrivateFormat.PKCS8,
                serialization.NoEncryption(),
            )
        )
        priv_path.chmod(0o600)
    public = private.public_key()
    jwk = json.loads(RSAAlgorithm.to_jwk(public))
    jwk["kid"] = "autua-local-1"
    jwk["use"] = "sig"
    jwk["alg"] = "RS256"
    return private, jwk


PRIVATE_KEY, JWK = load_or_create_key()


def sign_user_token(user: dict, extra_scopes: list[str] | None = None) -> str:
    scopes = extra_scopes if extra_scopes is not None else user["scopes"]
    now = int(time.time())
    payload = {
        "iss": ISSUER,
        "sub": user["cpf"],
        "azp": AZP,
        "aud": AZP,
        "name": user["cpf"],
        "preferred_username": user["cpf"],
        "cpf": user["cpf"],
        "orgao": ORGAO_CNPJ,
        "resource_access": {AZP: {"roles": list(user.get("roles") or [ROLE_AGENTE])}},
        "authorization": {
            "permissions": [{"rsname": "padrao", "scopes": scopes}],
        },
        "iat": now,
        "exp": now + 3600,
        "typ": "Bearer",
    }
    return jwt.encode(payload, PRIVATE_KEY, algorithm="RS256", headers={"kid": "autua-local-1"})


def sign_service_token() -> str:
    now = int(time.time())
    payload = {
        "iss": ISSUER,
        "sub": CLIENT_ID,
        "azp": AZP,
        "aud": AZP,
        "name": CLIENT_ID,
        "resource_access": {AZP: {"roles": ["service"]}},
        "iat": now,
        "exp": now + 300,
        "typ": "Bearer",
    }
    return jwt.encode(payload, PRIVATE_KEY, algorithm="RS256", headers={"kid": "autua-local-1"})


def read_body(handler: BaseHTTPRequestHandler) -> bytes:
    length = int(handler.headers.get("Content-Length") or 0)
    return handler.rfile.read(length) if length else b""


def parse_qs_bytes(raw: bytes) -> dict[str, str]:
    parsed = urllib.parse.parse_qs(raw.decode("utf-8"), keep_blank_values=True)
    return {k: v[0] if v else "" for k, v in parsed.items()}


def send_json(handler: BaseHTTPRequestHandler, status: int, body: dict):
    data = json.dumps(body).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json")
    handler.send_header("Content-Length", str(len(data)))
    handler.send_header("Access-Control-Allow-Origin", "*")
    handler.end_headers()
    handler.wfile.write(data)


def send_html(handler: BaseHTTPRequestHandler, status: int, html: str):
    data = html.encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "text/html; charset=utf-8")
    handler.send_header("Content-Length", str(len(data)))
    handler.end_headers()
    handler.wfile.write(data)


LOGIN_PAGE = """<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8"><title>AUTUA E2E login</title>
<style>body{font-family:sans-serif;margin:2rem}button{display:block;margin:.5rem 0;padding:.6rem 1rem}</style>
</head><body>
<h1>Identidade local E2E</h1>
<p>Usuarios sinteticos. Sem CPF real, senha corporativa ou gov.br.</p>
<form method="post" action="/login">
  <input type="hidden" name="redirect_uri" value="{redirect_uri}">
  <input type="hidden" name="state" value="{state}">
  <button name="user" value="local-ok">Entrar como agente autorizado</button>
  <button name="user" value="local-403">Entrar sem DISPOSITIVO_MOBILE:LOGIN</button>
  <button name="user" value="local-missing">Entrar como agente inexistente no banco</button>
</form>
</body></html>
"""


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys_stderr = __import__("sys").stderr
        sys_stderr.write("[identity] " + (fmt % args) + "\n")

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        q = urllib.parse.parse_qs(parsed.query)

        if path in (
            "/health",
            "/realms/autua-local/health",
        ):
            send_json(self, 200, {"status": "UP", "issuer": ISSUER})
            return

        if path.endswith("/.well-known/openid-configuration"):
            send_json(
                self,
                200,
                {
                    "issuer": ISSUER,
                    "authorization_endpoint": f"{ISSUER}/protocol/openid-connect/auth",
                    "token_endpoint": f"{ISSUER}/protocol/openid-connect/token",
                    "jwks_uri": f"{ISSUER}/protocol/openid-connect/certs",
                    "userinfo_endpoint": f"{ISSUER}/protocol/openid-connect/userinfo",
                    "end_session_endpoint": f"{ISSUER}/protocol/openid-connect/logout",
                    "grant_types_supported": [
                        "authorization_code",
                        "client_credentials",
                        "urn:ietf:params:oauth:grant-type:uma-ticket",
                    ],
                    "response_types_supported": ["code", "token", "id_token"],
                    "subject_types_supported": ["public"],
                    "id_token_signing_alg_values_supported": ["RS256"],
                    "token_endpoint_auth_methods_supported": [
                        "client_secret_post",
                        "client_secret_basic",
                    ],
                    "scopes_supported": ["openid", "profile"],
                    "claims_supported": ["sub", "iss", "name", "azp", "orgao"],
                },
            )
            return

        if path.endswith("/protocol/openid-connect/certs"):
            send_json(self, 200, {"keys": [JWK]})
            return

        if path in ("/auth/login/authorize-url", "/authorize-url"):
            redirect_uri = (q.get("redirect_uri") or [""])[0]
            state = new_oauth_state()
            login = (
                f"{PUBLIC_BASE}/login?"
                f"redirect_uri={urllib.parse.quote(redirect_uri, safe='')}&state={state}"
            )
            send_json(self, 200, {"url": login})
            return

        if path == "/e2e/token":
            user_key = (q.get("user") or ["local-ok"])[0]
            user = USERS.get(user_key)
            if not user:
                send_json(self, 400, {"error": "unknown_user"})
                return
            token = sign_user_token(user)
            send_json(
                self,
                200,
                {
                    "access_token": token,
                    "token_type": "Bearer",
                    "expires_in": 3600,
                    "user": user_key,
                    "cpf": user["cpf"],
                },
            )
            return

        if path == "/login":
            redirect_uri = (q.get("redirect_uri") or [""])[0]
            state = (q.get("state") or [""])[0]
            if not is_valid_oauth_state(state):
                send_json(self, 400, {"error": "invalid_request", "error_description": "state inválido"})
                return
            send_html(
                self,
                200,
                LOGIN_PAGE.replace("{redirect_uri}", html_escape(redirect_uri)).replace(
                    "{state}", html_escape(state)
                ),
            )
            return

        if path.startswith("/api/v1/usuarios/orgaos/") and path.endswith("/vinculo"):
            self.handle_vinculo(path)
            return

        send_json(self, 404, {"error": "not_found", "path": path})

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        body = parse_qs_bytes(read_body(self))
        q = urllib.parse.parse_qs(parsed.query)
        merged = {**{k: v[0] for k, v in q.items()}, **body}

        if path in (
            "/auth/login/token",
            "/token",
            "/realms/autua-local/protocol/openid-connect/token",
            "/protocol/openid-connect/token",
        ):
            self.handle_token(merged)
            return

        if path == "/login":
            user_key = body.get("user", "")
            redirect_uri = body.get("redirect_uri", "")
            state = body.get("state", "")
            user = USERS.get(user_key)
            if not user or not redirect_uri:
                send_json(self, 400, {"error": "invalid_request"})
                return
            if not is_valid_oauth_state(state):
                send_json(self, 400, {"error": "invalid_request", "error_description": "state inválido"})
                return
            code = new_oauth_code()
            CODES[code] = {"user": user_key, "redirect_uri": redirect_uri, "state": state}
            sep = "&" if "?" in redirect_uri else "?"
            loc = f"{redirect_uri}{sep}code={urllib.parse.quote(code)}&state={urllib.parse.quote(state)}&iss={urllib.parse.quote(ISSUER)}"
            self.send_response(302)
            self.send_header("Location", loc)
            self.end_headers()
            return

        send_json(self, 404, {"error": "not_found", "path": path})

    def handle_token(self, params: dict[str, str]):
        grant = params.get("grant_type", "")
        if grant == "client_credentials":
            if not valid_client(params, self.headers.get("Authorization")):
                send_json(self, 401, {"error": "invalid_client", "error_description": "Invalid client or Invalid client credentials"})
                return
            token = sign_service_token()
            send_json(
                self,
                200,
                {
                    "access_token": token,
                    "token_type": "Bearer",
                    "expires_in": 300,
                    "scope": "openid",
                },
            )
            return

        if grant == "urn:ietf:params:oauth:grant-type:uma-ticket":
            auth = self.headers.get("Authorization") or ""
            if not auth.lower().startswith("bearer "):
                send_json(self, 401, {"error": "invalid_grant"})
                return
            user_jwt = auth.split(" ", 1)[1].strip()
            try:
                claims = jwt.decode(user_jwt, PRIVATE_KEY.public_key(), algorithms=["RS256"], issuer=ISSUER, options={"verify_aud": False})
            except Exception:
                send_json(self, 401, {"error": "invalid_token"})
                return
            cpf = claims.get("name") or claims.get("cpf")
            user = USERS_BY_CPF.get(cpf)
            if not user:
                send_json(self, 403, {"error": "access_denied"})
                return
            token = sign_user_token(user)
            send_json(self, 200, {"access_token": token, "token_type": "Bearer", "expires_in": 3600})
            return

        # authorization_code (Autentikus /token)
        code = params.get("code", "")
        state = params.get("state", "")
        rec = CODES.pop(code, None)
        if not rec or rec.get("state") != state:
            send_json(self, 400, {"error": "invalid_grant"})
            return
        user = USERS[rec["user"]]
        access = sign_user_token(user)
        send_json(
            self,
            200,
            {
                "access_token": access,
                "refresh_token": access,
                "id_token": access,
                "token_type": "Bearer",
                "expires_in": 3600,
                "scope": "openid profile",
            },
        )

    def handle_vinculo(self, path: str):
        # /api/v1/usuarios/orgaos/{orgaoId}/cpf/{cpf}/vinculo
        parts = path.strip("/").split("/")
        try:
            orgao_id = int(parts[4])
            cpf = parts[6]
        except (IndexError, ValueError):
            send_json(self, 400, {"error": "invalid_path"})
            return
        user = USERS_BY_CPF.get(cpf)
        if not user or user["key"] == "local-missing":
            send_json(self, 404, {"error": "not_found"})
            return
        send_json(
            self,
            200,
            {
                "id": 1,
                "cpf": cpf,
                "orgaoId": orgao_id,
                "unidadeAutuadoraId": UNIDADE_ID,
            },
        )


def valid_client(params: dict[str, str], authorization: str | None) -> bool:
    cid = params.get("client_id")
    secret = params.get("client_secret")
    if authorization and authorization.lower().startswith("basic "):
        import base64

        try:
            decoded = base64.b64decode(authorization.split(" ", 1)[1]).decode("utf-8")
            cid, secret = decoded.split(":", 1)
        except Exception:
            return False
    return cid == CLIENT_ID and secret == CLIENT_SECRET


def html_escape(value: str) -> str:
    return (
        value.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


if __name__ == "__main__":
    httpd = ThreadingHTTPServer(("0.0.0.0", LISTEN_PORT), Handler)
    print(f"autua-local identity listening on {LISTEN_PORT} issuer={ISSUER}", flush=True)
    httpd.serve_forever()
