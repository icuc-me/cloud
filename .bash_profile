# .bash_profile - intended for use by bin/devel.sh

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export GOSRC="/home/$USER/go/src/github.com/icuc-me/cloud/"
export PATH="/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$HOME/bin:$GOBIN"
export EDITOR=/usr/bin/vim
export VIEWER=/usr/bin/vim
export SYSTEMD_LESS=FRXMK
export SYSTEMD_PAGER=less
