#!/bin/bash
# Environment Variable Setup Examples for Database Management
# Add these to ~/.zshenv or set them in your session

# ============================================================
# Password Management
# ============================================================

# Convention: ${PROJECT^^}_DB_${DB_NAME^^}_PASSWORD
# Where:
#   - PROJECT: Project name from projects.yml (uppercase)
#   - DB_NAME: Database name from projects.yml (uppercase)

# Example 1: myapp project, main database
export MYAPP_DB_MAIN_PASSWORD="secret123"
export MYAPP_DB_CACHE_PASSWORD="redis456"  # If Redis has auth

# Example 2: legacy-api project
export LEGACY_API_DB_MAIN_PASSWORD="mysql_password"

# Example 3: ecommerce project with multiple databases
export ECOMMERCE_DB_PRODUCTS_PASSWORD="products_pass"
export ECOMMERCE_DB_SESSIONS_PASSWORD="sessions_pass"
export ECOMMERCE_DB_ANALYTICS_PASSWORD="analytics_pass"

# Example 4: remote-project
export REMOTE_PROJECT_DB_MAIN_PASSWORD="production_secret"

# ============================================================
# Secure Storage Options
# ============================================================

# Option 1: Store in ~/.zshenv (recommended for development)
# Make sure file is protected: chmod 600 ~/.zshenv

# Option 2: Use password manager (recommended for production)
# Example with 1Password CLI:
# export MYAPP_DB_MAIN_PASSWORD=$(op read "op://Development/myapp-db/password")

# Option 3: Prompt at shell startup (most secure)
# echo -n "Enter MYAPP database password: "
# read -s MYAPP_DB_MAIN_PASSWORD
# export MYAPP_DB_MAIN_PASSWORD
# echo ""

# ============================================================
# Verification
# ============================================================

# Check if password is set
if [[ -z "$MYAPP_DB_MAIN_PASSWORD" ]]; then
    echo "⚠️  Warning: MYAPP_DB_MAIN_PASSWORD not set"
else
    echo "✅ MYAPP_DB_MAIN_PASSWORD is configured"
fi

# Test connection with password
# db-test-connection myapp main

# ============================================================
# Security Best Practices
# ============================================================

# ✅ DO:
# - Store passwords in environment variables
# - Use ~/.zshenv with chmod 600
# - Use password managers when possible
# - Rotate passwords regularly

# ❌ DON'T:
# - Store passwords in projects.yml
# - Pass passwords as command-line arguments
# - Commit passwords to git
# - Share passwords in plain text

# ============================================================
# Quick Setup Script
# ============================================================

setup_db_passwords() {
    local project="$1"
    local db_name="$2"

    echo -n "Enter password for ${project}/${db_name} (hidden): "
    read -s password
    echo ""

    local env_var="${project^^}_DB_${db_name^^}_PASSWORD"
    export "${env_var}=${password}"

    echo "✅ ${env_var} set for current session"
    echo ""
    echo "To persist, add to ~/.zshenv:"
    echo "export ${env_var}=\"YOUR_PASSWORD_HERE\""
}

# Usage: setup_db_passwords myapp main
