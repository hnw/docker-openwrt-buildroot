#!/bin/bash
set -e

SCRIPT_DIR=$(dirname $(readlink -e $0))
. ${SCRIPT_DIR}/utils.sh

BRANCH=$1

CACHE_BASE_DIR="${SCRIPT_DIR}/cache"
BUILDROOT_DIRNAME=source

if [[ ! -e ${HOME}/.ssh/config ]]; then
    echo "Copying .ssh/config ..."
    mkdir -p ${HOME}/.ssh/
    chmod 700 ${HOME}/.ssh/
    cp ${SCRIPT_DIR}/.ssh_config ${HOME}/.ssh/config
    chmod 600 ${HOME}/.ssh/config
fi

mkdir -p ${CACHE_BASE_DIR}/repos/${BRANCH}
cd ${CACHE_BASE_DIR}/repos/${BRANCH}

if [[ ! -d ${BUILDROOT_DIRNAME} ]]; then
    # shallow clone
    set_timer
    if [[ ${BRANCH} = "trunk" ]]; then
        git clone --depth 1 git://github.com/openwrt/openwrt.git ${BUILDROOT_DIRNAME}
    elif [[ ${BRANCH} = "lede-trunk" ]]; then
        git clone --depth 1 https://git.lede-project.org/source.git ${BUILDROOT_DIRNAME}
    elif [[ ${BRANCH} = "17.01" ]]; then
        git clone --depth 1 -b lede-17.01 https://git.lede-project.org/source.git ${BUILDROOT_DIRNAME}
    elif [[ ${BRANCH} = "15.05.1" ]]; then
        git clone --depth 1 -b chaos_calmer git://github.com/openwrt/openwrt.git ${BUILDROOT_DIRNAME}
    elif [[ ${BRANCH} = "14.07" ]]; then
        git clone --depth 1 -b barrier_breaker git://github.com/openwrt/openwrt.git ${BUILDROOT_DIRNAME}
    else
        rmdir ${CACHE_BASE_DIR}/repos/${BRANCH}
        die "ERROR: Unknown branch name: ${BRANCH}"
    fi
    success "Cloning buildroot finished. (elapsed time: $(time_elasped))"
fi

set_timer
cd ${BUILDROOT_DIRNAME}
git pull
success "Pulling buildroot finished. (elapsed time: $(time_elasped))"
