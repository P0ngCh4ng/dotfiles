[[ -o interactive ]] && echo "Brew and Zplug are required to run this script."
zstyle ":completion:*:commands" rehash 1
autoload -U zmv

# auto_ls
function chpwd(){
    if [[ $(pwd) != $HOME ]]; then;
                                  ls
    fi
}
autoload chpwd

# brewがない場合
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

    autoload -Uz compinit
    compinit -i
fi

if [ -e ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi

source $ZPLUG_HOME/init.zsh
source $HOME/dotfiles/opt.zsh

PROMPT='%F{034}%n%f %F{036}($(arch))%f:%F{020}%~%f $(git_super_status)'
PROMPT+=""$'\n'"%# "

alias ls='lsd'
alias l='lsd -l'
alias ll='lsd -l'
alias la='lsd -a'
alias lla='lsd -la'
alias lt='lsd --tree'

alias g='git'
alias ga='git add'
alias gd='git diff'
alias gs='git status'
alias gp='git push'
alias gb='git branch'
alias gst='git status'
alias gco='git checkout'
alias gf='git fetch'
alias gc='git commit'
gacp() { git add . && git commit -m "$1" && git push; }

# ============================================================
# Project Management Functions (Port Management)
# ============================================================

# projects.yml のパス
PROJECTS_FILE="$HOME/dotfiles/projects.yml"

# 現在使用中のportをスキャン
port-scan() {
    echo "Currently used ports:"
    lsof -iTCP -sTCP:LISTEN -n -P | awk 'NR>1 {print $9, $1}' | sed 's/.*://' | sort -n | uniq
}

# projects.ymlから全プロジェクトのport情報を表示
check-ports() {
    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo "Error: $PROJECTS_FILE not found" >&2
        return 1
    fi

    echo "=== Project Port Assignments ==="
    echo ""

    # 使用中のportを取得
    local used_ports=$(lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | awk 'NR>1 {print $9}' | sed 's/.*://' | sort -n | uniq)

    # projects.ymlをパース（シンプル実装）
    local current_project=""
    while IFS= read -r line; do
        # プロジェクト名を取得
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z0-9_-]+):$ ]]; then
            current_project="${match[1]}"
            if [[ "$current_project" != "projects" ]]; then
                echo "📦 $current_project"
            fi
        fi

        # portsを取得
        if [[ "$line" =~ ports:[[:space:]]*\[([0-9, ]+)\] ]]; then
            local ports="${match[1]}"
            # ポートごとにチェック
            for port in ${(s:,:)ports}; do
                port=$(echo $port | tr -d ' ')
                if echo "$used_ports" | grep -q "^${port}$"; then
                    echo "  🔴 Port $port (IN USE)"
                else
                    echo "  🟢 Port $port (available)"
                fi
            done
        fi
    done < "$PROJECTS_FILE"
}

# プロジェクト情報を表示
pj-info() {
    if [[ -z "$1" ]]; then
        echo "Usage: pj-info <project-name>"
        echo ""
        echo "Available projects:"
        grep -E '^[[:space:]]*[a-zA-Z0-9_-]+:$' "$PROJECTS_FILE" | sed 's/://g' | sed 's/^[[:space:]]*/  - /' | grep -v 'projects'
        return 1
    fi

    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo "Error: $PROJECTS_FILE not found" >&2
        return 1
    fi

    local project_name="$1"
    local in_project=0
    local in_databases=0
    local db_count=0

    echo "=== Project: $project_name ==="

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*${project_name}:$ ]]; then
            in_project=1
            continue
        fi

        if [[ $in_project -eq 1 ]]; then
            # 次のプロジェクトが始まったら終了
            if [[ "$line" =~ ^[[:space:]]*[a-zA-Z0-9_-]+:$ && ! "$line" =~ databases: ]]; then
                break
            fi

            # databases セクション開始
            if [[ "$line" =~ ^[[:space:]]+databases: ]]; then
                in_databases=1
                continue
            fi

            # databases セクション内
            if [[ $in_databases -eq 1 ]]; then
                if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+name:[[:space:]]*(.*) ]]; then
                    ((db_count++))
                fi
                continue
            fi

            # 基本情報を表示
            if [[ "$line" =~ path:[[:space:]]*(.*) ]]; then
                echo "Path: ${match[1]}"
            elif [[ "$line" =~ ports:[[:space:]]*\[(.*)\] ]]; then
                echo "Ports: ${match[1]}"
            elif [[ "$line" =~ description:[[:space:]]*\"(.*)\" ]]; then
                echo "Description: ${match[1]}"
            elif [[ "$line" =~ tech:[[:space:]]*\[(.*)\] ]]; then
                echo "Tech: ${match[1]}"
            fi
        fi
    done < "$PROJECTS_FILE"

    # DB情報を表示
    if [[ $db_count -gt 0 ]]; then
        echo "Databases: $db_count configured"
        echo ""
        echo "Run 'db-list $project_name' for database details"
        echo "Run 'db-info $project_name' for full database information"
    fi
}

# ============================================
# Database Management Functions (sourced from db.zsh)
# ============================================
[[ -f "$HOME/dotfiles/db.zsh" ]] && source "$HOME/dotfiles/db.zsh"

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
# Claude Code aliases
alias claude='CLAUDE_CODE_DISABLE_ITERM2=1 cage -config "$HOME/.config/cage/presets.yaml" claude --dangerously-skip-permissions'  # With Cage wrapper
alias claude-raw='CLAUDE_CODE_DISABLE_ITERM2=1 ~/homebrew/bin/claude --dangerously-skip-permissions'  # Direct Claude Code (no Cage)
zplug 'zsh-users/zsh-autosuggestions'
zplug 'zsh-users/zsh-completions'
zplug 'zsh-users/zsh-syntax-highlighting'
zplug "zsh-users/zsh-history-substring-search"
zplug "woefe/git-prompt.zsh"
# 未インストール項目をインストールする
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# コマンドをリンクして、PATH に追加し、プラグインは読み込む
zplug load --verbose


[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env"# ghcup-env export PATH="/opt/homebrew/opt/llvm/bin:$PATH"


# Added by Antigravity
export PATH="/Users/pongchang/.antigravity/antigravity/bin:$PATH"
