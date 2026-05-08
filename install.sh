#!/bin/bash
#
# install.sh - Build the hhd kernel on Arch Linux and install via pacman.
#
# Flow: Fedora container builds kernel RPMs -> Arch container repackages
# them into a pkg.tar.zst -> pacman -U installs it.
#
# Env:
#   ARCH             target arch (default: x86_64)
#   FEDORA_VERSION   Fedora builder image version (default: 43)
#   CCACHE_USE       1 to enable ccache (default: 1)
#   SKIP_INSTALL     1 to build only, skip pacman -U (default: 0)
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

ARCH="${ARCH:-x86_64}"
FEDORA_VERSION="${FEDORA_VERSION:-43}"
CCACHE_USE="${CCACHE_USE:-1}"
SKIP_INSTALL="${SKIP_INSTALL:-0}"

log() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

log "linux-hhd installer (arch=$ARCH fedora=$FEDORA_VERSION)"

if ! command -v pacman >/dev/null 2>&1; then
    die "pacman not found — this script targets Arch Linux."
fi

if ! command -v podman >/dev/null 2>&1; then
    log "Installing podman"
    sudo pacman -S --needed --noconfirm podman
fi

# Skip rebuild if RPMs already present (idempotent-ish re-runs)
need_kernel_build=1
if compgen -G "build/RPMS/$ARCH/kernel-*.rpm" >/dev/null; then
    log "Existing kernel RPMs found in build/RPMS/$ARCH — skipping Fedora build."
    log "    (rm -rf build/ to force rebuild)"
    need_kernel_build=0
fi

if [ "$need_kernel_build" = "1" ]; then
    log "Building Fedora builder image"
    sudo podman build . -f Dockerfile --tag fedora_builder \
        --build-arg FEDORA_VERSION="$FEDORA_VERSION" \
        --build-arg UID="$(id -u)" --build-arg GID="$(id -g)"

    log "Compiling kernel in container (this can take 1-4 hours)"
    sudo podman run --rm -v "$REPO_ROOT:/workspace" \
        -e UID="$(id -u)" -e GID="$(id -g)" \
        -e ARCH="$ARCH" -e FEDORA_VERSION="$FEDORA_VERSION" \
        -e CCACHE_USE="$CCACHE_USE" \
        fedora_builder bash ./build.sh
fi

# Separate debuginfo so makepkg doesn't sweep it into the Arch package
mkdir -p ./build/DRPMS
mv -f ./build/RPMS/"$ARCH"/kernel-debuginfo-*.rpm ./build/DRPMS/ 2>/dev/null || true

log "Preparing PKGBUILD"
src_rpm=$(ls -1 build/SRPMS/kernel-*.src.rpm 2>/dev/null | head -n 1) \
    || die "no source RPM in build/SRPMS — kernel build failed?"
KERNEL_VER=${src_rpm##*/kernel-}; KERNEL_VER=${KERNEL_VER%.src.rpm}
ARCH_VER=${KERNEL_VER//-/.}

sed "s/VERSION_FEDORA/${KERNEL_VER}.${ARCH}/; s/VERSION_TAG/${ARCH_VER}/" \
    PKGBUILD-ACTION > "./build/RPMS/$ARCH/PKGBUILD"

log "Building Arch builder image"
sudo podman build . -f Dockerfile-arch --tag arch_builder \
    --build-arg UID="$(id -u)" --build-arg GID="$(id -g)"

log "Packaging as Arch .pkg.tar.zst"
sudo podman run --rm -v "$REPO_ROOT/build/RPMS/$ARCH:/workspace" \
    arch_builder makepkg -s --noconfirm

PKG=$(ls -1t "$REPO_ROOT/build/RPMS/$ARCH"/linux-hhd-*.pkg.tar.zst 2>/dev/null | head -n 1)
[ -n "$PKG" ] || die "makepkg did not produce a linux-hhd-*.pkg.tar.zst"

log "Package ready: $PKG"

if [ "$SKIP_INSTALL" = "1" ]; then
    log "SKIP_INSTALL=1 — skipping pacman install."
    log "    Install later with: sudo pacman -U \"$PKG\""
    exit 0
fi

log "Installing via pacman"
sudo pacman -U --noconfirm "$PKG"

log "Done. Regenerate your bootloader entries if your setup needs it"
log "    (e.g. sudo grub-mkconfig -o /boot/grub/grub.cfg)."
