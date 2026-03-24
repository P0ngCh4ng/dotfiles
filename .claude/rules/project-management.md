# Project Management Rules

## CRITICAL: Always Load projects.yml First

**`~/dotfiles/projects.yml` is the single source of truth for ALL projects on this machine.**

### At the Start of EVERY Session

**AUTOMATICALLY read `~/dotfiles/projects.yml`** to understand:
- All available projects (dotfiles, pon, sokko, chatclinic, onlinemedic, hojocon)
- Port assignments and potential conflicts
- Database configurations
- Tech stacks and paths

**Do NOT wait for the user to ask.** Load this context proactively.

---

## When to Reference projects.yml

**ALWAYS check projects.yml when:**
- User mentions ANY project name (explicit or implicit)
- User mentions ports ("port 3000", "address already in use", "start server")
- User mentions databases ("MySQL", "connect to DB", "backup")
- User asks about project structure or tech stack
- User wants to start/stop development servers
- User asks "what projects do I have?"
- **ANY uncertainty about project details**

**Rule of thumb: If unsure, read projects.yml.**

---

## Managed Projects Inventory

Current projects (as of last update):

1. **dotfiles** - Personal dotfiles and PC management hub
   - Path: ~/dotfiles
   - Ports: None
   - Tech: zsh, emacs, make

2. **pon** - PON! Dynamic MCP Server Orchestration Platform
   - Path: ~/pon
   - Port: 8888
   - Tech: react, primereact, webpack, mcp

3. **sokko** - Linear Issue Tracking MCP (KENSHO)
   - Path: ~/SOKKO
   - Ports: 5174 (vite), 3306 (MySQL)
   - Tech: php, laravel, vue, vite, mysql
   - **DB**: MySQL (laravel) - Docker: kensyo-db

4. **chatclinic** - ClinicTalk オンライン診療予約・相談システム
   - Path: ~/ChatClinic
   - Ports: 3000 (main), 3001 (payment)
   - Tech: typescript, node, express, mysql
   - **DB**: MySQL (chatclinic)

5. **onlinemedic** - ONLINE MEDIC オンライン診療サービス
   - Path: ~/onlinemedic
   - Port: 3005
   - Tech: typescript, node, express, prisma, mysql
   - **DB**: MySQL (chatclinic) - Shared with ChatClinic

6. **hojocon** - 補助金申請管理システム
   - Path: ~/hojocon
   - Port: 3006
   - Tech: nextjs, react, typescript, drizzle

**Note**: This list may be outdated. ALWAYS read projects.yml for current state.

---

## Proactive Actions

### When User Works on a Project

**Automatically suggest:**
1. Check project info: `pj-info <project>`
2. Verify ports: `check-ports`
3. Check database status: `db-status <project>`
4. Start databases if needed: `db-start <project>`

### When User Mentions Port Issues

**Immediately:**
1. Run `check-ports` to see conflicts
2. Check which project uses that port
3. Suggest solutions (change port, stop other service)

### When User Mentions Database

**Automatically:**
1. Check if project has DB configured
2. Verify connection: `db-test-connection <project> <db>`
3. Show DB info: `db-info <project> <db>`
4. Suggest backup before risky operations

---

## Available Commands

### Project Information
- `pj-info <project>` - Show project details
- `port-scan` - Show currently used ports
- `check-ports` - Check all project port assignments

### Database Management (see database-management.md for details)
- `db-list <project>` - List all databases
- `db-info <project> <db>` - Show database details
- `db-connect <project> <db>` - Connect to database
- `db-backup <project> <db>` - Create backup
- `db-restore <project> <db> <file>` - Restore from backup
- `db-status <project>` - Show container status
- `db-start <project>` - Start database containers
- `db-stop <project>` - Stop database containers
- `db-set-password <project> <db>` - Set password securely
- `db-test-connection <project> <db>` - Test connection

---

## Prohibited Actions

**NEVER:**
- Commit `projects.yml` to git (it's gitignored, local only)
- Assume port numbers without checking projects.yml
- Remove projects without explicit permission
- Store passwords in projects.yml (use environment variables)
- Modify projects.yml without showing user the changes

---

## Integration with Other Rules

- **database-management.md**: Detailed DB operation workflows
- **~/dotfiles/CLAUDE.md**: Project-specific documentation
- **~/dotfiles/PROJECT_MANAGEMENT.md**: Comprehensive user guide

---

## Workflow Examples

### Example 1: User says "start chatclinic"

**Claude Code should:**
1. Read projects.yml
2. See chatclinic uses ports 3000, 3001 and has MySQL
3. Check port availability: `check-ports`
4. Check DB status: `db-status chatclinic`
5. Start DB if needed: `db-start chatclinic`
6. Confirm: "ChatClinic uses ports 3000 (main) and 3001 (payment). Database is running. Ready to start."

### Example 2: User says "port 3000 is already in use"

**Claude Code should:**
1. Run: `check-ports`
2. See port 3000 is used by chatclinic
3. Inform: "Port 3000 is used by chatclinic (main app). Options:
   - Stop chatclinic if not needed
   - Use different port for your new service
   - Current port assignments: [show all]"

### Example 3: User mentions "working on sokko"

**Claude Code should:**
1. Read projects.yml
2. Note sokko is Laravel + Vue with MySQL
3. Suggest: "Sokko uses port 5174 (vite) and has MySQL database (kensyo-db).
   - Check DB: `db-status sokko`
   - Start DB: `db-start sokko`
   - Project path: ~/SOKKO"

---

## Summary

**Golden Rule**: Read `~/dotfiles/projects.yml` at the start of every session and whenever there's any uncertainty about projects, ports, or databases.

**Be Proactive**: Don't wait for users to ask. Use project knowledge to provide helpful suggestions automatically.

**Stay Updated**: projects.yml is the source of truth. Always check it for current state.
