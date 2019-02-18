
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

export HOMEBIN="$HOME/bin"
export GOPATH="$HOME/go:/usr/lib/golang:/var/cache/go"
export GOBIN="$GOPATH/bin"
export SRCBIN="$SRC_DIR/bin"
export PATH="/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$HOMEBIN:$GOBIN:$SRCBIN"
export EDITOR=/usr/bin/vim
export VIEWER=/usr/bin/vim
export SYSTEMD_LESS=FRXMK
export SYSTEMD_PAGER=less
