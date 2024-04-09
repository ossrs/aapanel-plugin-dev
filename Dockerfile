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

# See https://www.aapanel.com
# Note: We use very simple user `ossrs` and password `12345678` for local development environment, you should change it in production environment.
# Note: We disable the HTTPS by sed `SET_SSL=false` in install.sh.
RUN cd /tmp && \
    wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && \
    sed -i 's/^    Set_Ssl/    #Set_Ssl/g' install.sh && \
    env panelPort=7800 go=y bash install.sh aapanel

# Enable the develop debug mode and reset some params.
RUN echo '/srsstack' > /www/server/panel/data/admin_path.pl && \
    echo 'True' > /www/server/panel/data/debug.pl && \
    cd /www/server/panel && btpython -c 'import tools;tools.set_panel_username("ossrs")' && \
    cd /www/server/panel && btpython -c 'import tools;tools.set_panel_pwd("12345678")'

RUN cd /tmp && \
    echo "Install libs for aaPanel." && \
    curl -sSL https://node.aapanel.com/install/4/lib.sh |bash -s --

# Note: We install nginx 1.22 by default, like:
#       http://localhost:7800/plugin?action=install_plugin
#       sName=nginx&version=1.22&min_version=1&type=1
RUN cd /tmp && \
    echo "Install NGINX for aaPanel." && \
    curl -sSL https://node.aapanel.com/install/4/nginx.sh |bash -s -- install 1.22
