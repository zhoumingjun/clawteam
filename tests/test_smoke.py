"""烟雾级自检（原 tests/smoke/run.sh）。"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

import httpx
import pytest


@pytest.mark.smoke
def test_docker_cli_available() -> None:
    r = subprocess.run(
        ["docker", "version"],
        capture_output=True,
        timeout=45,
        check=False,
    )
    assert r.returncode == 0, (r.stderr or r.stdout or b"").decode(errors="replace")


@pytest.mark.smoke
def test_docker_compose_cli_available() -> None:
    r = subprocess.run(
        ["docker", "compose", "version"],
        capture_output=True,
        timeout=30,
        check=False,
    )
    assert r.returncode == 0


@pytest.mark.smoke
def test_compose_at_least_one_service_up(project_root: Path) -> None:
    assert (project_root / ".env").is_file(), "缺少 .env"
    r = subprocess.run(
        [
            "docker",
            "compose",
            "-f",
            "containers/docker-compose.yml",
            "--env-file",
            ".env",
            "ps",
            "--format",
            "{{.Status}}",
        ],
        cwd=project_root,
        capture_output=True,
        text=True,
        timeout=90,
        check=False,
    )
    assert r.returncode == 0, r.stderr
    lines = [ln.strip() for ln in r.stdout.splitlines() if ln.strip()]
    assert any(ln.startswith("Up") for ln in lines), f"无运行中服务: {r.stdout!r}"


@pytest.mark.smoke
def test_matrix_http_versions(matrix_server: str) -> None:
    r = httpx.get(f"{matrix_server}/_matrix/client/versions", timeout=15.0)
    r.raise_for_status()
    assert "versions" in r.json()


@pytest.mark.smoke
def test_tuwunel_container_running() -> None:
    r = subprocess.run(
        ["docker", "ps", "--format", "{{.Names}}\t{{.Status}}"],
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )
    assert r.returncode == 0
    for line in r.stdout.splitlines():
        if line.startswith("clawteam-tuwunel\t"):
            assert "Up" in line
            return
    pytest.fail("未找到运行中的 clawteam-tuwunel 容器")


@pytest.mark.smoke
def test_compose_project_network_exists() -> None:
    proj = os.environ.get("COMPOSE_PROJECT_NAME", "clawteam")
    net = f"{proj}_clawteam-network"
    r = subprocess.run(
        ["docker", "network", "inspect", net],
        capture_output=True,
        timeout=30,
        check=False,
    )
    assert r.returncode == 0, f"网络 {net} 不存在（检查 COMPOSE_PROJECT_NAME 与 compose 网络名）"
