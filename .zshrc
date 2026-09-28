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

# Case-sensitive completion must be off. _ and - will be interchangeable. HYPHEN_INSENSITIVE="true"

# Accept suggestion with Ctrl+Space
bindkey '^ ' autosuggest-accept

# Accept one word at a time with Ctrl+→
bindkey '^[[1;5C' autosuggest-partial-accept

zstyle ':omz:update' mode reminder  # just remind me to update when it's time
zstyle ':omz:update' frequency 13 # how often to auto-update

COMPLETION_WAITING_DOTS="%F{magenta}⣾⣽⣻⢿%f"

plugins=(
	git
	zsh-autosuggestions
	fzf
	zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

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


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
