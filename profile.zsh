# Managed by dotfiles bootstrap. Linux counterpart to profile.ps1.
DOTFILES_ROOT="${0:A:h}"

[ -f "$DOTFILES_ROOT/.my_config.zsh" ] && source "$DOTFILES_ROOT/.my_config.zsh"

# fzf: Debian/Ubuntu package fd-find as "fdfind" to avoid a name clash.
if command -v fzf > /dev/null; then
    if command -v fdfind > /dev/null; then
        export FZF_DEFAULT_COMMAND="fdfind --type f --hidden --exclude .git"
    elif command -v fd > /dev/null; then
        export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
    fi
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# eza: override the ls family from .my_config.zsh when eza is available.
if command -v eza > /dev/null; then
    alias ls='eza --group-directories-first'
    alias ll='eza -la --icons --git --group-directories-first'
    alias la='eza -a --icons --group-directories-first'
    alias lt='eza --tree --level=2 --icons'
fi

command -v zoxide > /dev/null && eval "$(zoxide init zsh)"

OH_MY_POSH_THEME="$DOTFILES_ROOT/config/oh-my-posh/theme.json"
if command -v oh-my-posh > /dev/null && [ -f "$OH_MY_POSH_THEME" ]; then
    eval "$(oh-my-posh init zsh --config "$OH_MY_POSH_THEME")"
fi
