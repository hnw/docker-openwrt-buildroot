#!/bin/bash
set -e

SCRIPT_DIR=$(dirname $(readlink -e $0))
. ${SCRIPT_DIR}/utils.sh

export TERM=xterm
export COLOR=always

BRANCH=$1

CACHE_BASE_DIR="${SCRIPT_DIR}/cache"

if [[ ! -e ${HOME}/.ssh/config ]]; then
    echo "Copying .ssh/config ..."
    mkdir -p ${HOME}/.ssh/
    chmod 700 ${HOME}/.ssh/
    cp ${SCRIPT_DIR}/.ssh_config ${HOME}/.ssh/config
    chmod 600 ${HOME}/.ssh/config
fi

mkdir -p ${CACHE_BASE_DIR}/repos/${BRANCH}
cd ${CACHE_BASE_DIR}/repos/${BRANCH}

if [[ ! -d openwrt ]]; then
    # shallow clone
    set_timer
    if [[ ${BRANCH} = "trunk" ]]; then
        git clone --depth 1 https://github.com/openwrt/openwrt.git
    elif [[ ${BRANCH} = "15.05.1" ]]; then
        git clone --depth 1 -b chaos_calmer git://github.com/openwrt/openwrt.git
    elif [[ ${BRANCH} = "14.07" ]]; then
        git clone --depth 1 -b barrier_breaker https://github.com/openwrt/openwrt.git
    else
        rmdir ${CACHE_BASE_DIR}/repos/${BRANCH}
        die "ERROR: Unknown branch name: ${BRANCH}"
    fi
    success "Cloning 'openwrt' finished. (elapsed time: $(time_elasped))"
fi

cd openwrt
git pull
