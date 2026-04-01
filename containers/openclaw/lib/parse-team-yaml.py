#!/usr/bin/env python3
"""Parse team.yaml and output shell variables.

Usage:
    python3 parse-team-yaml.py /path/to/team.yaml

Output (eval-able shell variables):
    AGENTS="manager product arch dev qa sre research"
    OC_ROLES='["manager","product","arch","dev","qa","sre","research"]'
"""
import json
import re
import sys


def parse_team_yaml(path):
    """Simple parser for team.yaml — no PyYAML dependency."""
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    agents = []
    in_agents = False
    for line in lines:
        stripped = line.rstrip()
        # Detect top-level keys
        if re.match(r"^(agents|projects|collaboration):", stripped):
            in_agents = stripped.startswith("agents:")
            continue
        if in_agents:
            # Match "  - name: xxx"
            m = re.match(r"^\s+-\s+name:\s*(.+)", stripped)
            if m:
                agents.append(m.group(1).strip())
            # Stop at next top-level key or non-indented line
            elif stripped and not stripped[0].isspace():
                in_agents = False

    return agents


def main():
    if len(sys.argv) < 2:
        print("Usage: parse-team-yaml.py <team.yaml>", file=sys.stderr)
        sys.exit(1)

    path = sys.argv[1]
    agents = parse_team_yaml(path)

    if not agents:
        print("ERROR: No agents found in " + path, file=sys.stderr)
        sys.exit(1)

    print('AGENTS="' + " ".join(agents) + '"')
    print("OC_ROLES='" + json.dumps(agents) + "'")


if __name__ == "__main__":
    main()
