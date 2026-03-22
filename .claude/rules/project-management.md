# Project Management Rules

`~/dotfiles/projects.yml` is the **central registry** for all local projects on this machine.

## Core Rule: ALWAYS Check projects.yml

**Read ~/dotfiles/projects.yml when:**
- User mentions ANY project name (pon, sokko, chatclinic, onlinemedic, hojocon, etc.)
- User asks about projects ("what projects", "list projects")
- User mentions ports or port conflicts ("port 3000", "address already in use")
- Starting/stopping development servers
- User asks about project paths or locations

**Even if unsure, check projects.yml first.**

## Actions

1. **Read**: `~/dotfiles/projects.yml` to get current state
2. **Use functions**: Suggest `port-scan`, `pj-info <name>`, or `check-ports`
3. **Update**: If new project detected, ask to add it to projects.yml

## Prohibited

- Never commit `projects.yml` to git (gitignored)
- Never assume port numbers without checking
- Never remove projects without explicit permission

## Details

For detailed usage, commands, and examples, see:
- `~/dotfiles/CLAUDE.md` (comprehensive guide)
- `~/dotfiles/projects.yml.example` (template)

---

**Simple rule: When in doubt about projects or ports, check projects.yml first.**
