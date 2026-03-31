"""仓库与编排文件。"""

from __future__ import annotations

import subprocess
from pathlib import Path

import yaml


def test_agent_workspace_files(project_root: Path) -> None:
    agents = ("manager", "arch", "dev", "qa", "sre", "research")
    for agent in agents:
        base = project_root / "config" / "agents" / agent
        for name in ("SOUL.md", "AGENTS.md", "HEARTBEAT.md"):
            assert (base / name).is_file(), f"missing {agent}/{name}"


def test_git_history(project_root: Path) -> None:
    r = subprocess.run(
        ["git", "rev-list", "--count", "HEAD"],
        cwd=project_root,
        capture_output=True,
        text=True,
        check=False,
    )
    assert r.returncode == 0
    assert int(r.stdout.strip()) > 0


def test_docs_has_markdown(project_root: Path) -> None:
    doc = project_root / "docs"
    assert doc.is_dir()
    assert list(doc.rglob("*.md"))


def test_compose_makefile_env_example(project_root: Path) -> None:
    assert (project_root / "containers" / "docker-compose.yml").is_file()
    assert (project_root / "Makefile").is_file()
    assert (project_root / ".env.example").is_file()
    text = (project_root / "containers" / "docker-compose.yml").read_text(encoding="utf-8")
    data = yaml.safe_load(text)
    assert isinstance(data, dict) and "services" in data
    assert len(data["services"]) >= 1
