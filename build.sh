#!/bin/bash
# WITH_UPX=1

platform="$(uname -s)"
platform_arch="$(uname -m)"

if [ -x "$(which apt 2>/dev/null)" ]
    then
        apt update && apt install -y \
            build-essential clang pkg-config git autoconf libtool libcap-dev \
            gettext autopoint meson ninja-build libselinux1-dev
fi

if [ -d build ]
    then
        echo "= removing previous build directory"
        rm -rf build
fi

if [ -d release ]
    then
        echo "= removing previous release directory"
        rm -rf release
fi

# create build and release directory
mkdir build
mkdir release
pushd build

# cd to downloaded bubblewrap
[[ -d bubblewrap ]] || git clone https://github.com/containers/bubblewrap.git
bubblewrap_version="$(cd bubblewrap && git describe --long --tags|sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g')"
echo "BWRAP_VER=${bubblewrap_version}_$(date +%s)" >> $GITHUB_ENV
mv bubblewrap "bubblewrap-${bubblewrap_version}"
echo "= downloading bubblewrap v${bubblewrap_version}"

echo "= building bubblewrap"
pushd bubblewrap-${bubblewrap_version}
meson --buildtype=plain release -Dselinux=disabled -Dc_args="-static -g -O2 -Os -ffunction-sections -fdata-sections" -Dc_link_args='--static'
meson compile -C release
popd # bubblewrap-${bubblewrap_version}

popd # build

shopt -s extglob

echo "= extracting bubblewrap binary"
mv build/bubblewrap-${bubblewrap_version}/bwrap release 2>/dev/null

echo "= striptease"
strip -s -R .comment -R .gnu.version --strip-unneeded release/bwrap 2>/dev/null

if [[ "$WITH_UPX" == 1 && -x "$(which upx 2>/dev/null)" ]]
    then
        echo "= upx compressing"
        upx -9 --best release/bwrap 2>/dev/null
fi

mv release/bwrap .

if [ "$NO_CLEANUP" != 1 ]
    then
        echo "= cleanup"
        rm -rf release build
fi

echo "= bubblewrap v${bubblewrap_version} done"
