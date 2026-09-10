#!/usr/bin/env python3
"""SessionStart hook: tell the model, deterministically, when the current
working directory is a project managed by ~/dotfiles/projects.yml.

Unlike enforce-session-start.js (which prints a human-facing banner to
stderr), this emits `hookSpecificOutput.additionalContext` on stdout, which
Claude Code injects into the session context. So every session that starts
inside a registered project *knows* it is managed -- its declared ports, its
always_on / start_command status, and that a local dashboard monitors and can
start/restart it -- without relying on the model choosing to read projects.yml.

Prints nothing (empty output) for unregistered directories, so unmanaged
sessions aren't polluted. Never blocks session start: any error -> exit 0.
"""

import json
import os
import sys
from pathlib import Path

DASHBOARD_URL = "http://localhost:9797"


def read_cwd():
    """Prefer the cwd Claude Code passes on stdin; fall back to os.getcwd()."""
    cwd = None
    try:
        raw = sys.stdin.read()
        if raw.strip():
            cwd = (json.loads(raw) or {}).get("cwd")
    except Exception:
        pass
    return cwd or os.getcwd()


def find_project(projects, cwd):
    """Return (name, cfg) whose `path` equals cwd or contains it, else None."""
    resolved = Path(cwd).resolve()
    best = None
    for name, cfg in (projects or {}).items():
        cfg = cfg or {}
        p = cfg.get("path")
        if not p:
            continue
        proj = Path(os.path.expanduser(str(p))).resolve()
        if resolved == proj or proj in resolved.parents:
            # Deepest matching path wins (a subproject beats its parent).
            if best is None or len(str(proj)) > len(str(best[2])):
                best = (name, cfg, proj)
    return (best[0], best[1]) if best else None


def build_context(name, cfg):
    ports = cfg.get("ports", []) or []
    always_on = bool(cfg.get("always_on", False))
    start_command = str(cfg.get("start_command", "") or "").strip()
    databases = cfg.get("databases", []) or []

    lines = [
        f"[Managed project: {name}]",
        "This working directory is registered in ~/dotfiles/projects.yml, the "
        "single source of truth for local projects on this machine, and is "
        f"monitored by a local dashboard at {DASHBOARD_URL}.",
    ]

    if ports:
        lines.append(
            f"- Declared ports: {', '.join(str(p) for p in ports)}. A dev "
            "server is expected on these; before starting one, assume it may "
            "already be running (check `check-ports` / lsof) rather than "
            "spawning a duplicate."
        )
    if databases:
        names = ", ".join(str(db.get("name", "db")) for db in databases)
        lines.append(
            f"- Databases: {names} (managed via db-* zsh functions; back up "
            "before migrations)."
        )
    if always_on:
        lines.append(
            "- always_on: yes -- this project is expected to always be "
            "running. The dashboard flags it red when down (offering ▶ "
            "起動) and ⟳ 再起動 when up."
        )
    if start_command:
        lines.append(
            f"- start_command: {start_command} (run in the project dir; the "
            "dashboard's start/restart uses exactly this)."
        )

    lines.append(
        f"Run `pj-info {name}` for full details. To change how this project is "
        "managed, edit ~/dotfiles/projects.yml or use the dashboard's ⚙ "
        "config -- do not invent separate config."
    )
    return "\n".join(lines)


def main():
    try:
        cwd = read_cwd()
        projects_file = Path.home() / "dotfiles" / "projects.yml"
        if not projects_file.exists():
            return
        try:
            import yaml
        except ImportError:
            return
        data = yaml.safe_load(projects_file.read_text()) or {}
        match = find_project(data.get("projects", {}) or {}, cwd)
        if not match:
            return  # unregistered dir: stay silent

        context = build_context(*match)
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": context,
            }
        }))
    except Exception:
        pass  # never block session start


if __name__ == "__main__":
    main()
    sys.exit(0)
