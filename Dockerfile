FROM ubuntu:xenial

RUN apt-get update &&\
    apt-get install -y git-core subversion wget bzip2 unzip \
                       build-essential gcc-multilib flex ccache \
                       libncurses5-dev zlib1g-dev libssl-dev gettext \
                       python gawk sudo groff-base &&\
    apt-get remove -y openssh-client manpages manpages-dev krb5-locales locales &&\
    apt-get -y autoremove &&\
    apt-get clean &&\
    useradd -m openwrt &&\
    echo 'openwrt ALL=NOPASSWD: ALL' > /etc/sudoers.d/openwrt &&\
    sudo -iu openwrt git clone git://git.openwrt.org/15.05/openwrt.git &&\
    sudo -iu openwrt openwrt/scripts/feeds update -a
#    sudo -iu openwrt ln -s ../feeds/base/package/utils openwrt/package/utils
# see: https://dev.openwrt.org/ticket/18552
