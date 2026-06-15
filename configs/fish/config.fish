# PATH
fish_add_path ~/.local/bin ~/bin

# eza — colored ls with icons
alias ls='eza --icons --group-directories-first --color=always'
alias ll='eza --icons --group-directories-first --color=always -lh --git'
alias la='eza --icons --group-directories-first --color=always -lha --git'
alias tree='eza --icons --tree --color=always'

# bat — syntax-highlighted cat
alias cat='bat --pager=never'
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

# grep / diff with color
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# delta — syntax-highlighted git diffs
set -gx GIT_PAGER delta

# lazygit
alias lg='lazygit'

# Gamescope — 2560x1440 @ 165Hz, RT scheduling, async flips, MangoApp overlay
alias gcs2='gamescope -W 2560 -H 1440 -r 165 --rt --immediate-flips --mangoapp -e --'

# scripts
alias rice="$HOME/scripts/rice-start.sh"
alias sysinfo="$HOME/scripts/sysinfo.sh"

# zoxide — smart cd
zoxide init fish | source

# mise — runtime version manager
~/.local/bin/mise activate fish 2>/dev/null | source

# Starship prompt
starship init fish | source
