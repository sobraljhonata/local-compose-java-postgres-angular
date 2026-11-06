#!/usr/bin/env python3
"""OAuth2 state contract tests against the local identity mock.

Does not print tokens, codes, or secrets.
"""
from __future__ import annotations

import json
import os
import re
import urllib.error
import urllib.parse
import urllib.request
import uuid

BASE = os.environ.get("E2E_IDENTITY_BASE", "http://127.0.0.1:18082").rstrip("/")
BFF = os.environ.get("E2E_BFF_BASE", "http://127.0.0.1:18080/autua-bff").rstrip("/")
REDIRECT = "autua://callback"
UUID_RE = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


_OPENER = urllib.request.build_opener(_NoRedirect)


def _req(url: str, method: str = "GET", data: bytes | None = None, headers: dict | None = None, json_body=None):
    hdrs = dict(headers or {})
    body = data
    if json_body is not None:
        body = json.dumps(json_body).encode("utf-8")
        hdrs.setdefault("Content-Type", "application/json")
    request = urllib.request.Request(url, data=body, headers=hdrs, method=method)
    try:
        with _OPENER.open(request, timeout=8) as resp:
            raw = resp.read()
            return resp.status, raw, dict(resp.headers)
    except urllib.error.HTTPError as err:
        return err.code, err.read(), dict(err.headers)


def _status_only(url: str, method="GET", data=None, headers=None, json_body=None):
    status, raw, _ = _req(url, method=method, data=data, headers=headers, json_body=json_body)
    return status, raw


def _extract_state(url: str) -> str:
    parsed = urllib.parse.urlparse(url)
    return urllib.parse.parse_qs(parsed.query).get("state", [""])[0]


def _login_and_location(state: str, user: str = "e2e-ok") -> tuple[int, str]:
    body = urllib.parse.urlencode(
        {"user": user, "redirect_uri": REDIRECT, "state": state}
    ).encode("utf-8")
    status, _, headers = _req(
        f"{BASE}/login",
        method="POST",
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    loc = headers.get("Location") or headers.get("location") or ""
    return status, loc


def test_a_state_valido_preservado():
    status, raw, _ = _req(f"{BFF}/auth/login/authorize-url?redirect_uri={urllib.parse.quote(REDIRECT)}")
    assert status == 200, status
    url = json.loads(raw)["url"]
    state = _extract_state(url)
    assert UUID_RE.match(state), "authorize-url state must be UUID"
    html_status, html = _status_only(url)
    assert html_status == 200, html_status
    assert state.encode() in html, "login HTML must preserve authorize-url state"
    code_status, loc = _login_and_location(state)
    assert code_status in (301, 302, 303, 307, 308), code_status
    assert _extract_state(loc) == state, "callback must echo the same state"


def test_b_state_ausente_rejeitado():
    status, _ = _status_only(f"{BASE}/login?redirect_uri={urllib.parse.quote(REDIRECT)}")
    assert status == 400, status
    post_status, loc = _login_and_location("")
    assert post_status == 400, post_status
    assert not loc
    bff_status, raw = _status_only(
        f"{BFF}/auth/login/token-from-callback",
        method="POST",
        json_body={
            "redirect_uri": REDIRECT,
            "callback_url": f"{REDIRECT}?code={uuid.uuid4()}",
        },
    )
    assert bff_status == 400, bff_status
    assert b"state" in raw.lower()


def test_c_state_adulterado_rejeitado():
    status, raw, _ = _req(f"{BFF}/auth/login/authorize-url?redirect_uri={urllib.parse.quote(REDIRECT)}")
    assert status == 200, status
    url = json.loads(raw)["url"]
    state = _extract_state(url)
    _, loc = _login_and_location(state)
    tampered = loc.replace(state, "not-a-uuid")
    bff_status, raw = _status_only(
        f"{BFF}/auth/login/token-from-callback",
        method="POST",
        json_body={
            "redirect_uri": REDIRECT,
            "callback_url": tampered,
        },
    )
    assert bff_status == 400, bff_status
    assert b"state inv" in raw.lower() or b"inv" in raw.lower()


def test_d_e_f_single_use_and_independent_attempts():
    s1_status, raw1, _ = _req(f"{BFF}/auth/login/authorize-url?redirect_uri={urllib.parse.quote(REDIRECT)}")
    s2_status, raw2, _ = _req(f"{BFF}/auth/login/authorize-url?redirect_uri={urllib.parse.quote(REDIRECT)}")
    assert s1_status == 200 and s2_status == 200
    state1 = _extract_state(json.loads(raw1)["url"])
    state2 = _extract_state(json.loads(raw2)["url"])
    assert state1 != state2, "two login attempts must not share state"
    assert UUID_RE.match(state1) and UUID_RE.match(state2)

    _, loc1 = _login_and_location(state1)
    _, loc2 = _login_and_location(state2)
    assert _extract_state(loc1) == state1
    assert _extract_state(loc2) == state2

    first, raw_ok = _status_only(
        f"{BFF}/auth/login/token-from-callback",
        method="POST",
        json_body={
            "redirect_uri": REDIRECT,
            "callback_url": loc1,
        },
    )
    assert first == 200, first
    assert b"access_token" in raw_ok

    replay, _ = _status_only(
        f"{BFF}/auth/login/token-from-callback",
        method="POST",
        json_body={
            "redirect_uri": REDIRECT,
            "callback_url": loc1,
        },
    )
    assert replay in (400, 422, 502), replay

    second, raw2tok = _status_only(
        f"{BFF}/auth/login/token-from-callback",
        method="POST",
        json_body={
            "redirect_uri": REDIRECT,
            "callback_url": loc2,
        },
    )
    assert second == 200, second
    assert b"access_token" in raw2tok


def main() -> int:
    tests = [
        test_a_state_valido_preservado,
        test_b_state_ausente_rejeitado,
        test_c_state_adulterado_rejeitado,
        test_d_e_f_single_use_and_independent_attempts,
    ]
    failed = 0
    for fn in tests:
        try:
            fn()
            print(f"APROVADO {fn.__name__}")
        except Exception as exc:
            failed += 1
            print(f"REPROVADO {fn.__name__} :: {type(exc).__name__}")
    if failed:
        raise SystemExit(failed)
    print("AUTH FLOW SMOKE OK")
    return 0


if __name__ == "__main__":
    main()
