#! /bin/sh
#
# Distributed under terms of the MIT license.
#
# Credit: https://github.com/moby/moby/blob/master/contrib/mkimage-arch.sh
#
# Require arch-install-scripts from Arch Linux

# version/date
DATE="2016.08.01"

# the URLs
BASEURL="https://archive.archlinux.org"
ISOURL="$BASEURL/iso/$DATE"
REPOURL="$BASEURL/repos/$(echo $DATE | sed 's/\./\//g')"

# filename
BOOTSTRAP="archlinux-bootstrap-$DATE-x86_64.tar.gz"

# some alias
ROOTFS="root.x86_64"
CHROOT="$ROOTFS/bin/arch-chroot $ROOTFS"

# packages that must present in chroot
PKGREQUIRED=(
    bash zsh base-devel haveged pacman pacman-mirrorlist vim bzip2 coreutils 
    device-mapper wget curl)
PKGREQUIRED=${PKGREQUIRED[*]}

# download the bootstrap and signature for verification
wget -c $ISOURL/$BOOTSTRAP
wget -c $ISOURL/$BOOTSTRAP.sig

# verify the signature using host's pacman keyring.
pacman-key --verify $BOOTSTRAP.sig

# Extract
tar -xf $BOOTSTRAP

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

# clean tarbals to save space
expect <<EOF
spawn $CHROOT pacman -Scc
expect -exact "ALL files from cache? \[y\/N\] "
send -- "y\r"
expect -exact "unused repositories? \[Y\/n\] "
send -- "y\r"
expect eof
EOF

# udev doesnt work in containers, rebuild /dev
rm -rf $ROOTFS/dev
mkdir -p  $ROOTFS/dev
mknod -m 666 $ROOTFS/dev/null c 1 3
mknod -m 666 $ROOTFS/dev/zero c 1 5
mknod -m 666 $ROOTFS/dev/random c 1 8
mknod -m 666 $ROOTFS/dev/urandom c 1 9
mkdir -m 755 $ROOTFS/dev/pts
mkdir -m 1777 $ROOTFS/dev/shm
mknod -m 666 $ROOTFS/dev/tty c 5 0
mknod -m 600 $ROOTFS/dev/console c 5 1
mknod -m 666 $ROOTFS/dev/tty0 c 4 0
mknod -m 666 $ROOTFS/dev/full c 1 7
mknod -m 600 $ROOTFS/dev/initctl p
mknod -m 666 $ROOTFS/dev/ptmx c 5 2
ln -sf /proc/self/fd $ROOTFS/dev/fd

# make a docker image locally
tar --numeric-owner --xattrs --acls -C $ROOTFS -c .  | docker import - pychuang/oldarch:$DATE

# return a success message from inside Docker container
docker run --rm=true -t pychuang/oldarch:$DATE echo Success.

# remove files
rm $BOOTSTRAP
rm $BOOTSTRAP.sig
rm -rf $ROOTFS
