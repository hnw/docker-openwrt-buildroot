#!/bin/bash
set -e

SCRIPT_DIR=$(dirname $(readlink -e $0))
. ${SCRIPT_DIR}/utils.sh

export TERM=xterm
export COLOR=always

BRANCH=$1
BOARD=$2

PATCH_FILE="${SCRIPT_DIR}/patch/${BRANCH}-${BOARD}.patch"
CACHE_BASE_DIR="${SCRIPT_DIR}/cache"

[[ ! -e ${PATCH_FILE} ]] && die "ERROR: cannot access ${PATCH_FILE}"

# Copy cached buildroot to ${HOME}
CACHED_BUILDROOT_DIR="${CACHE_BASE_DIR}/repos/${BRANCH}/openwrt"
BUILDROOT_DIR="${HOME}/openwrt"

[[ ! -d ${CACHED_BUILDROOT_DIR} ]] && die "ERROR: not found ${CACHED_BUILDROOT_DIR}"
[[ -d ${BUILDROOT_DIR} ]] && die "ERROR: already exist ${BUILDROOT_DIR}"

set_timer
mkdir -p ${BUILDROOT_DIR}
copy_all_files ${CACHED_BUILDROOT_DIR} ${BUILDROOT_DIR}
success "Copying buildroot finished. (elapsed time: $(time_elasped))"

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
set_timer
scripts/feeds update -a
success "Updating feeds finished. (elapsed time: $(time_elasped))"

# Build toolchain
set_timer
patch -p1 < "${PATCH_FILE}"
make toolchain/install
success "Building toolchain finished. (elapsed time: $(time_elasped))"

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
        header "ccache status (before build)"
        cat /tmp/${dir}.log
        echo ""
        header "ccache status (after build)"
        CCACHE_DIR=${dir} ccache -s
        rm -f /tmp/${dir}.log
    fi
done
