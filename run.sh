#! /bin/sh
#
# Copyright © 2019 Pi-Yueh Chuang <pychuang@gwu.edu>
# Distributed under terms of the MIT license.
#
# Credit: https://github.com/moby/moby/blob/master/contrib/mkimage-arch.sh
#
# Require arch-install-scripts from Arch Linux on the host

# stop script when error happens
set -e

# version/date
DATE="2016.08.01"

# the URLs
BASEURL="https://archive.archlinux.org"
ISOURL="$BASEURL/iso/$DATE"
REPOURL="$BASEURL/repos/$(echo $DATE | sed 's/\./\//g')"

# filename
BOOTSTRAP="archlinux-bootstrap-$DATE-x86_64.tar.gz"

# some alias; we use host's arch-chroot, instead of chroot's arch-chroot
ROOTFS="mnt"
CHROOT="arch-chroot $ROOTFS"

# some core utilities beside bash pacman coreutils findutils util-linux glibc
PKGREQUIRED=(tar less diffutils grep sed gawk procps-ng binutils gzip which)
PKGREQUIRED=${PKGREQUIRED[*]}

# packages that will be removed later
PKGREMOVE=(
    arch-install-scripts systemd iptables libmnl libnftnl dbus libdbus kbd 
    kmod libelf libseccomp hwids)
PKGREMOVE=${PKGREMOVE[*]}

# download the bootstrap and signature for verification
wget -c $ISOURL/$BOOTSTRAP
wget -c $ISOURL/$BOOTSTRAP.sig

# verify the signature using host's pacman keyring.
pacman-key --verify $BOOTSTRAP.sig

# Extract
tar -xf $BOOTSTRAP

# bind to a mountpoint so we can use host's arch-chroot
if [ ! -d "$ROOTFS" ]; then
    mkdir $ROOTFS
fi
mount --bind root.x86_64 $ROOTFS

# fix the repository mirror to a fixed-date snapshot.
echo "Server = $REPOURL/\$repo/os/\$arch" > $ROOTFS/etc/pacman.d/mirrorlist

# update arch pub keys; take your own risk ...
$CHROOT rm -rf /etc/pacman.d/gnupg
$CHROOT pacman-key --init
cp -r keys $ROOTFS/root
$CHROOT gpg --homedir=/etc/pacman.d/gnupg --import /root/keys/archkeys-$DATE.asc
$CHROOT gpg --homedir=/etc/pacman.d/gnupg --import-ownertrust /root/keys/archkeys-ownertrust-$DATE.txt
$CHROOT pacman -Syy --noconfirm
$CHROOT rm -r /root/keys

# install basic packages
$CHROOT pacman -S --noconfirm $PKGREQUIRED

# locale: en_US.UTF-8
echo "en_US.UTF-8 UTF-8" > $ROOTFS/etc/locale.gen
$CHROOT locale-gen
echo "LANG=en_US.UTF-8" > $ROOTFS/etc/locale.conf

# timezone: always UTC
ln -sf $ROOTFS/usr/share/zoneinfo/UTC $ROOTFS/etc/localtime

# remove unnecessary packages
$CHROOT pacman -Rnu --noconfirm $PKGREMOVE

# clean tarbals to save space
expect <<EOF
spawn $CHROOT pacman -Scc
expect -exact "ALL files from cache? \[y\/N\] "
send -- "y\r"
expect -exact "unused repositories? \[Y\/n\] "
send -- "y\r"
expect eof
EOF

# clean man pages and non-en locale files
rm -r $ROOTFS/usr/share/man/*
rm -r $ROOTFS/usr/share/doc/*
rm -r $ROOTFS/usr/share/info/*
mv $ROOTFS/usr/share/locale/en_US $ROOTFS/root
mv $ROOTFS/usr/share/locale/locale.alias $ROOTFS/root
rm -r $ROOTFS/usr/share/locale/*
mv $ROOTFS/root/* $ROOTFS/usr/share/locale
mv $ROOTFS/usr/share/zoneinfo/UTC $ROOTFS/root
rm -r $ROOTFS/usr/share/zoneinfo/*
mv $ROOTFS/root/UTC $ROOTFS/usr/share/zoneinfo

# umount the mountpoint; after this point, we can not use $CHROOT anymore
sync && umount -R $ROOTFS && sync

# udev doesnt work in containers, rebuild /dev
rm -rf root.x86_64/dev
mkdir -p  root.x86_64/dev
mknod -m 666 root.x86_64/dev/null c 1 3
mknod -m 666 root.x86_64/dev/zero c 1 5
mknod -m 666 root.x86_64/dev/random c 1 8
mknod -m 666 root.x86_64/dev/urandom c 1 9
mkdir -m 755 root.x86_64/dev/pts
mkdir -m 1777 root.x86_64/dev/shm
mknod -m 666 root.x86_64/dev/tty c 5 0
mknod -m 600 root.x86_64/dev/console c 5 1
mknod -m 666 root.x86_64/dev/tty0 c 4 0
mknod -m 666 root.x86_64/dev/full c 1 7
mknod -m 600 root.x86_64/dev/initctl p
mknod -m 666 root.x86_64/dev/ptmx c 5 2
ln -sf /proc/self/fd root.x86_64/dev/fd
sync

# make a docker image locally
IMGNAME="oldarch:base$(echo $DATE | sed 's/\.//g')"
tar --numeric-owner --xattrs --acls -C root.x86_64 -c . | docker import - $IMGNAME

# return a success message from inside Docker container
docker run --rm=true -t $IMGNAME echo Success.

# remove files
rm $BOOTSTRAP
rm $BOOTSTRAP.sig
rm -rf $ROOTFS
rm -rf root.x86_64
