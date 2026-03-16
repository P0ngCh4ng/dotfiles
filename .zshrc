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

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
# Claude Code aliases
alias claude='cage -config "$HOME/.config/cage/presets.yaml" claude --dangerously-skip-permissions'  # With Cage wrapper
alias claude-raw='~/homebrew/bin/claude --dangerously-skip-permissions'  # Direct Claude Code (no Cage)
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
