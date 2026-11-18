#!/usr/bin/env python3
"""SessionStart hook: tell the model, deterministically, when the current
working directory is a project managed by ~/dotfiles/projects.yml.

Unlike enforce-session-start.js (which prints a human-facing banner to
stderr), this emits `hookSpecificOutput.additionalContext` on stdout, which
Claude Code injects into the session context. So every session that starts
inside a registered project *knows* it is managed -- its declared ports, its
always_on / start_command status, and that a local dashboard monitors and can
start/restart it -- without relying on the model choosing to read projects.yml.

Projects flagged `auto_start: true` (with a start_command and ports) also get
their dev server launched here when none of their ports is listening -- so a
heavy dev server runs only while you are working on that project, instead of
24/7 via always_on. Only sessions whose cwd is inside the project's own path
trigger it (git worktrees live at ~/<project>-<branch> and never match).

Prints nothing (empty output) for unregistered directories, so unmanaged
sessions aren't polluted. Never blocks session start: any error -> exit 0.
"""

import fcntl
import json
import os
import socket
import subprocess
import sys
import time
from pathlib import Path

DASHBOARD_URL = "http://localhost:9797"
AUTOSTART_STATE_DIR = Path.home() / "dotfiles" / ".dashboard" / "autostart"
PORT_PROBE_TIMEOUT = 0.3
LOG_MAX_BYTES = 1_000_000
# Only a fresh/resumed session should start a server; /clear and /compact also
# fire SessionStart and must not resurrect a server the user just stopped.
AUTOSTART_SOURCES = {"startup", "resume"}


def read_hook_input():
    """Return (cwd, source) from the SessionStart payload on stdin.

    cwd falls back to os.getcwd(); source is None when not provided.
    """
    payload = {}
    try:
        raw = sys.stdin.read()
        if raw.strip():
            payload = json.loads(raw) or {}
    except Exception:
        pass
    return payload.get("cwd") or os.getcwd(), payload.get("source")


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


def port_listening(port):
    """True if something accepts TCP connections on localhost:port."""
    for host in ("127.0.0.1", "::1"):
        try:
            with socket.create_connection((host, int(port)), PORT_PROBE_TIMEOUT):
                return True
        except (OSError, ValueError):
            continue
    return False


def process_group_alive(pgid):
    try:
        os.killpg(int(pgid), 0)
        return True
    except (OSError, ValueError, TypeError):
        # ESRCH = gone. EPERM too: our own processes are always signalable, so
        # EPERM means a zombie group (macOS) or a sandbox denying signals --
        # treating it as dead keeps auto_start from wedging forever; the port
        # check above still prevents duplicating a server that is listening.
        return False


def spawn_detached(command, cwd, log_path):
    """Run command in its own session, output appended to log_path; return pid."""
    if log_path.exists() and log_path.stat().st_size > LOG_MAX_BYTES:
        log_path.write_bytes(b"")  # keep the log from growing forever
    with open(log_path, "ab") as log:
        log.write(f"\n=== {time.strftime('%Y-%m-%d %H:%M:%S')} {command}\n".encode())
        log.flush()
        proc = subprocess.Popen(
            command,
            shell=True,
            cwd=str(cwd),
            stdin=subprocess.DEVNULL,
            stdout=log,
            stderr=subprocess.STDOUT,
            start_new_session=True,  # own process group; survives the session
        )
    return proc.pid


def maybe_autostart(name, cfg):
    """Start the project's dev server if auto_start is on and it's down.

    Returns a status string for the session context, or None when auto_start
    isn't configured. The command comes only from projects.yml.

    The whole check-and-spawn runs under an exclusive flock on a per-project
    state file, so concurrent sessions are serialized. The state file records
    the spawned process group; while that group is alive (e.g. a cold Next.js
    compile hasn't bound the port yet) no second instance is started.
    """
    if not cfg.get("auto_start"):
        return None
    command = str(cfg.get("start_command", "") or "").strip()
    ports = cfg.get("ports", []) or []
    if not command or not ports:
        return "skipped (auto_start needs both start_command and ports)"
    cwd = Path(os.path.expanduser(str(cfg.get("path", ""))))
    if not cwd.is_dir():
        return f"skipped (path does not exist: {cwd})"

    AUTOSTART_STATE_DIR.mkdir(parents=True, exist_ok=True)
    state_path = AUTOSTART_STATE_DIR / f"{name}.json"
    log_path = AUTOSTART_STATE_DIR / f"{name}.log"
    fd = os.open(state_path, os.O_RDWR | os.O_CREAT, 0o644)
    try:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return "being started by another session"

        if any(port_listening(p) for p in ports):
            return "already running"

        try:
            state = json.loads(os.pread(fd, 4096, 0) or b"{}")
        except ValueError:
            state = {}
        if process_group_alive(state.get("pgid")):
            return (f"still starting (pgid {state['pgid']} alive, port not "
                    f"listening yet; log: {log_path})")

        pid = spawn_detached(command, cwd, log_path)
        os.ftruncate(fd, 0)
        os.pwrite(fd, json.dumps({"pgid": pid, "started": time.time()}).encode(), 0)
        return f"started now in background (log: {log_path})"
    finally:
        os.close(fd)  # also releases the flock


def build_context(name, cfg, autostart_status=None):
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

    if autostart_status:
        lines.append(
            f"- auto_start: dev server {autostart_status}. Do not launch a "
            "second instance; stop it from the dashboard when done."
        )

    lines.append(
        f"Run `pj-info {name}` for full details. To change how this project is "
        "managed, edit ~/dotfiles/projects.yml or use the dashboard's ⚙ "
        "config -- do not invent separate config."
    )
    return "\n".join(lines)


def main():
    try:
        cwd, source = read_hook_input()
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

        name, cfg = match
        cfg = cfg or {}
        autostart_status = None
        if source is None or source in AUTOSTART_SOURCES:
            try:
                autostart_status = maybe_autostart(name, cfg)
            except Exception as e:
                autostart_status = f"failed to start ({e})"
        context = build_context(name, cfg, autostart_status)
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
