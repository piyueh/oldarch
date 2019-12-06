# Dockerfile.deluxe
#
# This Dockerfile creates an Arch Linux image with glibc 2.23 and some
# unnecessary but my personal preferred packages. See README for details. 
#
# Copyright © 2019 Pi-Yueh Chuang <pychuang@gwu.edu>
# Distributed under terms of the BSD 3-Clause license.

# base image
FROM pychuang/oldarch:fancybase20160801

# install
RUN pacman -Syy \
 && pacman -S --noconfirm git vim python python2 htop wget w3m imlib2 \
 && yes | pacman -Scc

CMD ["/bin/zsh"]

# vim:ft=dockerfile
