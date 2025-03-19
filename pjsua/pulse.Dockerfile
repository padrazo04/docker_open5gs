FROM rockylinux:9 AS builder
ENV PULSE_COOKIE=/root/.config/pulse/cookie

RUN yum -y update && yum install -y wget
WORKDIR /var/tmp

# Requirements to build PJSUA. Installing only pulseaudio-utils to ensure that PJSUA can bind to pulseaudio client code
# but no pulseaudio server will be running in the container
RUN yum install -y gcc gcc-c++ make automake autoconf sudo git
RUN yum install -y alsa-lib alsa-lib-devel alsa-plugins-pulseaudio pulseaudio-utils
RUN yum install -y openssl-devel

# Install pjsua
RUN git clone https://github.com/pjsip/pjproject.git
RUN cd pjproject && \
    git fetch origin pull/4354/head:extra_aka && \
    git switch extra_aka && \
    git revert -n 7a302f27edb85c74c9a171383bfb561f9992291a && \
    echo -e "#define PJSIP_HAS_DIGEST_AKA_AUTH 1" > pjlib/include/pj/config_site.h && \
    export CFLAGS="$CFLAGS -fPIC -DPJMEDIA_CODEC_L16_HAS_8KHZ_MONO=1 -DPJMEDIA_CODEC_L16_HAS_8KHZ_STEREO=1 -DPJMEDIA_CODEC_L16_HAS_16KHZ_MONO=1 -DPJMEDIA_CODEC_L16_HAS_16KHZ_STEREO=1" && \
    ./configure && \
    make dep && \
    make && \
    make install
#    cp ./pjsip-apps/bin/pjsua-x86_64-unknown-linux-gnu /usr/bin/pjsua && \
#    cp ./pjsip-apps/bin/pjsystest-x86_64-unknown-linux-gnu /usr/bin/pjsystest

###
FROM rockylinux:9
COPY --from=builder /var/tmp/pjproject/pjsip-apps/bin/pjsua-x86_64-unknown-linux-gnu /usr/bin/pjsua
COPY --from=builder /var/tmp/pjproject/pjsip-apps/bin/pjsystest-x86_64-unknown-linux-gnu /usr/bin/pjsystest
COPY ./pulse-client.conf /etc/pulse/client.conf

RUN yum install -y alsa-lib alsa-plugins-pulseaudio
RUN yum install -y openssl vim-common
RUN export SNGREP_REPO_FILE=/etc/yum.repos.d/irontec.repo && \
    touch $SNGREP_REPO_FILE && \
    echo "[irontec]" >> $SNGREP_REPO_FILE && \
    echo "name=Irontec RPMs repository" >> $SNGREP_REPO_FILE && \
    echo "baseurl=http://packages.irontec.com/centos/8/x86_64/" >> $SNGREP_REPO_FILE && \
    rpm --import http://packages.irontec.com/public.key && \
    yum -y install sngrep
RUN rm -rf /var/cache/yum

# Enable EPEL
RUN dnf install -y dnf-plugins-core \
    && dnf config-manager --set-enabled crb \
    && dnf install -y epel-release \
    && rm -rf /var/cache/yum

COPY --chmod=755 ./pjsua.sh /pjsua.sh

ENTRYPOINT "./pjsua.sh"
