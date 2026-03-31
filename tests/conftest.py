"""项目根、环境、Matrix URL、测试报告。"""

from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path

import pytest
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parents[1]
load_dotenv(PROJECT_ROOT / ".env")


@pytest.fixture(scope="session")
def project_root() -> Path:
    return PROJECT_ROOT


@pytest.fixture(scope="session")
def matrix_server() -> str:
    base = os.environ.get("SYNAPSE_SERVER")
    if base:
        return base.rstrip("/")
    port = os.environ.get("SYNAPSE_PORT", "8008")
    return f"http://127.0.0.1:{port}"


def pytest_sessionfinish(session: pytest.Session, exitstatus: int) -> None:
    latest = PROJECT_ROOT / "outputs" / "latest"
    latest.mkdir(parents=True, exist_ok=True)
    tr = session.config.pluginmanager.get_plugin("terminalreporter")
    passed = len(tr.stats.get("passed", [])) if tr else 0
    failed = len(tr.stats.get("failed", [])) if tr else 0
    total = passed + failed
    pct = (100.0 * passed / total) if total else 0.0
    lines = [
        "# Claw Team 测试报告（pytest）",
        "",
        f"**时间**: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%SZ')}",
        f"**退出码**: {exitstatus}",
        "",
        "| 指标 | 数值 |",
        "|------|------|",
        f"| 通过 | {passed} |",
        f"| 失败 | {failed} |",
        f"| 合计 | {total} |",
        f"| 通过率 | {pct:.1f}% |",
        "",
    ]
    (latest / "test-report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    # 兼容旧路径
    (latest / "e2e-report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
