#!/bin/bash

OPENWRT_VER=$1
ARCH=$2
PATCH_FILE="/work/patch/config.${ARCH}.patch"

[[ ! -e "${PATCH_FILE}" ]] && echo "ERROR: cannot access ${PATCH_FILE}" && exit 1

cd ${HOME}
if [[ "${OPENWRT_VER}" == "trunk" ]] ; then
    git clone git://github.com/openwrt/openwrt.git
elif [[ "${OPENWRT_VER}" == "15.05.1" ]] ; then
    git clone -b chaos_calmer git://github.com/openwrt/openwrt.git
elif [[ "${OPENWRT_VER}" == "14.07" ]] ; then
    git clone -b barrier_breaker git://github.com/openwrt/openwrt.git
else
    echo "ERROR: unknown version specified: ${OPENWRT_VER}" && exit 1   
fi
cd openwrt
scripts/feeds update -a
patch -p1 < "${PATCH_FILE}"
grep -v '^#' .config | uniq
CCACHE_DIR=staging_dir/host/ccache/ ccache -s
make prepare
CCACHE_DIR=staging_dir/host/ccache/ ccache -s
