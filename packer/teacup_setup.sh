#!/bin/bash

set -ex

cleanup(){
    set +e  # Don't fail at the very end
    # Allow root ssh-logins
    if [[ -r /etc/cloud/cloud.cfg ]]
    then
        sudo sed -re 's/^disable_root:.*/disable_root: 0/g' -i /etc/cloud/cloud.cfg
    fi
    PKG=$(type -P dnf || type -P yum || echo "")
    sudo $PKG clean all
    cat <<EOF | sudo at -M now
cd /
sleep 10s
userdel -fr $USER
rm -rf /var/cache/{yum,dnf}
rm -f /etc/udev/rules.d/*-persistent-*.rules
rm -rf /var/lib/cloud/instance?
rm -rf /root/.ssh/*
rm -rf /tmp/.??*
rm -rf "$SRC_DIR"
rm -rf /tmp/*
touch /.unconfigured  # force firstboot to run
sync
fstrim -av
EOF
}

source "$SRC_DIR/bin/lib.sh"

sudo yum update -y
sudo yum install -y epel-release centos-release-scl
sudo cp "$SRC_DIR/packer/google-cloud-sdk.repo" /etc/yum.repos.d/
sudo yum install -y $(cat "$SRC_DIR/packer/centos.packages")
sudo cp "$SRC_DIR/packer/git" /usr/bin/git
sudo chmod 755 /usr/bin/git
