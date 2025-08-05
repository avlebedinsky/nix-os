# ~/.config/fish/config.fish
# Конфигурация Fish shell для NixOS + Hyprland

# Установка переменных окружения
set -x EDITOR nano
set -x BROWSER firefox
set -x TERMINAL kitty

# Wayland переменные
set -x QT_QPA_PLATFORM wayland
set -x GDK_BACKEND wayland
set -x MOZ_ENABLE_WAYLAND 1
set -x XDG_SESSION_TYPE wayland
set -x XDG_CURRENT_DESKTOP Hyprland

# Алиасы для удобства
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"
alias ..="cd .."
alias ...="cd ../.."
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

# NixOS специфичные алиасы
alias rebuild="sudo nixos-rebuild switch"
alias rebuild-test="sudo nixos-rebuild test"
alias rebuild-boot="sudo nixos-rebuild boot"
alias nix-clean="sudo nix-collect-garbage -d"
alias nix-search="nix search nixpkgs"

# Git алиасы
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline"
alias gd="git diff"

# Системные алиасы
alias ports="netstat -tulanp"
alias mkdir="mkdir -pv"
alias h="history"
alias j="jobs -l"
alias mount="mount | column -t"
alias path='echo -e $PATH | tr ":" "\n"'
alias now="date +'%T'"
alias nowtime=now
alias nowdate="date +'%d-%m-%Y'"

# Hyprland специфичные алиасы
alias hypr-reload="hyprctl reload"
alias hypr-restart="pkill -USR1 hyprland"
alias waybar-reload="pkill -USR2 waybar"

# Инициализация Starship prompt
if command -v starship > /dev/null
    starship init fish | source
end

# Автодополнение для Nix
if test -f ~/.nix-profile/share/bash-completion/completions/nix
    complete -c nix -w nix
end

# Функции
function backup
    set timestamp (date +%Y%m%d_%H%M%S)
    cp -r $argv[1] "$argv[1]_backup_$timestamp"
    echo "Backup created: $argv[1]_backup_$timestamp"
end

function extract
    switch $argv[1]
        case "*.tar.bz2"
            tar xjf $argv[1]
        case "*.tar.gz"
            tar xzf $argv[1]
        case "*.bz2"
            bunzip2 $argv[1]
        case "*.rar"
            rar x $argv[1]
        case "*.gz"
            gunzip $argv[1]
        case "*.tar"
            tar xf $argv[1]
        case "*.tbz2"
            tar xjf $argv[1]
        case "*.tgz"
            tar xzf $argv[1]
        case "*.zip"
            unzip $argv[1]
        case "*.Z"
            uncompress $argv[1]
        case "*"
            echo "Unknown archive format"
    end
end

function mkcd
    mkdir -p $argv[1] && cd $argv[1]
end

# Приветствие при запуске
echo "🚀 NixOS + Hyprland готов к работе!"
echo "Используйте 'rebuild' для пересборки системы"
echo "Используйте 'nix-search <пакет>' для поиска пакетов"
