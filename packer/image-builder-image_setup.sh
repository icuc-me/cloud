#!/bin/bash

# This script is called by packer on a vanilla CentOS VM, to prepare it
# for use in building additional GCE images. It's not intended to be used
# outside of this context.

set -e

echo "Updating packages"
sudo yum -y update

echo "Configuring repositories"
sudo yum -y install epel-release

echo "Installing packages"
ooe.sh sudo yum -y install \
    genisoimage \
    libvirt \
    libvirt-admin \
    libvirt-client \
    libvirt-daemon \
    make \
    python36 \
    python36-PyYAML \
    qemu-img \
    qemu-kvm \
    qemu-kvm-tools \
    qemu-user \
    rsync \
    rng-tools \
    unzip \
    util-linux \
    vim

echo "Enabling rngd service for reliable booting"
sudo systemctl enable rngd

echo "Link qemu-kvm binary into \$PATH directory"
sudo ln -s /usr/libexec/qemu-kvm /usr/bin/

echo "Enable nested-virtualization"
sudo tee /etc/modprobe.d/kvm-nested.conf <<EOF
options kvm-intel nested=1
options kvm-intel enable_shadow_vmcs=1
options kvm-intel enable_apicv=1
options kvm-intel ept=1
EOF

echo "Cleaning up"
cd /
PKG=$(type -P dnf || type -P yum || echo "")
sudo $PKG clean all
sudo rm -rf /var/cache/{yum,dnf}
sudo rm -f /etc/udev/rules.d/*-persistent-*.rules
sudo rm -rf /var/lib/cloud/instanc*
sudo rm -rf /root/.ssh/*
sudo rm -rf /home/*
sudo rm -rf /tmp/*
sudo rm -rf /tmp/.??*
sudo rm -rf /var/tmp/*
sudo rm -rf /var/tmp/.??*
sudo sync
sudo fstrim -av
sudo touch /.unconfigured  # force firstboot to run

echo "SUCCESS!"
