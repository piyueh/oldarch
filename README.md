oldarch
=======

This repository contains scripts to create Docker images of Arch Linux that have
an old `glibc` (v2.23) and can be containerized on hosts running Linux kernel v2.6.
These Docker images can be pulled from Docker Hub 
(https://hub.docker.com/r/pychuang/oldarch), or built locally through the scripts.
Scripts for creating Singularity images can also be found in this repository.

Currently, all images are based on the Arch Linux snapshot on 2016-08-01.
The difference between the images is the packages installed.
The package repository URL in the images is fixed to the date of 2016-08-01.
This means `pacman -Syu` will not upgrade installed packages to newer versions.
However, `pacman -S <package>` can still be used to install packages that
exists on 2016-08-01.
AUR packages should work fine, as long as there're no dependencies that do not
exist on 2016-08-01.

## Warning: GPG keys and package verification

A problem I encounterd is the verification of packages. 
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
The base image is supposed to be used as the base layer of other images.

Another thing is that, to minimize the image size, all non-`en_US` locale files
are removed. 
All manpages, documentation, and GNU info files are also removed.

## Fancy base image

This version just adds vi, zsh, and zsh configurations to the base image. It
can be pulled from Docker Gub through:

```
$ docker pull pychuang/oldarch:fancybase20160801
```

The default shell is zsh.
And the version of zsh is 5.7.1-1, which is downloaded from lated archlinux
repository (as of 2019-12-05).
Also, the zsh configuration is global (hard-coded in `/etc/zsh/zshrc`) and is
tuned based on my personal preference.

The image can be built locally through (assuming the user has privilege 
to build/create images):

```
$ docker build -t oldarch:fancybase20160801 Dockerfile.fancybase .
```

## Deluxe image

This version adds more packages to `fancybase20160801` to meet my personal use:

1. termite-terminfo 11-3
2. git 2.9.2-1
3. vim 7.4.1910-1
4. python 3.5.2-1
5. python2 2.7.12-1
6. htop 2.0.2-1
7. wget 1.18-1
8. w3m 0.5.3.git20160413-1
9. imlib2 1.4.9-1

To pull the image from Docker Hub:

```
$ docker pull pychuang/oldarch:deluxe20160801
```

To build the image locally:

```
$ docker build -t oldarch:deluxe20160801 Dockerfile.deluxe .
```

## Image with PyTorch (v1.3.1 gpu version), h5py and miniconda

This image adds miniconda, PyTorch, and h5py to `fancybase20160801` image.
The whole python ecosystem in this image is provided by the miniconda installed,
and the base environment is activate by default no matter it's a login shell
or not.
Python version is 3.7.
The purpose of this image is to run things at remote HPC clusters, so the image
does not have any extra python package except the dependencies of miniconda, 
pytorch, and h5py.
Due to the cuda and mkl libraries, the image size is not trivial. So, be aware.

To pull the image from Docker Hub:

```
$ docker pull pychuang/oldarch:torchgpu20160801
```

To build the image locally:

```
$ docker build -t oldarch:torchgpu20160801 Dockerfile.conda .
```
