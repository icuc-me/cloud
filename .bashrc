# .bashrc - intended for use by bin/devel.sh

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

export PATH="/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/home/$USER/go/bin"
