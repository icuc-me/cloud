
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

export HOMEBIN="$HOME/bin"
export GOPATH="$HOME/go:/usr/lib/golang:/var/cache/go"
export GOBIN="$HOME/go/bin"
export SRCBIN="$SRC_DIR/bin"
export VARBIN="/var/cache/go/bin"
export LIBBIN="/usr/lib/golang/bin"
export PATH="$HOMEBIN:$GOBIN:$SRCBIN:$VARBIN:$LIBBIN:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
export EDITOR=/usr/bin/vim
export VIEWER=/usr/bin/vim
export SYSTEMD_LESS=FRXMK
export SYSTEMD_PAGER=less
