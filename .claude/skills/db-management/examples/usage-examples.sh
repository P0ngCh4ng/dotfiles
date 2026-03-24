#!/bin/bash
# Database Management Function Usage Examples
# Assumes db.zsh is sourced and projects.yml is configured

# ============================================================
# Basic Operations (Phase 1)
# ============================================================

# List all databases in a project
db-list myapp
# Output:
# === Databases for project: myapp ===
#
# 📦 main (postgresql)
#   Host: localhost:5432
#   Database: myapp_dev
#   User: postgres
#   🐳 Container: myapp-postgres (running)
#   🔑 Password: ✅ Set (MYAPP_DB_MAIN_PASSWORD)
#
# 📦 cache (redis)
#   Host: localhost:6379
#   🐳 Container: myapp-redis (running)

# Show detailed info for specific database
db-info myapp main
# Output:
# === Database: main (myapp) ===
# Type: postgresql
# Host: localhost
# Port: 5432
# Database: myapp_dev
# User: postgres
#
# Docker:
#   Container: myapp-postgres
#   Status: running
#   Compose: docker-compose.yml
#
# Backup:
#   Enabled: yes
#   Retention: 7 days
#   Path: ~/backups/myapp
#
# Environment:
#   Password variable: MYAPP_DB_MAIN_PASSWORD
#   Status: ✅ Set

# Connect to database
export MYAPP_DB_MAIN_PASSWORD="secret123"
db-connect myapp main
# Opens interactive psql/mysql session

# ============================================================
# Backup & Restore (Phase 2)
# ============================================================

# Create backup
db-backup myapp main
# Output:
# Creating backup for myapp/main...
# ✅ Backup created: ~/backups/myapp/20260324_160523.sql.gz
# 🗑️  Cleaned up 2 old backup(s)

# List backups
ls -lh ~/dotfiles/etc/db/backup/myapp/main/
# Output:
# 20260317_100000.sql.gz
# 20260318_100000.sql.gz
# 20260324_160523.sql.gz  (latest)

# Restore from latest backup
db-restore myapp main latest
# Prompts for confirmation:
# ⚠️  WARNING: This will OVERWRITE the current database!
# Database: myapp_dev
# Backup file: ~/backups/myapp/20260324_160523.sql.gz
# Are you sure? Type 'yes' to continue: yes
# Restoring database...
# ✅ Database restored successfully

# Restore from specific backup
db-restore myapp main 20260318_100000.sql.gz

# ============================================================
# Docker Management (Phase 3)
# ============================================================

# Check container status
db-status myapp
# Output:
# === Database Container Status: myapp ===
#
# 📦 main (myapp-postgres)
#   Status: ✅ Running
#   Container: myapp-postgres
#
# 📦 cache (myapp-redis)
#   Status: ✅ Running
#   Container: myapp-redis

# Start all databases for a project
db-start myapp
# Output:
# Starting database containers for myapp...
# ✅ Started container: myapp-postgres
# ✅ Started container: myapp-redis

# Start specific database
db-start myapp main
# Output:
# Starting database: main (myapp-postgres)...
# Using docker-compose file: /Users/pongchang/projects/myapp/docker-compose.yml
# ✅ Container myapp-postgres started

# Stop specific database
db-stop myapp main
# Output:
# Stopping database: main (myapp-postgres)...
# ✅ Container myapp-postgres stopped

# Stop all databases
db-stop myapp
# Output:
# Stopping database containers for myapp...
# ✅ Stopped container: myapp-postgres
# ✅ Stopped container: myapp-redis

# ============================================================
# Security & Testing (Phase 4)
# ============================================================

# Set password securely (hidden input)
db-set-password myapp main
# Prompts:
# Enter password (input hidden): ********
# Confirm password: ********
# ✅ Password set for current session
# ℹ️  To persist, add to ~/.zshenv:
# export MYAPP_DB_MAIN_PASSWORD="YOUR_PASSWORD_HERE"

# Test database connection
db-test-connection myapp main
# Output:
# Testing connection to myapp/main...
# ✅ Connection successful

# Or if failed:
# Testing connection to myapp/main...
# ❌ Connection failed
# Please check:
#   - Password is set (MYAPP_DB_MAIN_PASSWORD)
#   - Container is running (myapp-postgres)
#   - Database credentials are correct

# ============================================================
# Common Workflows
# ============================================================

# Workflow 1: Daily development
db-status myapp              # Check status
db-start myapp              # Start if needed
db-connect myapp main       # Connect and work

# Workflow 2: Before major changes
db-backup myapp main        # Create backup
# ... make changes ...
db-test-connection myapp main  # Verify still works
# If something breaks:
db-restore myapp main latest

# Workflow 3: Project setup
cp ~/dotfiles/projects.yml.example ~/dotfiles/projects.yml
# Edit projects.yml to add your project
db-set-password myapp main  # Set password
db-start myapp              # Start containers
db-test-connection myapp main  # Verify setup
db-connect myapp main       # Start working

# Workflow 4: Switching between projects
db-stop oldproject          # Stop old project DBs
db-start newproject         # Start new project DBs
db-status newproject        # Verify running

# ============================================================
# Error Handling Examples
# ============================================================

# Password not set
db-connect myapp main
# Error: Password not set for myapp/main
# Set the environment variable: MYAPP_DB_MAIN_PASSWORD

# Container not found
db-connect myapp main
# Error: Database not found in projects.yml
# Available databases:
#   - myapp/main
#   - myapp/cache

# Database not in projects.yml
db-info nonexistent main
# Error: Project 'nonexistent' not found in projects.yml
#
# Available projects:
#   - myapp
#   - legacy-api
#   - ecommerce

# ============================================================
# Integration with Other Tools
# ============================================================

# Use with project switching
cd ~/projects/myapp
db-start $(basename $(pwd))  # Start DBs for current project
db-connect $(basename $(pwd)) main

# Backup before git operations
git checkout feature-branch
db-backup myapp main  # Backup before testing new feature

# Automated backup script
#!/bin/bash
for project in myapp legacy-api ecommerce; do
    db-backup $project main
done

# Health check script
#!/bin/bash
db-status myapp || db-start myapp
db-test-connection myapp main || {
    echo "Database unhealthy, restarting..."
    db-stop myapp main
    db-start myapp main
}
