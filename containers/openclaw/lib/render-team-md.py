#!/usr/bin/env python3
"""Render TEAM.md from team.yaml.

Usage:
    python3 render-team-md.py /path/to/team.yaml [server_name] > TEAM.md

Reads team.yaml (agents + collaboration sections) and outputs a Markdown
file suitable for sharing across all agent workspaces.
"""
import os
import re
import sys


def parse_team_yaml(path):
    """Simple parser — no PyYAML dependency. Supports both 'collaboration:' and 'rules:' sections."""
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    agents = {}
    rules = {}
    section = None  # current top-level key
    current_key = None
    buf = []

    for line in lines:
        raw = line.rstrip()

        # Detect top-level keys (treat rules same as collaboration)
        top_match = re.match(r"^(agents|projects|collaboration|rules):", raw)
        if top_match:
            # flush previous key (only if buf has actual content)
            if current_key and buf:
                content = "\n".join(buf).strip()
                if content:
                    rules[current_key] = content
                buf = []
                current_key = None
            raw_key = top_match.group(1)
            # normalize rules -> collaboration (same semantics)
            section = "collaboration" if raw_key == "rules" else raw_key
            continue

        if section == "agents":
            m = re.match(r"^\s+-\s+name:\s*(.+)", raw)
            if m:
                name = m.group(1).strip()
                agents[name] = {"name": name}
                continue
            m = re.match(r"^\s+role:\s*(.+)", raw)
            if m and agents:
                list(agents.values())[-1]["role"] = m.group(1).strip()
                continue
            m = re.match(r"^\s+emoji:\s*(.+)", raw)
            if m and agents:
                list(agents.values())[-1]["emoji"] = m.group(1).strip()
                continue
            # next top-level key
            if raw and not raw[0].isspace():
                section = None

        elif section == "collaboration":
            # Skip blank lines (they don't belong to any key)
            if not raw.strip():
                continue
            # "  key: |" or "  key: value" (single-line)
            m = re.match(r"^\s{2}(\S[^:]*):\s*(.*)", raw)
            if m:
                # flush previous
                if current_key and buf:
                    rules[current_key] = "\n".join(buf).strip()
                    buf = []
                current_key = m.group(1).strip()
                rest = m.group(2).strip()
                if rest and rest != "|":
                    buf.append(rest)
                continue
            # Indented continuation lines (must be 4+ spaces after rules:)
            if raw.startswith("    ") and current_key:
                buf.append(raw.strip())
                continue
            # Next top-level key
            if raw and not raw[0].isspace():
                if current_key and buf:
                    rules[current_key] = "\n".join(buf).strip()
                    buf = []
                    current_key = None
                section = None

    # flush last key
    if current_key and buf:
        content = "\n".join(buf).strip()
        if content:
            rules[current_key] = content

    return list(agents.values()), rules


def render(agents, collaboration, server_name):
    lines = []
    lines.append("# Team — Claw Team 成员目录")
    lines.append("")
    lines.append("*此文件由 team.yaml 自动生成，请勿手动编辑。*")
    lines.append("")
    lines.append("## 成员")
    lines.append("")
    lines.append("| Agent | Matrix ID | 角色 |")
    lines.append("|-------|-----------|------|")
    lines.append(
        f"| human | `@human:{server_name}` | 人类用户——最终决策者 |"
    )
    for a in agents:
        name = a["name"]
        role = a.get("role", "")
        emoji = a.get("emoji", "")
        label = f"{emoji} {role}" if emoji else role
        lines.append(f"| {name} | `@{name}:{server_name}` | {label} |")
    lines.append("")

    if collaboration:
        for title, body in collaboration.items():
            lines.append(f"## {title}")
            lines.append("")
            lines.append(body)
            lines.append("")

    lines.append("## Matrix 规则")
    lines.append("")
    lines.append("- @ 人时**必须**用完整 MXID：`@localpart:" + server_name + "`")
    lines.append(
        "- 域名跟随 `MATRIX_SERVER_NAME` 环境变量（默认 `localhost`）"
    )
    lines.append("- 团队房配置 `requireMention: true`——完整 MXID 才能触发通知")
    lines.append("")
    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        print("Usage: render-team-md.py <team.yaml> [server_name]", file=sys.stderr)
        sys.exit(1)

    path = sys.argv[1]
    server_name = sys.argv[2] if len(sys.argv) > 2 else os.environ.get(
        "MATRIX_SERVER_NAME", "localhost"
    )

    agents, collaboration = parse_team_yaml(path)
    if not agents:
        print("ERROR: No agents found in " + path, file=sys.stderr)
        sys.exit(1)

    print(render(agents, collaboration, server_name))


if __name__ == "__main__":
    main()
