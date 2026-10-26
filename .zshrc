# Path to Oh My Zsh installation.
export ZSH="$HOME/.local/oh-my-zsh"

# Path to local scripts
export PATH="$HOME/.local/bin:$PATH"

# XDG-Compliant path for zsh's auto completion cache
export ZSH_COMPDUMP="$HOME/.cache/zsh/zcompdump-$HOST-$ZSH_VERSION"

# XDG-Compliant path for zsh's history file
export HISTFILE="$HOME/.local/state/zsh/history"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="kiwi" #Can also do 'random'

zstyle ':omz:update' mode reminder  
zstyle ':omz:update' frequency 13 

COMPLETION_WAITING_DOTS="%F{magenta}⣾⣽⣻⢿%f"

plugins=(
	git
	zsh-autosuggestions
	fzf
	zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Key Bindings 
bindkey '^ ' autosuggest-accept #Ctrl+Space: accept suggestion
bindkey '^[[1;5C' autosuggest-partial-accept #Ctrl+→: accept one word

ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste accept-line)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6C7A89,italic"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=white"

HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# XDG-Compliant GO path (default is ~/go)
export GOPATH="$HOME/.local/share/go"

# XDG-Compliant paths for Rust (default is ~/.cargo and ~/.rustup)
export CARGO_HOME="$HOME/.local/share/cargo"
export RUSTUP_HOME="$HOME/.local/share/rustup"
export PATH="$HOME/.local/share/cargo/bin:$PATH"

# XDG-Compliant path for npm's cache directory ( default is ~/.npm)
export NPM_CONFIG_CACHE="$HOME/.cache/npm"

alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias ldot='lazygit --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# fastfetch: small.jsonc in narrow terminals, full.jsonc otherwise;
fastfetch() {
    local dir=~/.config/fastfetch
    if [[ " $* " == *" -c "* || " $* " == *" --config "* ]]; then
        command fastfetch "$@"
    elif (( COLUMNS < 75 )); then
        command fastfetch -c $dir/small.jsonc "$@"
    else
        command fastfetch -c $dir/full.jsonc "$@"
    fi
}
alias ff='fastfetch'
alias ffs='fastfetch -c ~/.config/fastfetch/small.jsonc'


# --- play <game> [-g]: run a Windows game from /mnt/hdd/Games/installs via umu ---
play() {
    local root=/mnt/hdd/Games
    local game=$1 gpu=()
    [[ $2 == -g ]] && gpu=(prime-run)
    local dir=$root/installs/$game
    if [[ -z $game || ! -d $dir ]]; then
        print "usage: play <game> [-g]\ngames:"; ls -1 $root/installs
        return 1
    fi

    # which exe starts this game? remembered in <game>/.play-exe after the first run
    local exe
    if [[ -f $dir/.play-exe ]]; then
        exe=$(<$dir/.play-exe)
    else
        local -a exes
        exes=( ${(f)"$(cd $dir && find -L . -iname '*.exe' \
            ! -iname 'unins*' ! -iname '*crash*' ! -iname '*setup*' \
            ! -ipath '*redist*' ! -ipath '*directx*' | sed 's|^\./||' | sort)"} )
        if (( ${#exes} == 0 )); then
            print "no .exe found in $dir"; return 1
        elif (( ${#exes} == 1 )); then
            exe=$exes[1]
        else
            print "Which exe starts $game?"
            select exe in $exes; do [[ -n $exe ]] && break; done
        fi
        print -r -- $exe > $dir/.play-exe
    fi

    (
        cd "$dir/${exe:h}" || exit 1
        WINEPREFIX="$root/prefixes/$game" GAMEID=0 "${gpu[@]}" umu-run "${exe:t}"
    )
}

# tab-complete game folders for `play`
_play() { _files -W /mnt/hdd/Games/installs -/ }
compdef _play play


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
