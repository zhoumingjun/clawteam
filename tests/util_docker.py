"""Docker CLI helpers."""

from __future__ import annotations

import subprocess


def container_running(name: str) -> bool:
    try:
        out = subprocess.run(
            ["docker", "inspect", "-f", "{{.State.Running}}", name],
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
        return out.returncode == 0 and out.stdout.strip() == "true"
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def exec_ok(container: str, argv: list[str]) -> bool:
    try:
        r = subprocess.run(
            ["docker", "exec", container, *argv],
            capture_output=True,
            timeout=30,
            check=False,
        )
        return r.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False
