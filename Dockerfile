ARG ARCH

FROM ${ARCH}ossrs/node:18 AS node
FROM ${ARCH}ossrs/srs:ubuntu20 AS go
FROM ${ARCH}ossrs/srs:tools AS tools

# Usage:
# Build image:
#     docker build -t test .
# Note that should start with --privileged to run systemd.
#     docker run \
#         --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:rw --cgroupns=host \
#         -d --rm -it -v $(pwd):/g -w /g --name=install test
# Start a shell:
#     docker exec -it install /bin/bash

#FROM ubuntu:focal
# See https://hub.docker.com/r/jrei/systemd-ubuntu/tags
FROM ${ARCH}jrei/systemd-ubuntu:focal AS dist

ARG TARGETARCH

# Copy nodejs for ui build.
COPY --from=node /usr/local/bin /usr/local/bin
COPY --from=node /usr/local/lib /usr/local/lib
# Copy FFmpeg for tests.
COPY --from=tools /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /usr/local/bin/
# For build platform in docker.
COPY --from=go /usr/local/go /usr/local/go
ENV PATH=$PATH:/usr/local/go/bin

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ENV DEBIAN_FRONTEND=noninteractive

# To use if in RUN, see https://github.com/moby/moby/issues/7281#issuecomment-389440503
# Note that only exists issue like "/bin/sh: 1: [[: not found" for Ubuntu20, no such problem in CentOS7.
SHELL ["/bin/bash", "-c"]

# See https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#apt-get
# Note that we install docker.io because we don't use the docker plugin.
RUN apt update -y && apt-get install -y docker.io make \
    curl ffmpeg gdb gcc g++ wget vim tree python3 python3-venv \
    fonts-lato javascript-common libjs-jquery libruby2.7 libyaml-0-2 rake \
    ruby ruby-minitest ruby-net-telnet ruby-power-assert ruby-test-unit ruby-xmlrpc \
    ruby2.7 rubygems-integration unzip zip libcurl4 cmake libxslt-dev

RUN apt-get install -y libssl-dev xterm dpkg-dev gnupg gpg libfreetype-dev libfreetype6-dev libice-dev libice6 libxaw7 \
    pkg-config swig4.0 tcl tcl-dev tk tk8.6 x11-utils x11proto-dev xbitmaps libx11-dev libxau-dev libxdmcp-dev libxext-dev \
    libxft-dev libxrender-dev bzip2-doc libdb5.3++ libdb5.3++-dev libdb5.3-dev libipset13 libjpeg-turbo8-dev \
    libjpeg8-dev libpcap0.8 libpcap0.8-dev libpcre16-3 libpcre32-3 libpcrecpp0v5 libsm-dev libsqlite3-0 libxss-dev \
    libxt-dev tk8.6-dev x11proto-scrnsaver-dev distro-info-data debian-keyring automake autotools-dev libsigsegv2 m4 \
    re2c libzip5 bison-doc libfl-dev libfl2 gawk-doc libtinfo5 libncurses5-dev libltdl-dev libevent-2.1-7 \
    libevent-core-2.1-7 libevent-extra-2.1-7 libevent-openssl-2.1-7 libevent-pthreads-2.1-7 zlibc libsasl2-dev \
    libblkid-dev libblkid1 libglib2.0-bin libglib2.0-dev-bin libmount-dev libmount1 libpcre2-16-0 libpcre2-32-0 \
    libpcre2-dev libpcre2-posix2 libselinux1-dev libsepol1-dev libjpeg62 libjpeg-dev libjpeg-turbo8-dev libjpeg8-dev \
    comerr-dev krb5-multidev libgssrpc4 libkadm5clnt-mit11 libkadm5srv-mit11 libkdb5-9 libpq5 gettext-base libcroco3 \
    libcap-dev libc-client2007e libpam0g libpam0g-dev mlock psmisc libc-ares2 libgd-tools libjbig-dev libjpeg-dev \
    libjpeg-turbo8-dev libjpeg8-dev liblzma-dev libtiff-dev libtiffxx5 libvpx-dev libxpm-dev libwebpdemux2 \
    liblockfile-bin liblockfile1 lockfile-progs procmail sendmail-base sendmail-bin sensible-mda anacron logrotate \
    checksecurity libcurl4-doc libidn11-dev libkrb5-dev libldap2-dev librtmp-dev libssh2-1-dev readline-doc sqlite3-doc \
    swig-doc swig-examples ncompress tar-scripts tar-doc tk-doc rsyslog debian-archive-keyring

# See https://www.aapanel.com
# Note: We use very simple user `ossrs` and password `12345678` for local development environment, you should change it in production environment.
# Note: We disable the HTTPS by sed `SET_SSL=false` in install.sh. \
# You can also set the user and password as:
#    cd /www/server/panel && btpython -c 'import tools;tools.set_panel_username("ossrs")'
#    cd /www/server/panel && btpython -c 'import tools;tools.set_panel_pwd("12345678")'
RUN cd /tmp && \
    curl -o install.sh -sSL http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && \
    bash install.sh --port 7800 --user ossrs --password 12345678 -y --ssl-disable aapanel

# Enable the develop debug mode and reset some params.
RUN echo '/srsstack' > /www/server/panel/data/admin_path.pl && \
    echo 'True' > /www/server/panel/data/debug.pl

RUN cd /tmp && \
    echo "Install libs for aaPanel." && \
    curl -sSL https://node.aapanel.com/install/4/lib.sh |bash -s --

# Note: We install nginx 1.22 by default, like:
#       http://localhost:7800/plugin?action=install_plugin
#       sName=nginx&version=1.22&min_version=1&type=0
# Install from binary:
#       https://node.aapanel.com/install/4/nginx.sh
# Build from source:
#       https://node.aapanel.com/install/0/nginx.sh
RUN cd /tmp && \
    echo "Install NGINX for aaPanel." && \
    curl -sSL https://node.aapanel.com/install/0/nginx.sh |bash -s -- install 1.22
