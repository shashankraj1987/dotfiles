# Managed by dotfiles bootstrap. Linux counterpart to profile.ps1.
DOTFILES_ROOT="${0:A:h}"

# The unattended installer keeps ~/.zshrc unchanged. Load Oh My Zsh here on
# fresh systems, while avoiding a second load when ~/.zshrc already sources it.
if [[ -f "${ZSH:-$HOME/.oh-my-zsh}/oh-my-zsh.sh" ]] && (( ! ${+functions[omz]} )); then
    export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
    ZSH_THEME="${ZSH_THEME:-robbyrussell}"
    source "$ZSH/oh-my-zsh.sh"
fi

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
