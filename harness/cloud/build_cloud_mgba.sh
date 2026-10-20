#!/bin/bash
# Build mGBA headless + Lua 5.4 (frozen: commit 143adf5a + pacing/video patch). Installs to /opt/mgba-headless.
set -e
[ -x /opt/mgba-headless ] && { echo "mgba-headless already built"; exit 0; }
MGBA_COMMIT=143adf5aa2a60c6036810b0cd72445e13d74b0e6
HERE="$(cd "$(dirname "$0")" && pwd)"
SUDO=""; [ "$(id -u)" = 0 ] || SUDO=sudo
$SUDO apt-get update -q && DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -q cmake liblua5.4-dev zlib1g-dev libpng-dev libsqlite3-dev pkg-config build-essential git python3-pil
W=/opt/mgba-src; $SUDO rm -rf "$W"; $SUDO mkdir -p "$W"; $SUDO chown "$(id -u)" "$W"; cd "$W"
git clone -q https://github.com/mgba-emu/mgba.git && cd mgba && git checkout -q $MGBA_COMMIT
git apply "$HERE/mgba-headless-pacing-and-video.patch"   # 60 fps pacing (MGBA_UNCAPPED=1 disables) + video buffer for screenshots
mkdir build && cd build
cmake .. -DBUILD_HEADLESS=ON -DBUILD_QT=OFF -DBUILD_SDL=OFF -DUSE_LUA=5.4 -DUSE_FFMPEG=OFF -DUSE_EPOXY=OFF -DBUILD_GL=OFF -DBUILD_GLES2=OFF -DBUILD_GLES3=OFF -DUSE_DISCORD_RPC=OFF -DUSE_LIBZIP=OFF -DUSE_EDITLINE=OFF -DCMAKE_BUILD_TYPE=Release >/dev/null
make -j"$(nproc)" mgba-headless >/dev/null
$SUDO cp mgba-headless /opt/mgba-headless
# shared lib if built as one
for f in libmgba.so*; do [ -e "$f" ] && $SUDO cp -a "$f" /usr/local/lib/; done; $SUDO ldconfig || true
echo "built /opt/mgba-headless"
