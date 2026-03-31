"""Matrix Client-Server：注册/登录、建房间、发消息。"""

from __future__ import annotations

import time

import httpx
import pytest

E2E_USER = "e2e_test_user"
E2E_PASSWORD = "e2e_test_password"


@pytest.fixture
def e2e_access_token(matrix_server: str) -> str:
    client = httpx.Client(timeout=30.0)
    reg = client.post(
        f"{matrix_server}/_matrix/client/r0/register",
        json={
            "auth": {"type": "m.login.dummy"},
            "username": E2E_USER,
            "password": E2E_PASSWORD,
        },
    )
    if reg.status_code == 200 and reg.json().get("access_token"):
        return reg.json()["access_token"]
    body = (reg.text or "").lower()
    if reg.status_code != 200 or "user_in_use" in body or "m_user_in_use" in body:
        login = client.post(
            f"{matrix_server}/_matrix/client/v3/login",
            json={
                "type": "m.login.password",
                "identifier": {"type": "m.id.user", "user": E2E_USER},
                "password": E2E_PASSWORD,
            },
        )
        login.raise_for_status()
        tok = login.json().get("access_token")
        assert tok, login.text
        return tok
    pytest.fail(f"register failed: {reg.status_code} {reg.text}")


def test_create_room_and_send_message(matrix_server: str, e2e_access_token: str) -> None:
    headers = {"Authorization": f"Bearer {e2e_access_token}"}
    with httpx.Client(timeout=30.0, headers=headers) as client:
        cr = client.post(
            f"{matrix_server}/_matrix/client/r0/createRoom",
            json={"name": "pytest integration room", "topic": "clawteam"},
        )
        cr.raise_for_status()
        room_id = cr.json().get("room_id")
        assert room_id

        tx = str(int(time.time()))
        send = client.put(
            f"{matrix_server}/_matrix/client/r0/rooms/{room_id}/send/m.room.message/m{tx}",
            json={"msgtype": "m.text", "body": "pytest Matrix message"},
        )
        send.raise_for_status()
        assert send.json().get("event_id")
