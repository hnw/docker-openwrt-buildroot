#!/bin/bash
set -e

BRANCH=$1
BOARD=$2
PATCH_FILE="/work/patch/config.${BRANCH}-${BOARD}.patch"

[[ ! -e ${PATCH_FILE} ]] && echo "ERROR: cannot access ${PATCH_FILE}" && exit 1

# Use TravisCI's ccache directory in build
if [[ -d ${HOME}/.ccache ]] ; then
    for dir in host ${TARGET} ${TOOLCHAIN}; do
        mkdir -p ${HOME}/.ccache/${dir}
        if [[ ! -d ${HOME}/openwrt/staging_dir/${dir} ]] ; then
            mkdir -p ${HOME}/openwrt/staging_dir/${dir}
        fi
        if [[ -e ${HOME}/openwrt/staging_dir/${dir}/ccache ]] ; then
            mv ${HOME}/openwrt/staging_dir/${dir}/ccache ${HOME}/openwrt/staging_dir/${dir}/ccache.orig
        fi
        ln -s ${HOME}/.ccache/${dir} ${HOME}/openwrt/staging_dir/${dir}/ccache
        CCACHE_DIR=${HOME}/.ccache/${dir} ccache -s | tee /tmp/ccache.${dir}.log
    done
fi

# Build toolchain
cd ${HOME}/openwrt
scripts/feeds update -a
patch -p1 < "${PATCH_FILE}"
make toolchain/install

# Cleanup
find build_dir \( -type l -or -type f \) -not -name '.*' -print0 | xargs -0 rm
find build_dir -type d -empty -delete
rm -f dl/{linux,u-boot}-*
for file in dl/* ; do
    mv ${file} ${file}.orig
    touch ${file} -r ${file}.orig
    rm ${file}.orig
done

# Show ccache status and remove them from image
for dir in host ${TARGET} ${TOOLCHAIN}; do
    if [[ -L ${HOME}/openwrt/staging_dir/${dir}/ccache ]] ; then
        echo "### ccache status (before build, ${dir}) ###"
        cat /tmp/ccache.${dir}.log
        echo ""
        echo "### ccache status (after build, ${dir}) ###"
        CCACHE_DIR=${HOME}/.ccache/${dir} ccache -s
        rm -f /tmp/ccache.${dir}.log
        rm -f ${HOME}/openwrt/staging_dir/${dir}/ccache
    fi
done
