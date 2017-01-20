#!/bin/bash
set -e

BRANCH=$1
BOARD=$2

SCRIPT_DIR=$(dirname $(readlink -e $0))
PATCH_FILE="${SCRIPT_DIR}/patch/${BRANCH}-${BOARD}.patch"
CACHE_BASE_DIR="${SCRIPT_DIR}/cache"

[[ ! -e ${PATCH_FILE} ]] && echo "ERROR: cannot access ${PATCH_FILE}" && exit 1

# Copy cached buildroot to ${HOME}
CACHED_BUILDROOT_DIR="${CACHE_BASE_DIR}/repos/${BRANCH}/openwrt"
BUILDROOT_DIR="${HOME}/openwrt"
if [[ ! -d ${CACHED_BUILDROOT_DIR} ]]; then
    echo "ERROR: not found ${CACHED_BUILDROOT_DIR}"
    exit 1
fi
if [[ -d ${BUILDROOT_DIR} ]]; then
    echo "ERROR: already exist ${BUILDROOT_DIR}"
    exit 1
fi
START_TIME=$SECONDS
mkdir -p ${BUILDROOT_DIR}
tar -C ${CACHED_BUILDROOT_DIR} -cf - . | tar -C ${BUILDROOT_DIR} -xf -
echo "Copying buildroot finished. (elapsed time: $(expr $SECONDS - $START_TIME) secs)"

# Prepare Travis CI's cache directory
declare -A cache_dir=(
    [ccache-host]=${HOME}/openwrt/staging_dir/host/ccache
    [feeds]=${HOME}/openwrt/feeds
    [dl]=${HOME}/openwrt/dl
)
for key in "${!cache_dir[@]}"; do
    real_dir=${CACHE_BASE_DIR}/${key}
    cache_target=${cache_dir[$key]}
    mkdir -p ${real_dir}
    if [[ ! -d $(dirname ${cache_target}) ]] ; then
        echo "mkdir -p $(dirname ${cache_target})"
        mkdir -p $(dirname ${cache_target})
    fi
    if [[ -e ${cache_target} ]] ; then
        echo "Move ${cache_target} to ${cache_target}.orig"
        mv ${cache_target} ${cache_target}.orig
    fi
    echo "Link ${real_dir} ($(du -sh ${real_dir} | awk '{print $1}')) to ${cache_target}"
    ln -s ${real_dir} ${cache_target}
    if [[ ${key} =~ ^ccache- ]]; then
        CCACHE_DIR=${real_dir} ccache -s | tee /tmp/${key}.log
    fi
done

cd ${HOME}/openwrt

# Update feeds
START_TIME=$SECONDS
scripts/feeds update -a
echo "Updating feeds finished. (elapsed time: $(expr $SECONDS - $START_TIME) secs)"

# Build toolchain
START_TIME=$SECONDS
patch -p1 < "${PATCH_FILE}"
make toolchain/install
echo "Building toolchain finished. (elapsed time: $(expr $SECONDS - $START_TIME) secs)"

# Cleanup
for cache_target in "${cache_dir[@]}"; do
    if [[ -L ${cache_target} ]] ; then
        rm ${cache_target}
    fi
done
find build_dir \( -type l -or -type f \) -not -name '.*' -print0 | xargs -0 rm
find build_dir -type d -empty -delete
if [[ -d ${CACHE_BASE_DIR}/dl && ! -e ${HOME}/openwrt/dl/ ]]; then
    cd ${CACHE_BASE_DIR}/dl
    mkdir -p ${HOME}/openwrt/dl/
    for file in * ; do
        touch ${HOME}/openwrt/dl/${file} -r ${file}
    done
    rm -f ${HOME}/openwrt/dl/{linux,u-boot}-*
fi

# Show ccache status
cd ${CACHE_BASE_DIR}
for dir in *; do
    if [[ ${dir} =~ ^ccache- ]]; then
        echo ""
        echo "### ccache status (before build) ###"
        cat /tmp/${dir}.log
        echo ""
        echo "### ccache status (after build) ###"
        CCACHE_DIR=${dir} ccache -s
        rm -f /tmp/${dir}.log
    fi
done
