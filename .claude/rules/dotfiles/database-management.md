# Database Management Rule

## Overview

This dotfiles repository includes a comprehensive database management system integrated with `projects.yml`. Claude Code should proactively utilize this system when working with database-related tasks.

**System Components**:
- **Configuration**: `~/dotfiles/projects.yml` - Central database registry
- **Implementation**: `~/dotfiles/db.zsh` - All database functions (sourced by `.zshrc`)
- **Documentation**: `~/.claude/skills/db-management/SKILL.md` - Implementation patterns
- **Examples**: `~/.claude/skills/db-management/examples/` - Usage examples

---

## When to Use Database Management Functions

### Proactive Usage (Suggest Automatically)

Claude Code should **proactively suggest or use** database functions in these scenarios:

1. **Project Setup/Initialization**
   ```bash
   # When user starts working on a project, check DB status
   db-list myproject
   db-status myproject
   ```

2. **Before Database Migrations**
   ```bash
   # Always backup before running migrations
   db-backup myproject main
   # Run migration
   # Verify with db-test-connection
   ```

3. **Development Environment Setup**
   ```bash
   # Help user set up databases
   db-start myproject
   db-test-connection myproject main
   ```

4. **When User Mentions Database Issues**
   - Connection errors → Suggest `db-test-connection`, `db-status`
   - Setup questions → Guide to `db-info`, `db-set-password`
   - Data loss concerns → Remind about `db-backup`

5. **Before Major Code Changes**
   ```bash
   # Proactively suggest backup
   "Before implementing this feature, should we backup the database?"
   db-backup myproject main
   ```

### Reactive Usage (User Asks)

Use when user explicitly asks:
- "How do I connect to the database?"
- "Start the database containers"
- "Backup the database"
- "What databases does this project have?"

---

## Checking Project Database Configuration

### Step 1: Check if Project Has Databases

```bash
# Use pj-info to see if project has databases
pj-info myproject

# Look for line: "Databases: N configured"
```

### Step 2: Get Database Details

```bash
# List all databases
db-list myproject

# Get specific database info
db-info myproject main
```

### Step 3: Parse projects.yml Directly (if needed)

```bash
# Read the configuration
cat ~/dotfiles/projects.yml

# Or use grep to find specific project
grep -A 30 "^  myproject:" ~/dotfiles/projects.yml
```

**Important**: Always check `~/dotfiles/projects.yml` to see available projects and their database configurations.

---

## Security Guidelines

### Password Management

**CRITICAL RULES**:

1. **NEVER suggest storing passwords in projects.yml**
   ```yaml
   # ❌ WRONG
   databases:
     - name: main
       password: "secret123"  # NEVER DO THIS

   # ✅ CORRECT
   databases:
     - name: main
       # Password via env var: MYPROJECT_DB_MAIN_PASSWORD
   ```

2. **ALWAYS use environment variables**
   ```bash
   # Naming convention: ${PROJECT^^}_DB_${DB_NAME^^}_PASSWORD
   export MYPROJECT_DB_MAIN_PASSWORD="secret123"
   ```

3. **Guide users to secure password setup**
   ```bash
   # Interactive setup with hidden input
   db-set-password myproject main

   # Or guide to add to ~/.zshenv
   echo 'export MYPROJECT_DB_MAIN_PASSWORD="your_password"' >> ~/.zshenv
   chmod 600 ~/.zshenv
   ```

4. **NEVER expose passwords in command suggestions**
   ```bash
   # ❌ WRONG
   mysql -u user -p"secret123" database

   # ✅ CORRECT
   db-connect myproject main  # Uses env var internally
   ```

---

## Common Workflows

### Workflow 1: Help User Start Working on Project

```bash
# 1. Show project info including databases
pj-info myproject

# 2. Check database status
db-status myproject

# 3. Start databases if not running
db-start myproject

# 4. Test connection
db-test-connection myproject main

# 5. If password not set, guide user
db-set-password myproject main
```

### Workflow 2: Database Backup Before Changes

```bash
# 1. Inform user about backup recommendation
echo "Backing up database before making changes..."

# 2. Create backup
db-backup myproject main

# 3. Note the backup file location
# Output shows: ~/dotfiles/etc/db/backup/myproject/main/TIMESTAMP.sql.gz

# 4. Proceed with changes
# ...

# 5. If something goes wrong, suggest restore
db-restore myproject main latest
```

### Workflow 3: New Project Database Setup

```bash
# 1. Guide user to edit projects.yml
vim ~/dotfiles/projects.yml
# (Use ~/.claude/skills/db-management/examples/example-projects.yml as reference)

# 2. Set up password
db-set-password myproject main

# 3. Start containers
db-start myproject

# 4. Verify setup
db-test-connection myproject main

# 5. Connect and work
db-connect myproject main
```

### Workflow 4: Troubleshooting Database Issues

```bash
# 1. Check status
db-status myproject

# 2. Check detailed info
db-info myproject main

# 3. Test connection
db-test-connection myproject main

# 4. Common fixes:
# - Password not set → db-set-password myproject main
# - Container not running → db-start myproject main
# - Wrong credentials → Check projects.yml and env vars
```

---

## Available Commands Reference

### Core Operations (Phase 1)
- `db-list <project>` - List all databases with status
- `db-info <project> <db_name>` - Detailed database information
- `db-connect <project> <db_name>` - Connect to database (interactive session)

### Backup & Restore (Phase 2)
- `db-backup <project> <db_name>` - Create timestamped gzip backup
- `db-restore <project> <db_name> <backup_file|latest>` - Restore with confirmation

### Docker Management (Phase 3)
- `db-status <project> [db_name]` - Show container status
- `db-start <project> [db_name]` - Start database container(s)
- `db-stop <project> [db_name]` - Stop database container(s)

### Security & Testing (Phase 4)
- `db-set-password <project> <db_name>` - Securely set password (hidden input)
- `db-test-connection <project> <db_name>` - Test database connection

### Project Information
- `pj-info <project>` - Show project details including database count
- `check-ports` - Check all projects' port assignments

---

## Integration with Other Commands

### With Git Operations
```bash
# Before checking out branch with migrations
git checkout feature-with-migration
db-backup myproject main  # Safety first

# After pulling changes with migrations
git pull origin main
db-backup myproject main  # Backup before running new migrations
npm run migrate
```

### With Docker Compose
```bash
# Database functions integrate with docker-compose
# If compose_file specified in projects.yml, commands use it

db-start myproject main
# Internally runs: docker-compose -f /path/to/docker-compose.yml up -d container-name
```

### With Project Switching
```bash
# When user switches projects, suggest DB check
cd ~/projects/newproject
pj-info newproject
db-status newproject
```

---

## Response Patterns

### When User Asks About Databases

**User**: "What databases does this project use?"

**Claude Code**:
```bash
# Check projects.yml for database configuration
db-list myproject
```

### When User Has Connection Issues

**User**: "I can't connect to the database"

**Claude Code**:
```bash
# Let's troubleshoot the database connection
db-test-connection myproject main

# If it fails, check:
# 1. Is the container running?
db-status myproject

# 2. Is the password set?
db-info myproject main  # Shows password env var status

# 3. Start container if needed
db-start myproject main

# 4. Set password if needed
db-set-password myproject main
```

### When Suggesting Dangerous Operations

**User**: "Run this database migration"

**Claude Code**:
```
Before running the migration, let me backup the database for safety:

db-backup myproject main

This creates a timestamped backup at:
~/dotfiles/etc/db/backup/myproject/main/

If something goes wrong, you can restore with:
db-restore myproject main latest

Should I proceed with the migration?
```

---

## Error Handling

### Common Errors and Solutions

1. **"Error: Password not set"**
   ```bash
   # Guide user to set password
   db-set-password myproject main

   # Or add to ~/.zshenv
   echo 'export MYPROJECT_DB_MAIN_PASSWORD="password"' >> ~/.zshenv
   ```

2. **"Error: Container not running"**
   ```bash
   # Start the container
   db-start myproject main

   # Check status
   db-status myproject
   ```

3. **"Error: Database not found in projects.yml"**
   ```bash
   # Show available databases
   db-list  # Shows error with available projects

   # Guide user to add to projects.yml
   vim ~/dotfiles/projects.yml
   # Reference: ~/.claude/skills/db-management/examples/example-projects.yml
   ```

4. **"Error: Connection failed"**
   ```bash
   # Systematically check:
   db-info myproject main     # Verify configuration
   db-status myproject main   # Check container status
   db-test-connection myproject main  # Test connection

   # Check environment variable
   echo $MYPROJECT_DB_MAIN_PASSWORD  # Should show password (or ***)
   ```

---

## Best Practices for Claude Code

### 1. Always Check Before Suggesting
```bash
# Before suggesting database commands, verify project has databases
pj-info myproject | grep "Databases:"
```

### 2. Prefer Existing Functions Over Raw Commands
```bash
# ❌ Don't suggest:
docker exec -it myapp-postgres psql -U postgres -d myapp_dev

# ✅ Instead suggest:
db-connect myproject main
```

### 3. Explain What Functions Do
```
I'll use `db-backup` which creates a timestamped, gzip-compressed backup
and automatically removes backups older than the retention period (7 days).
```

### 4. Provide Context for Security
```
For security, passwords are managed via environment variables.
The password for this database should be set in:
MYPROJECT_DB_MAIN_PASSWORD

You can set it securely with:
db-set-password myproject main
```

### 5. Reference Documentation When Needed
```
For more details on database management, see:
- Full documentation: ~/.claude/skills/db-management/SKILL.md
- Usage examples: ~/.claude/skills/db-management/examples/usage-examples.sh
- Configuration examples: ~/.claude/skills/db-management/examples/example-projects.yml
```

---

## Configuration File Locations

- **Main config**: `~/dotfiles/projects.yml` (user's actual projects, gitignored)
- **Template**: `~/dotfiles/projects.yml.example` (tracked in git)
- **Implementation**: `~/dotfiles/db.zsh` (all functions)
- **Skill docs**: `~/.claude/skills/db-management/SKILL.md`
- **Examples**: `~/.claude/skills/db-management/examples/`
- **Backups**: `~/dotfiles/etc/db/backup/{project}/{db_name}/`

---

## Supported Database Types

**Currently Implemented**:
- MySQL (`type: mysql`)
- PostgreSQL (`type: postgresql`)
- Redis (`type: redis`) - basic support

**Future Support** (mentioned in SKILL.md):
- MongoDB
- SQLite

---

## Quick Reference Card

| Task | Command |
|------|---------|
| List databases | `db-list <project>` |
| Show details | `db-info <project> <db>` |
| Connect | `db-connect <project> <db>` |
| Backup | `db-backup <project> <db>` |
| Restore | `db-restore <project> <db> latest` |
| Check status | `db-status <project>` |
| Start DB | `db-start <project> [db]` |
| Stop DB | `db-stop <project> [db]` |
| Set password | `db-set-password <project> <db>` |
| Test connection | `db-test-connection <project> <db>` |

---

## Related Documentation

- **Project Management**: `~/.claude/rules/project-management.md` - projects.yml schema
- **Emacs Environment**: `~/.claude/rules/emacs-environment.md` - Editor context
- **Implementation Skill**: `~/.claude/skills/db-management/SKILL.md` - Technical details
- **Main Project Docs**: `~/dotfiles/CLAUDE.md` - Repository overview

---

## Summary

**Key Points**:
1. ✅ **Proactively suggest** database functions when appropriate
2. ✅ **Always prioritize security** - use env vars for passwords
3. ✅ **Backup before destructive operations**
4. ✅ **Use existing functions** instead of raw docker/mysql/psql commands
5. ✅ **Check projects.yml** to understand project database configuration
6. ✅ **Guide users** through setup and troubleshooting systematically

**Remember**: This database management system is a powerful tool for managing development databases. Use it proactively to make the user's workflow smoother and safer.
