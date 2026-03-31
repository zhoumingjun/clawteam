"""Docker 栈（OpenClaw + Tuwunel + 卷）。"""

from __future__ import annotations

import pytest

from tests.util_docker import container_running, exec_ok


@pytest.mark.parametrize("svc", ["tuwunel", "openclaw"])
def test_container_running(svc: str) -> None:
    assert container_running(f"clawteam-{svc}"), f"容器 clawteam-{svc} 未运行"


def test_openclaw_reaches_homeserver() -> None:
    ok = exec_ok(
        "clawteam-openclaw",
        ["curl", "-sf", "http://tuwunel:8008/_matrix/client/versions"],
    )
    assert ok, "OpenClaw 容器内无法访问 Tuwunel"


def test_volume_dirs_exist(project_root) -> None:
    for rel in ("volumes/tuwunel-data", "volumes/openclaw"):
        p = project_root / rel
        assert p.is_dir(), f"缺少目录 {rel}（部署后应存在）"
