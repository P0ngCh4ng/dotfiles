#!/usr/bin/env zsh
# ============================================
# Database Management Functions
# ============================================
#
# Description: Comprehensive database management for projects.yml
# Location: ~/dotfiles/db.zsh
# Sourced by: ~/.zshrc
#
# Features:
#   - Core: db-list, db-info, db-connect
#   - Backup: db-backup, db-restore (with rotation)
#   - Docker: db-status, db-start, db-stop
#   - Security: db-set-password, db-test-connection
#
# Supported Databases: MySQL, PostgreSQL
# Password Convention: ${PROJECT}_DB_${DB_NAME}_PASSWORD
#
# Usage Examples:
#   db-list myproject
#   db-connect myproject main
#   db-backup myproject main
#   db-restore myproject main latest
#   db-status myproject
#
# ============================================

# Helper: Get database password from environment variable
# Usage: _get_db_password <project_name> <db_name>
_get_db_password() {
    local project="$1"
    local db_name="$2"
    local env_var="${project^^}_DB_${db_name^^}_PASSWORD"
    echo "${(P)env_var}"
}

# Helper: Get default port for DB type
_get_default_db_port() {
    local db_type="$1"
    case "$db_type" in
        mysql) echo "3306" ;;
        postgresql) echo "5432" ;;
        redis) echo "6379" ;;
        mongodb) echo "27017" ;;
        sqlite) echo "" ;;
        *) echo "" ;;
    esac
}

# Helper: Check if Docker container is running
_is_container_running() {
    local container_name="$1"
    docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container_name}$"
}

# List all databases for a project
# Usage: db-list [project-name]
db-list() {
    local project="${1:-$(basename $(pwd))}"

    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo "Error: $PROJECTS_FILE not found" >&2
        return 1
    fi

    echo "=== Databases for project: $project ==="
    echo ""

    # YAMLパース: databases セクションを抽出
    local in_project=0
    local in_databases=0
    local db_name=""
    local db_type=""
    local db_host=""
    local db_port=""
    local db_database=""
    local db_user=""
    local container_name=""

    while IFS= read -r line; do
        # プロジェクトセクション開始
        if [[ "$line" =~ ^[[:space:]]*${project}:$ ]]; then
            in_project=1
            continue
        fi

        # 次のプロジェクトが始まったら終了
        if [[ $in_project -eq 1 && "$line" =~ ^[[:space:]]*[a-zA-Z0-9_-]+:$ && ! "$line" =~ databases: ]]; then
            break
        fi

        if [[ $in_project -eq 1 ]]; then
            # databases セクション開始
            if [[ "$line" =~ ^[[:space:]]+databases: ]]; then
                in_databases=1
                continue
            fi

            if [[ $in_databases -eq 1 ]]; then
                # 新しいDB開始 (- name:)
                if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+name:[[:space:]]*(.*) ]]; then
                    # 前のDBを出力
                    if [[ -n "$db_name" ]]; then
                        _print_db_info "$db_name" "$db_type" "$db_host" "$db_port" "$db_database" "$db_user" "$container_name"
                    fi
                    # リセット
                    db_name="${match[1]}"
                    db_type=""
                    db_host=""
                    db_port=""
                    db_database=""
                    db_user=""
                    container_name=""
                # DB属性
                elif [[ "$line" =~ ^[[:space:]]+type:[[:space:]]*(.*) ]]; then
                    db_type="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+host:[[:space:]]*(.*) ]]; then
                    db_host="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+port:[[:space:]]*(.*) ]]; then
                    db_port="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+database:[[:space:]]*(.*) ]]; then
                    db_database="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+user:[[:space:]]*(.*) ]]; then
                    db_user="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+container:[[:space:]]*(.*) ]]; then
                    container_name="${match[1]}"
                fi
            fi
        fi
    done < "$PROJECTS_FILE"

    # 最後のDBを出力
    if [[ -n "$db_name" ]]; then
        _print_db_info "$db_name" "$db_type" "$db_host" "$db_port" "$db_database" "$db_user" "$container_name"
    fi
}

# Helper: Print database info
_print_db_info() {
    local name="$1"
    local type="$2"
    local host="$3"
    local port="$4"
    local database="$5"
    local user="$6"
    local container="$7"

    # デフォルトポート
    if [[ -z "$port" ]]; then
        port=$(_get_default_db_port "$type")
    fi

    echo "[$name] $type"
    echo "  Host: $host:$port"
    echo "  Database: $database"
    echo "  User: $user"

    if [[ -n "$container" ]]; then
        if _is_container_running "$container"; then
            echo "  Docker: $container ✅"
        else
            echo "  Docker: $container ❌ (not running)"
        fi
    fi
    echo ""
}

# Show database information for a project
# Usage: db-info [project-name] [db-name]
db-info() {
    local project="${1:-$(basename $(pwd))}"
    local target_db="${2:-}"

    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo "Error: $PROJECTS_FILE not found" >&2
        return 1
    fi

    echo "=== Database Info: $project ==="
    echo ""

    local in_project=0
    local in_databases=0
    local db_name=""
    local db_type=""
    local db_host=""
    local db_port=""
    local db_database=""
    local db_user=""
    local container_name=""
    local found=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*${project}:$ ]]; then
            in_project=1
            continue
        fi

        if [[ $in_project -eq 1 && "$line" =~ ^[[:space:]]*[a-zA-Z0-9_-]+:$ && ! "$line" =~ databases: ]]; then
            break
        fi

        if [[ $in_project -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]+databases: ]]; then
                in_databases=1
                continue
            fi

            if [[ $in_databases -eq 1 ]]; then
                if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+name:[[:space:]]*(.*) ]]; then
                    if [[ -n "$db_name" ]]; then
                        if [[ -z "$target_db" || "$db_name" == "$target_db" ]]; then
                            _print_db_detailed "$db_name" "$db_type" "$db_host" "$db_port" "$db_database" "$db_user" "$container_name" "$project"
                            found=1
                        fi
                    fi
                    db_name="${match[1]}"
                    db_type=""
                    db_host=""
                    db_port=""
                    db_database=""
                    db_user=""
                    container_name=""
                elif [[ "$line" =~ ^[[:space:]]+type:[[:space:]]*(.*) ]]; then
                    db_type="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+host:[[:space:]]*(.*) ]]; then
                    db_host="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+port:[[:space:]]*(.*) ]]; then
                    db_port="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+database:[[:space:]]*(.*) ]]; then
                    db_database="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+user:[[:space:]]*(.*) ]]; then
                    db_user="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+container:[[:space:]]*(.*) ]]; then
                    container_name="${match[1]}"
                fi
            fi
        fi
    done < "$PROJECTS_FILE"

    if [[ -n "$db_name" ]]; then
        if [[ -z "$target_db" || "$db_name" == "$target_db" ]]; then
            _print_db_detailed "$db_name" "$db_type" "$db_host" "$db_port" "$db_database" "$db_user" "$container_name" "$project"
            found=1
        fi
    fi

    if [[ $found -eq 0 ]]; then
        echo "No database found for project: $project" >&2
        if [[ -n "$target_db" ]]; then
            echo "Database name '$target_db' not found" >&2
        fi
        return 1
    fi
}

# Helper: Print detailed database info
_print_db_detailed() {
    local name="$1"
    local type="$2"
    local host="$3"
    local port="$4"
    local database="$5"
    local user="$6"
    local container="$7"
    local project="$8"

    if [[ -z "$port" ]]; then
        port=$(_get_default_db_port "$type")
    fi

    echo "Database: $name"
    echo "  Type: $type"
    echo "  Host: $host"
    echo "  Port: $port"
    echo "  Database: $database"
    echo "  User: $user"

    # パスワード環境変数
    local env_var="${project^^}_DB_${name^^}_PASSWORD"
    if [[ -n "${(P)env_var}" ]]; then
        echo "  Password: \$${env_var} ✅"
    else
        echo "  Password: \$${env_var} ⚠️  (not set)"
    fi

    # Docker状態
    if [[ -n "$container" ]]; then
        if _is_container_running "$container"; then
            echo "  Docker Container: $container ✅ (running)"
        else
            echo "  Docker Container: $container ❌ (stopped)"
        fi
    fi

    # 接続文字列
    case "$type" in
        mysql)
            echo "  Connection: mysql -h $host -P $port -u $user -p $database"
            ;;
        postgresql)
            echo "  Connection: psql -h $host -p $port -U $user -d $database"
            ;;
    esac

    echo ""
}

# Connect to a database
# Usage: db-connect [project-name] [db-name]
db-connect() {
    local project="${1:-$(basename $(pwd))}"
    local target_db="${2:-main}"

    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo "Error: $PROJECTS_FILE not found" >&2
        return 1
    fi

    # DB情報を取得
    local in_project=0
    local in_databases=0
    local db_name=""
    local db_type=""
    local db_host=""
    local db_port=""
    local db_database=""
    local db_user=""
    local container_name=""
    local found=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*${project}:$ ]]; then
            in_project=1
            continue
        fi

        if [[ $in_project -eq 1 && "$line" =~ ^[[:space:]]*[a-zA-Z0-9_-]+:$ && ! "$line" =~ databases: ]]; then
            break
        fi

        if [[ $in_project -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]+databases: ]]; then
                in_databases=1
                continue
            fi

            if [[ $in_databases -eq 1 ]]; then
                if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+name:[[:space:]]*(.*) ]]; then
                    if [[ -n "$db_name" && "$db_name" == "$target_db" ]]; then
                        found=1
                        break
                    fi
                    db_name="${match[1]}"
                    db_type=""
                    db_host=""
                    db_port=""
                    db_database=""
                    db_user=""
                    container_name=""
                elif [[ "$line" =~ ^[[:space:]]+type:[[:space:]]*(.*) ]]; then
                    db_type="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+host:[[:space:]]*(.*) ]]; then
                    db_host="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+port:[[:space:]]*(.*) ]]; then
                    db_port="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+database:[[:space:]]*(.*) ]]; then
                    db_database="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+user:[[:space:]]*(.*) ]]; then
                    db_user="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+container:[[:space:]]*(.*) ]]; then
                    container_name="${match[1]}"
                fi
            fi
        fi
    done < "$PROJECTS_FILE"

    # 最後のDBをチェック
    if [[ -n "$db_name" && "$db_name" == "$target_db" ]]; then
        found=1
    fi

    if [[ $found -eq 0 ]]; then
        echo "Error: Database '$target_db' not found for project '$project'" >&2
        return 1
    fi

    # デフォルトポート
    if [[ -z "$db_port" ]]; then
        db_port=$(_get_default_db_port "$db_type")
    fi

    # パスワード取得
    local password=$(_get_db_password "$project" "$db_name")

    echo "Connecting to $db_type database: $db_database..."

    # Docker経由で接続
    if [[ -n "$container_name" ]] && _is_container_running "$container_name"; then
        echo "Using Docker container: $container_name"
        case "$db_type" in
            mysql)
                if [[ -n "$password" ]]; then
                    docker exec -it -e MYSQL_PWD="$password" "$container_name" mysql -u "$db_user" "$db_database"
                else
                    docker exec -it "$container_name" mysql -u "$db_user" -p "$db_database"
                fi
                ;;
            postgresql)
                docker exec -it -e PGPASSWORD="$password" "$container_name" psql -U "$db_user" -d "$db_database"
                ;;
            *)
                echo "Error: Docker connection not supported for DB type: $db_type" >&2
                return 1
                ;;
        esac
    else
        # ホスト経由で接続
        case "$db_type" in
            mysql)
                if [[ -n "$password" ]]; then
                    MYSQL_PWD="$password" mysql -h "$db_host" -P "$db_port" -u "$db_user" "$db_database"
                else
                    mysql -h "$db_host" -P "$db_port" -u "$db_user" -p "$db_database"
                fi
                ;;
            postgresql)
                if [[ -n "$password" ]]; then
                    PGPASSWORD="$password" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_database"
                else
                    psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_database"
                fi
                ;;
            *)
                echo "Error: Connection not supported for DB type: $db_type" >&2
                return 1
                ;;
        esac
    fi
}

# Backup a database
# Usage: db-backup [project-name] [db-name]
db-backup() {
    local project="${1:-$(basename $(pwd))}"
    local target_db="${2:-main}"

    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo "Error: $PROJECTS_FILE not found" >&2
        return 1
    fi

    # DB情報を取得
    local in_project=0
    local in_databases=0
    local db_name=""
    local db_type=""
    local db_host=""
    local db_port=""
    local db_database=""
    local db_user=""
    local container_name=""
    local backup_enabled="true"
    local backup_path=""
    local retention_days="7"
    local found=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*${project}:$ ]]; then
            in_project=1
            continue
        fi

        if [[ $in_project -eq 1 && "$line" =~ ^[[:space:]]*[a-zA-Z0-9_-]+:$ && ! "$line" =~ databases: ]]; then
            break
        fi

        if [[ $in_project -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]+databases: ]]; then
                in_databases=1
                continue
            fi

            if [[ $in_databases -eq 1 ]]; then
                if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+name:[[:space:]]*(.*) ]]; then
                    if [[ -n "$db_name" && "$db_name" == "$target_db" ]]; then
                        found=1
                        break
                    fi
                    db_name="${match[1]}"
                    db_type=""
                    db_host=""
                    db_port=""
                    db_database=""
                    db_user=""
                    container_name=""
                    backup_enabled="true"
                    backup_path=""
                    retention_days="7"
                elif [[ "$line" =~ ^[[:space:]]+type:[[:space:]]*(.*) ]]; then
                    db_type="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+host:[[:space:]]*(.*) ]]; then
                    db_host="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+port:[[:space:]]*(.*) ]]; then
                    db_port="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+database:[[:space:]]*(.*) ]]; then
                    db_database="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+user:[[:space:]]*(.*) ]]; then
                    db_user="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+container:[[:space:]]*(.*) ]]; then
                    container_name="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+enabled:[[:space:]]*(.*) ]]; then
                    backup_enabled="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+path:[[:space:]]*(.*) ]]; then
                    backup_path="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+retention_days:[[:space:]]*(.*) ]]; then
                    retention_days="${match[1]}"
                fi
            fi
        fi
    done < "$PROJECTS_FILE"

    if [[ -n "$db_name" && "$db_name" == "$target_db" ]]; then
        found=1
    fi

    if [[ $found -eq 0 ]]; then
        echo "Error: Database '$target_db' not found for project '$project'" >&2
        return 1
    fi

    # デフォルトポート
    if [[ -z "$db_port" ]]; then
        db_port=$(_get_default_db_port "$db_type")
    fi

    # バックアップパス設定
    if [[ -z "$backup_path" ]]; then
        backup_path="$HOME/dotfiles/etc/db/backup/${project}/${db_name}"
    else
        backup_path="${backup_path/#\~/$HOME}"
    fi

    # ディレクトリ作成
    mkdir -p "$backup_path"

    # タイムスタンプ
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_path}/${timestamp}"

    # パスワード取得
    local password=$(_get_db_password "$project" "$db_name")

    echo "Backing up $db_type database: $db_database..."
    echo "Backup path: $backup_file"

    # DBタイプ別バックアップ
    local backup_success=0
    case "$db_type" in
        mysql)
            backup_file="${backup_file}.sql.gz"
            if [[ -n "$container_name" ]] && _is_container_running "$container_name"; then
                if [[ -n "$password" ]]; then
                    docker exec "$container_name" mysqldump -u "$db_user" -p"$password" "$db_database" | gzip > "$backup_file"
                else
                    docker exec "$container_name" mysqldump -u "$db_user" "$db_database" | gzip > "$backup_file"
                fi
            else
                if [[ -n "$password" ]]; then
                    MYSQL_PWD="$password" mysqldump -h "$db_host" -P "$db_port" -u "$db_user" "$db_database" | gzip > "$backup_file"
                else
                    mysqldump -h "$db_host" -P "$db_port" -u "$db_user" -p "$db_database" | gzip > "$backup_file"
                fi
            fi
            backup_success=$?
            ;;
        postgresql)
            backup_file="${backup_file}.dump.gz"
            if [[ -n "$container_name" ]] && _is_container_running "$container_name"; then
                docker exec "$container_name" pg_dump -U "$db_user" -d "$db_database" | gzip > "$backup_file"
            else
                if [[ -n "$password" ]]; then
                    PGPASSWORD="$password" pg_dump -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_database" | gzip > "$backup_file"
                else
                    pg_dump -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_database" | gzip > "$backup_file"
                fi
            fi
            backup_success=$?
            ;;
        *)
            echo "Error: Backup not supported for DB type: $db_type" >&2
            return 1
            ;;
    esac

    if [[ $backup_success -eq 0 ]]; then
        local file_size=$(du -h "$backup_file" | cut -f1)
        echo "✅ Backup completed: $backup_file ($file_size)"

        # ローテーション実行
        _cleanup_old_backups "$backup_path" "$retention_days"
    else
        echo "❌ Backup failed" >&2
        return 1
    fi
}

# Helper: Clean up old backups
_cleanup_old_backups() {
    local backup_dir="$1"
    local retention_days="$2"

    if [[ ! -d "$backup_dir" ]]; then
        return 0
    fi

    local deleted=0
    while IFS= read -r file; do
        rm -f "$file"
        ((deleted++))
    done < <(find "$backup_dir" -type f -mtime +"$retention_days" 2>/dev/null)

    if [[ $deleted -gt 0 ]]; then
        echo "🗑️  Cleaned up $deleted old backup(s) (older than $retention_days days)"
    fi
}

# Restore a database from backup
# Usage: db-restore [project-name] [db-name] [backup-file]
db-restore() {
    local project="${1:-$(basename $(pwd))}"
    local target_db="${2:-main}"
    local backup_file="${3:-}"

    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo "Error: $PROJECTS_FILE not found" >&2
        return 1
    fi

    # DB情報を取得（db-backupと同じロジック）
    local in_project=0
    local in_databases=0
    local db_name=""
    local db_type=""
    local db_host=""
    local db_port=""
    local db_database=""
    local db_user=""
    local container_name=""
    local backup_path=""
    local found=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*${project}:$ ]]; then
            in_project=1
            continue
        fi

        if [[ $in_project -eq 1 && "$line" =~ ^[[:space:]]*[a-zA-Z0-9_-]+:$ && ! "$line" =~ databases: ]]; then
            break
        fi

        if [[ $in_project -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]+databases: ]]; then
                in_databases=1
                continue
            fi

            if [[ $in_databases -eq 1 ]]; then
                if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+name:[[:space:]]*(.*) ]]; then
                    if [[ -n "$db_name" && "$db_name" == "$target_db" ]]; then
                        found=1
                        break
                    fi
                    db_name="${match[1]}"
                    db_type=""
                    db_host=""
                    db_port=""
                    db_database=""
                    db_user=""
                    container_name=""
                    backup_path=""
                elif [[ "$line" =~ ^[[:space:]]+type:[[:space:]]*(.*) ]]; then
                    db_type="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+host:[[:space:]]*(.*) ]]; then
                    db_host="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+port:[[:space:]]*(.*) ]]; then
                    db_port="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+database:[[:space:]]*(.*) ]]; then
                    db_database="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+user:[[:space:]]*(.*) ]]; then
                    db_user="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+container:[[:space:]]*(.*) ]]; then
                    container_name="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+path:[[:space:]]*(.*) ]]; then
                    backup_path="${match[1]}"
                fi
            fi
        fi
    done < "$PROJECTS_FILE"

    if [[ -n "$db_name" && "$db_name" == "$target_db" ]]; then
        found=1
    fi

    if [[ $found -eq 0 ]]; then
        echo "Error: Database '$target_db' not found for project '$project'" >&2
        return 1
    fi

    # バックアップパス設定
    if [[ -z "$backup_path" ]]; then
        backup_path="$HOME/dotfiles/etc/db/backup/${project}/${db_name}"
    else
        backup_path="${backup_path/#\~/$HOME}"
    fi

    # バックアップファイル選択
    if [[ -z "$backup_file" ]]; then
        echo "Available backups in $backup_path:"
        ls -lht "$backup_path" 2>/dev/null | tail -n +2 | head -10
        echo ""
        echo -n "Enter backup filename (or 'latest' for most recent): "
        read backup_filename

        if [[ "$backup_filename" == "latest" ]]; then
            backup_file=$(ls -t "$backup_path"/* 2>/dev/null | head -1)
        else
            backup_file="${backup_path}/${backup_filename}"
        fi
    fi

    if [[ ! -f "$backup_file" ]]; then
        echo "Error: Backup file not found: $backup_file" >&2
        return 1
    fi

    # 確認プロンプト
    echo "⚠️  WARNING: This will OVERWRITE the current database!"
    echo "Database: $db_database"
    echo "Backup file: $backup_file"
    echo -n "Are you sure? Type 'yes' to continue: "
    read confirmation

    if [[ "$confirmation" != "yes" ]]; then
        echo "Restore cancelled."
        return 0
    fi

    # デフォルトポート
    if [[ -z "$db_port" ]]; then
        db_port=$(_get_default_db_port "$db_type")
    fi

    # パスワード取得
    local password=$(_get_db_password "$project" "$db_name")

    echo "Restoring database from: $backup_file..."

    # DBタイプ別リストア
    local restore_success=0
    case "$db_type" in
        mysql)
            if [[ -n "$container_name" ]] && _is_container_running "$container_name"; then
                gunzip < "$backup_file" | docker exec -i "$container_name" mysql -u "$db_user" -p"$password" "$db_database"
            else
                if [[ -n "$password" ]]; then
                    gunzip < "$backup_file" | MYSQL_PWD="$password" mysql -h "$db_host" -P "$db_port" -u "$db_user" "$db_database"
                else
                    gunzip < "$backup_file" | mysql -h "$db_host" -P "$db_port" -u "$db_user" -p "$db_database"
                fi
            fi
            restore_success=$?
            ;;
        postgresql)
            if [[ -n "$container_name" ]] && _is_container_running "$container_name"; then
                gunzip < "$backup_file" | docker exec -i "$container_name" psql -U "$db_user" -d "$db_database"
            else
                if [[ -n "$password" ]]; then
                    gunzip < "$backup_file" | PGPASSWORD="$password" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_database"
                else
                    gunzip < "$backup_file" | psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_database"
                fi
            fi
            restore_success=$?
            ;;
        *)
            echo "Error: Restore not supported for DB type: $db_type" >&2
            return 1
            ;;
    esac

    if [[ $restore_success -eq 0 ]]; then
        echo "✅ Restore completed successfully"
    else
        echo "❌ Restore failed" >&2
        return 1
    fi
}

# ============================================
# Phase 3: Docker Management Functions
# ============================================

# Show database container status
# Usage: db-status [project-name]
db-status() {
    local project="${1:-$(basename $(pwd))}"

    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo "Error: $PROJECTS_FILE not found" >&2
        return 1
    fi

    echo "=== Docker Container Status: $project ==="
    echo ""

    local in_project=0
    local in_databases=0
    local db_name=""
    local container_name=""
    local found_any=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*${project}:$ ]]; then
            in_project=1
            continue
        fi

        if [[ $in_project -eq 1 && "$line" =~ ^[[:space:]]*[a-zA-Z0-9_-]+:$ && ! "$line" =~ databases: ]]; then
            break
        fi

        if [[ $in_project -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]+databases: ]]; then
                in_databases=1
                continue
            fi

            if [[ $in_databases -eq 1 ]]; then
                if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+name:[[:space:]]*(.*) ]]; then
                    if [[ -n "$db_name" && -n "$container_name" ]]; then
                        _print_container_status "$db_name" "$container_name"
                        found_any=1
                    fi
                    db_name="${match[1]}"
                    container_name=""
                elif [[ "$line" =~ ^[[:space:]]+container:[[:space:]]*(.*) ]]; then
                    container_name="${match[1]}"
                fi
            fi
        fi
    done < "$PROJECTS_FILE"

    # 最後のDBを処理
    if [[ -n "$db_name" && -n "$container_name" ]]; then
        _print_container_status "$db_name" "$container_name"
        found_any=1
    fi

    if [[ $found_any -eq 0 ]]; then
        echo "No Docker containers configured for this project"
    fi
}

# Helper: Print container status
_print_container_status() {
    local db_name="$1"
    local container="$2"

    if _is_container_running "$container"; then
        local uptime=$(docker ps --filter "name=$container" --format '{{.Status}}' 2>/dev/null)
        echo "[$db_name] $container"
        echo "  Status: ✅ Running ($uptime)"
    else
        # コンテナが存在するかチェック
        if docker ps -a --filter "name=$container" --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"; then
            echo "[$db_name] $container"
            echo "  Status: ⏸️  Stopped"
        else
            echo "[$db_name] $container"
            echo "  Status: ❌ Not found"
        fi
    fi
    echo ""
}

# Start database containers
# Usage: db-start [project-name] [db-name]
db-start() {
    local project="${1:-$(basename $(pwd))}"
    local target_db="${2:-}"

    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo "Error: $PROJECTS_FILE not found" >&2
        return 1
    fi

    local in_project=0
    local in_databases=0
    local db_name=""
    local container_name=""
    local compose_file=""
    local started=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*${project}:$ ]]; then
            in_project=1
            continue
        fi

        if [[ $in_project -eq 1 && "$line" =~ ^[[:space:]]*[a-zA-Z0-9_-]+:$ && ! "$line" =~ databases: ]]; then
            break
        fi

        if [[ $in_project -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]+databases: ]]; then
                in_databases=1
                continue
            fi

            if [[ $in_databases -eq 1 ]]; then
                if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+name:[[:space:]]*(.*) ]]; then
                    if [[ -n "$db_name" && -n "$container_name" ]]; then
                        if [[ -z "$target_db" || "$db_name" == "$target_db" ]]; then
                            _start_container "$db_name" "$container_name" "$compose_file"
                            ((started++))
                        fi
                    fi
                    db_name="${match[1]}"
                    container_name=""
                    compose_file=""
                elif [[ "$line" =~ ^[[:space:]]+container:[[:space:]]*(.*) ]]; then
                    container_name="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+compose_file:[[:space:]]*(.*) ]]; then
                    compose_file="${match[1]}"
                fi
            fi
        fi
    done < "$PROJECTS_FILE"

    # 最後のDBを処理
    if [[ -n "$db_name" && -n "$container_name" ]]; then
        if [[ -z "$target_db" || "$db_name" == "$target_db" ]]; then
            _start_container "$db_name" "$container_name" "$compose_file"
            ((started++))
        fi
    fi

    if [[ $started -eq 0 ]]; then
        echo "No containers to start" >&2
        return 1
    fi
}

# Helper: Start a container
_start_container() {
    local db_name="$1"
    local container="$2"
    local compose_file="$3"

    if _is_container_running "$container"; then
        echo "[$db_name] $container is already running ✅"
        return 0
    fi

    echo "Starting [$db_name] $container..."

    if [[ -n "$compose_file" ]]; then
        # docker-compose経由
        local compose_path="${compose_file}"
        if [[ ! -f "$compose_path" ]]; then
            # プロジェクトパスからの相対パスを試す
            local project_path=$(grep -A 5 "^[[:space:]]*${project}:" "$PROJECTS_FILE" | grep "path:" | sed 's/.*path:[[:space:]]*//' | head -1)
            project_path="${project_path/#\~/$HOME}"
            compose_path="${project_path}/${compose_file}"
        fi

        if [[ -f "$compose_path" ]]; then
            docker-compose -f "$compose_path" up -d "$container" 2>/dev/null
        else
            docker start "$container" 2>/dev/null
        fi
    else
        # 直接起動
        docker start "$container" 2>/dev/null
    fi

    if [[ $? -eq 0 ]]; then
        echo "  ✅ Started successfully"
    else
        echo "  ❌ Failed to start" >&2
    fi
}

# Stop database containers
# Usage: db-stop [project-name] [db-name]
db-stop() {
    local project="${1:-$(basename $(pwd))}"
    local target_db="${2:-}"

    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo "Error: $PROJECTS_FILE not found" >&2
        return 1
    fi

    local in_project=0
    local in_databases=0
    local db_name=""
    local container_name=""
    local stopped=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*${project}:$ ]]; then
            in_project=1
            continue
        fi

        if [[ $in_project -eq 1 && "$line" =~ ^[[:space:]]*[a-zA-Z0-9_-]+:$ && ! "$line" =~ databases: ]]; then
            break
        fi

        if [[ $in_project -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]+databases: ]]; then
                in_databases=1
                continue
            fi

            if [[ $in_databases -eq 1 ]]; then
                if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+name:[[:space:]]*(.*) ]]; then
                    if [[ -n "$db_name" && -n "$container_name" ]]; then
                        if [[ -z "$target_db" || "$db_name" == "$target_db" ]]; then
                            _stop_container "$db_name" "$container_name"
                            ((stopped++))
                        fi
                    fi
                    db_name="${match[1]}"
                    container_name=""
                elif [[ "$line" =~ ^[[:space:]]+container:[[:space:]]*(.*) ]]; then
                    container_name="${match[1]}"
                fi
            fi
        fi
    done < "$PROJECTS_FILE"

    # 最後のDBを処理
    if [[ -n "$db_name" && -n "$container_name" ]]; then
        if [[ -z "$target_db" || "$db_name" == "$target_db" ]]; then
            _stop_container "$db_name" "$container_name"
            ((stopped++))
        fi
    fi

    if [[ $stopped -eq 0 ]]; then
        echo "No containers to stop" >&2
        return 1
    fi
}

# Helper: Stop a container
_stop_container() {
    local db_name="$1"
    local container="$2"

    if ! _is_container_running "$container"; then
        echo "[$db_name] $container is not running ⏸️"
        return 0
    fi

    echo "Stopping [$db_name] $container..."
    docker stop "$container" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        echo "  ✅ Stopped successfully"
    else
        echo "  ❌ Failed to stop" >&2
    fi
}

# ============================================
# Phase 4: Security & Advanced Functions
# ============================================

# Set database password in environment
# Usage: db-set-password [project-name] [db-name]
db-set-password() {
    local project="${1:-$(basename $(pwd))}"
    local db_name="${2:-main}"

    # 環境変数名生成
    local env_var="${project^^}_DB_${db_name^^}_PASSWORD"
    env_var=$(echo "$env_var" | tr '-' '_')

    echo "Setting password for: $project / $db_name"
    echo "Environment variable: $env_var"
    echo ""
    echo -n "Enter password (input hidden): "
    read -s password
    echo ""
    echo -n "Confirm password: "
    read -s password_confirm
    echo ""

    if [[ "$password" != "$password_confirm" ]]; then
        echo "Error: Passwords do not match" >&2
        return 1
    fi

    # 現在のセッションに設定
    export "${env_var}=${password}"
    echo "✅ Password set for current session"
    echo ""
    echo "To persist across sessions, add to ~/.zshenv:"
    echo "  export ${env_var}='your-password'"
    echo ""
    echo "⚠️  Security note: Storing passwords in env files is convenient but less secure."
    echo "   Consider using a password manager or secret management tool."
}

# Test database connection
# Usage: db-test-connection [project-name] [db-name]
db-test-connection() {
    local project="${1:-$(basename $(pwd))}"
    local target_db="${2:-main}"

    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo "Error: $PROJECTS_FILE not found" >&2
        return 1
    fi

    # DB情報を取得
    local in_project=0
    local in_databases=0
    local db_name=""
    local db_type=""
    local db_host=""
    local db_port=""
    local db_database=""
    local db_user=""
    local container_name=""
    local found=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*${project}:$ ]]; then
            in_project=1
            continue
        fi

        if [[ $in_project -eq 1 && "$line" =~ ^[[:space:]]*[a-zA-Z0-9_-]+:$ && ! "$line" =~ databases: ]]; then
            break
        fi

        if [[ $in_project -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]+databases: ]]; then
                in_databases=1
                continue
            fi

            if [[ $in_databases -eq 1 ]]; then
                if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+name:[[:space:]]*(.*) ]]; then
                    if [[ -n "$db_name" && "$db_name" == "$target_db" ]]; then
                        found=1
                        break
                    fi
                    db_name="${match[1]}"
                    db_type=""
                    db_host=""
                    db_port=""
                    db_database=""
                    db_user=""
                    container_name=""
                elif [[ "$line" =~ ^[[:space:]]+type:[[:space:]]*(.*) ]]; then
                    db_type="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+host:[[:space:]]*(.*) ]]; then
                    db_host="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+port:[[:space:]]*(.*) ]]; then
                    db_port="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+database:[[:space:]]*(.*) ]]; then
                    db_database="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+user:[[:space:]]*(.*) ]]; then
                    db_user="${match[1]}"
                elif [[ "$line" =~ ^[[:space:]]+container:[[:space:]]*(.*) ]]; then
                    container_name="${match[1]}"
                fi
            fi
        fi
    done < "$PROJECTS_FILE"

    if [[ -n "$db_name" && "$db_name" == "$target_db" ]]; then
        found=1
    fi

    if [[ $found -eq 0 ]]; then
        echo "Error: Database '$target_db' not found for project '$project'" >&2
        return 1
    fi

    # デフォルトポート
    if [[ -z "$db_port" ]]; then
        db_port=$(_get_default_db_port "$db_type")
    fi

    # パスワード取得
    local password=$(_get_db_password "$project" "$db_name")

    echo "Testing connection to $db_type database..."
    echo "  Host: $db_host:$db_port"
    echo "  Database: $db_database"
    echo "  User: $db_user"
    echo ""

    # 接続テスト
    local test_success=0
    case "$db_type" in
        mysql)
            if [[ -n "$container_name" ]] && _is_container_running "$container_name"; then
                docker exec "$container_name" mysql -u "$db_user" -p"$password" -e "SELECT 1;" "$db_database" > /dev/null 2>&1
            else
                if [[ -n "$password" ]]; then
                    MYSQL_PWD="$password" mysql -h "$db_host" -P "$db_port" -u "$db_user" -e "SELECT 1;" "$db_database" > /dev/null 2>&1
                else
                    mysql -h "$db_host" -P "$db_port" -u "$db_user" -p -e "SELECT 1;" "$db_database" > /dev/null 2>&1
                fi
            fi
            test_success=$?
            ;;
        postgresql)
            if [[ -n "$container_name" ]] && _is_container_running "$container_name"; then
                docker exec "$container_name" psql -U "$db_user" -d "$db_database" -c "SELECT 1;" > /dev/null 2>&1
            else
                if [[ -n "$password" ]]; then
                    PGPASSWORD="$password" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_database" -c "SELECT 1;" > /dev/null 2>&1
                else
                    psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_database" -c "SELECT 1;" > /dev/null 2>&1
                fi
            fi
            test_success=$?
            ;;
        *)
            echo "Error: Connection test not supported for DB type: $db_type" >&2
            return 1
            ;;
    esac

    if [[ $test_success -eq 0 ]]; then
        echo "✅ Connection successful!"
    else
        echo "❌ Connection failed" >&2
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check if database is running (db-status $project)"
        echo "  2. Verify password is set (db-set-password $project $db_name)"
        echo "  3. Check network/firewall settings"
        return 1
    fi
}
