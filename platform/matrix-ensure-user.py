#!/usr/bin/env python3
"""Register (UIAA + registration_token) or password-login a Matrix user; print access_token or nothing."""
import json
import sys
import urllib.error
import urllib.request
from typing import Any


def request_json(
    method: str, url: str, body: dict[str, Any] | None = None, headers: dict[str, str] | None = None
) -> tuple[int, Any]:
    data = None
    h = {"Content-Type": "application/json"}
    if headers:
        h.update(headers)
    if body is not None:
        data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=h, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode("utf-8")
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8")
        try:
            parsed = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            parsed = {"err": raw[:500]}
        return e.code, parsed


def login(base: str, user: str, password: str) -> str | None:
    url = f"{base.rstrip('/')}/_matrix/client/v3/login"
    _, data = request_json(
        "POST",
        url,
        {
            "type": "m.login.password",
            "identifier": {"type": "m.id.user", "user": user},
            "password": password,
        },
    )
    tok = data.get("access_token")
    return tok if isinstance(tok, str) else None


def register_with_token(base: str, user: str, password: str, token: str) -> str | None:
    url = f"{base.rstrip('/')}/_matrix/client/v3/register"
    sess: str | None = None
    for auth in ({"type": "m.login.dummy"}, None):
        body: dict[str, object] = {
            "username": user,
            "password": password,
            "initial_device_display_name": "clawteam",
            "inhibit_login": False,
        }
        if auth is not None:
            body["auth"] = auth
        code, first = request_json("POST", url, body)
        if code == 200 and isinstance(first.get("access_token"), str):
            return first["access_token"]
        if code in (401, 403) and first.get("session"):
            s = first.get("session")
            if isinstance(s, str):
                sess = s
            break
    if not sess:
        return None
    code2, second = request_json(
        "POST",
        url,
        {
            "username": user,
            "password": password,
            "initial_device_display_name": "clawteam",
            "inhibit_login": False,
            "auth": {"type": "m.login.registration_token", "token": token, "session": sess},
        },
    )
    if code2 == 200 and isinstance(second.get("access_token"), str):
        return second["access_token"]
    return None


def main() -> int:
    if len(sys.argv) != 5:
        print("usage: matrix-ensure-user.py BASE_URL USER PASS REGISTRATION_TOKEN", file=sys.stderr)
        return 2
    base, user, password, reg_token = sys.argv[1:5]
    tok = login(base, user, password)
    if tok:
        print(tok)
        return 0
    tok = register_with_token(base, user, password, reg_token)
    if tok:
        print(tok)
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
