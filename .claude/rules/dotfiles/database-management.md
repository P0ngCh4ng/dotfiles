# Database Management Rule

Databases are registered in `~/dotfiles/projects.yml` and managed by functions in `~/dotfiles/db.zsh` (sourced by `.zshrc`). Use these functions proactively instead of raw `docker`/`mysql`/`psql` commands.

Details & examples: `~/.claude/skills/db-management/SKILL.md`, `~/.claude/skills/db-management/examples/` (`usage-examples.sh`, `example-projects.yml`).

## Commands

| Task | Command |
|---|---|
| Project info (incl. DB count) | `pj-info <project>` |
| List DBs / details | `db-list <project>` / `db-info <project> <db>` |
| Connect (interactive) | `db-connect <project> <db>` |
| Backup (timestamped gzip, auto-rotates by retention) | `db-backup <project> <db>` |
| Restore (with confirmation) | `db-restore <project> <db> <file\|latest>` |
| Container status / start / stop | `db-status <project> [db]` / `db-start …` / `db-stop …` |
| Set password (hidden input) | `db-set-password <project> <db>` |
| Test connection | `db-test-connection <project> <db>` |
| Port assignments | `check-ports` |

If `compose_file` is set in projects.yml, `db-start`/`db-stop` use docker-compose for that container.

## When to Use Proactively

- **Starting work on a project**: `pj-info` → `db-status` → `db-start` if needed → `db-test-connection`.
- **Before migrations, schema changes, bulk deletes, branch switches/pulls that bring migrations**: `db-backup` first, tell the user the backup path (`~/dotfiles/etc/db/backup/{project}/{db}/`) and that `db-restore <project> <db> latest` undoes it, then confirm before running the migration.
- **Before major code changes touching data**: offer a backup.
- **User mentions DB problems**: see Troubleshooting.

Check that the project actually has databases (`pj-info <project> | grep Databases:`) before suggesting DB commands.

## Security (CRITICAL)

- **Never** put passwords in `projects.yml`, code, commits, or command lines (no `mysql -p"secret"`).
- Passwords come from env vars named `${PROJECT^^}_DB_${DB_NAME^^}_PASSWORD` (e.g. `SOKKO_DB_MAIN_PASSWORD`).
- Set them with `db-set-password <project> <db>`, or in `~/.zshenv` (then `chmod 600 ~/.zshenv`).
- Explain to the user which env var the DB expects.

## Troubleshooting

| Error | Fix |
|---|---|
| Password not set | `db-set-password <project> <db>` (or `source ~/.zshenv` if already set there) |
| Container not running | `db-start <project> <db>`, then `db-status <project>` |
| DB not found in projects.yml | `db-list` shows available entries; add it to `~/dotfiles/projects.yml` (see `example-projects.yml`) |
| Connection failed | `db-info` (config) → `db-status` (container) → `db-test-connection`; check the env var is set |

## projects.yml Schema (per database)

```yaml
databases:
  - name: main                 # identifier
    type: mysql                # mysql | postgresql | redis (basic); mongodb/sqlite planned
    host: localhost
    port: 3306                 # optional
    database: app_dev
    user: root
    # password: env var MYPROJECT_DB_MAIN_PASSWORD
    docker: { container: app-db, compose_file: docker-compose.yml }
    backup: { enabled: true, retention_days: 7 }
```

`projects.yml` is gitignored (local only); `projects.yml.example` is the tracked template.
