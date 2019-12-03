oldarch
=======

This repository contains scripts to create Docker images of Arch Linux that have
old `glibc` (v2.23) and can be containerized on hosts running Linux kernel v2.6.
These Docker images can be pulled from Docker Hub 
(https://hub.docker.com/r/pychuang/oldarch), or built locally through the scripts.
Scripts for creating Singularity images can also be found in this repository.

Currently, all images are based on the Arch Linux sanpshot on 2016-08-01.
The difference between images is the packages installed.
The package repository URL in the images is fixed to the date of 2016-08-01.
This means `pacman -Syu` will not upgrade installed packages to newer versions.
However, `pacman -S <package>` can still be used to install packages that
exists on 2016-08-01.
AUR package should work fine, as long as there're no dependencies that do not
exist on 2016-08-01.

## Warning: GPG keys and package verification

A problem I encounterd during is the verification of packages. 
Many keys in `pacman`'s keyring are expired now due that the snapshot comes 
from two years ago.
A normal process to deal with the issue is to refresh the keys from key servers
and then sign or utimately trust the keys.
However, the internet connections to most GPG key servers are unstable.
Sometimes the key refreshing process just hangs there due to unresponsive key
servers.
So I also added the refreshed keys and the ownertrust file in this repository.
And the script creating the base image always imports the updated key locally.

That is to say, the keys for package verification in the Docker images are not
directly fetched from key servers, and they are not in their original trust level.
Use with your own risk.

If you don't trust me, alternatively, you can modify the `run.sh` to refresh the
keys from key servers by:

```
# pcaman-key --refresh-keys
```


and then ultimately trust the keys with:

```
# gpg --homedir /etc/pacman.d/gnupg --list-keys --fingerprint | \
     grep pub -A 1 | \
     egrep -Ev "pub|--" | \
     tr -d ' ' | \
     awk 'BEGIN { FS = "\n" } ; { print $1":6:" } ' | \
     gpg --homedir /etc/pacman.d/gnupg --import-ownertrust
```

## Base image

The base image can be pulled from Docker Hub through
(assuming that the user has permission to create Docker images/containers):

```
$ docker pull pychuang/oldarch:base20160801
```

Alternatively, the script `run.sh` can be used to create a local base image.
Run the script with root privilege:

```
# sh ./run.sh
```

At the end of the process, a local Docker image `oldarch:base20160801` will be
created. Users should be able to see the image through:

```
$ docker image ls
```

This base image does not have many utilities. It only has core utilities suggested
by [this Arch Wiki page](https://wiki.archlinux.org/index.php/Core_utilities).
The base image is supposed to be used as the base bootstrap for other image.

Another thing is that, to minimizet the image size, all non-`en_US` locale files
are removed. 
All manpages, documentation, and GNU info files are also removed.
