#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${REPO_DIR}/src"
EXTRAS_SRC_DIR="${REPO_DIR}/extras"
DIST_DIR="${REPO_DIR}/dist"
EXTRAS_DIST_DIR="${DIST_DIR}/extras"

mkdir -p "${DIST_DIR}" "${EXTRAS_DIST_DIR}"
rm -f "${DIST_DIR}"/*.deb "${EXTRAS_DIST_DIR}"/*.deb

echo "=== Cleaning temporary files ==="
find "${SRC_DIR}" "${EXTRAS_SRC_DIR}" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "${SRC_DIR}" "${EXTRAS_SRC_DIR}" -type f -name "*.pyc" -delete 2>/dev/null || true
find "${SRC_DIR}" "${EXTRAS_SRC_DIR}" -type f -name "*~" -delete 2>/dev/null || true

echo "=== Building Argon ONE UP Core Debian Packages ==="

if [ "$(uname -m)" = "aarch64" ]; then
    CC_BIN="gcc"
    CXX_BIN="g++"
    STRIP_BIN="strip"
else
    CC_BIN="aarch64-linux-gnu-gcc"
    CXX_BIN="aarch64-linux-gnu-g++"
    STRIP_BIN="aarch64-linux-gnu-strip"
fi

if [ -f "${EXTRAS_SRC_DIR}/argon-oneup-plasma-widget/usr/src/argon-oneup-telemetry.c" ]; then
    echo "Compiling argon-oneup-telemetry binary (C / Cortex-A76 + LTO + Vectorize)..."
    "${CC_BIN}" -O3 -pipe -march=armv8.2-a+crypto+fp16+dotprod -mtune=cortex-a76 -ftree-vectorize -flto=auto -ffat-lto-objects "${EXTRAS_SRC_DIR}/argon-oneup-plasma-widget/usr/src/argon-oneup-telemetry.c" -o "${EXTRAS_SRC_DIR}/argon-oneup-plasma-widget/usr/bin/argon-oneup-telemetry"
    "${STRIP_BIN}" "${EXTRAS_SRC_DIR}/argon-oneup-plasma-widget/usr/bin/argon-oneup-telemetry"
fi

if [ -f "${EXTRAS_SRC_DIR}/ksystemstats-rpi5-fix/usr/src/ksystemstats-ns-helper.c" ]; then
    echo "Compiling ksystemstats-ns-helper binary (C / Cortex-A76 + LTO + Vectorize)..."
    "${CC_BIN}" -O2 -pipe -Wall -Wextra -march=armv8.2-a+crypto+fp16+dotprod -mtune=cortex-a76 -ftree-vectorize -flto=auto -ffat-lto-objects "${EXTRAS_SRC_DIR}/ksystemstats-rpi5-fix/usr/src/ksystemstats-ns-helper.c" -o "${EXTRAS_SRC_DIR}/ksystemstats-rpi5-fix/usr/bin/ksystemstats-ns-helper"
    "${STRIP_BIN}" "${EXTRAS_SRC_DIR}/ksystemstats-rpi5-fix/usr/bin/ksystemstats-ns-helper"
fi

if command -v dtc >/dev/null 2>&1; then
    echo "Compiling Device Tree Overlays (.dts -> .dtbo)..."
    dtc -@ -I dts -O dtb -Wno-gpios_property \
        -o "${SRC_DIR}/argon-oneup-lid/usr/share/argon-oneup/overlays/argon-oneup-lid.dtbo" \
        "${SRC_DIR}/argon-oneup-lid/usr/share/argon-oneup/dts/argon-oneup-lid.dts"
    dtc -@ -I dts -O dtb -Wno-gpios_property \
        -o "${SRC_DIR}/argon-oneup-battery/usr/share/argon-oneup/overlays/argon-oneup-battery.dtbo" \
        "${SRC_DIR}/argon-oneup-battery/usr/share/argon-oneup/dts/argon-oneup-battery.dts"
    if [ -f "${SRC_DIR}/cm5-mmc-fix/usr/share/cm5-mmc-fix/cm5-sdcard-fast.dts" ]; then
        dtc -@ -I dts -O dtb -Wno-gpios_property \
            -o "${SRC_DIR}/cm5-mmc-fix/usr/share/cm5-mmc-fix/overlays/cm5-sdcard-fast.dtbo" \
            "${SRC_DIR}/cm5-mmc-fix/usr/share/cm5-mmc-fix/cm5-sdcard-fast.dts"
    fi
    if [ -f "${SRC_DIR}/rpi-vc4-edp/usr/share/rpi-vc4-edp/dts/argon-oneup-display.dts" ]; then
        dtc -@ -I dts -O dtb -Wno-gpios_property \
            -o "${SRC_DIR}/rpi-vc4-edp/usr/share/rpi-vc4-edp/overlays/argon-oneup-display.dtbo" \
            "${SRC_DIR}/rpi-vc4-edp/usr/share/rpi-vc4-edp/dts/argon-oneup-display.dts"
    fi
fi

echo "Normalizing file and directory permissions (0755 / 0644)..."
find "${SRC_DIR}" "${EXTRAS_SRC_DIR}" -type d -exec chmod 0755 {} +
find "${SRC_DIR}" "${EXTRAS_SRC_DIR}" -type f -perm -0100 -exec chmod 0755 {} +
find "${SRC_DIR}" "${EXTRAS_SRC_DIR}" -type f -not -perm -0100 -exec chmod 0644 {} +
find "${SRC_DIR}" "${EXTRAS_SRC_DIR}" -path "*/DEBIAN/post*" -exec chmod 0755 {} +
find "${SRC_DIR}" "${EXTRAS_SRC_DIR}" -path "*/DEBIAN/pre*" -exec chmod 0755 {} +

GIT_COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "")
GIT_SHORT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "")
EXACT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")

GIT_SUFFIX=""
if [ -z "${EXACT_TAG}" ] && [ -n "${GIT_COMMIT_COUNT}" ] && [ -n "${GIT_SHORT_HASH}" ]; then
    GIT_SUFFIX="+git${GIT_COMMIT_COUNT}.${GIT_SHORT_HASH}"
    echo "=== Rolling Continuous Delivery: Version suffix ${GIT_SUFFIX} ==="
else
    echo "=== Release Build: Clean versions from control files (Tag: ${EXACT_TAG:-none}) ==="
fi

install_copyright() {
    local pkg_dir="$1"
    local pkg="$2"
    local doc_dir="${pkg_dir}/usr/share/doc/${pkg}"

    [ -f "${doc_dir}/copyright" ] && return 0
    mkdir -p "${doc_dir}"
    cat > "${doc_dir}/copyright" <<'EOF'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: argon-oneup-suite
Source: https://github.com/GamingTux/argon-oneup-suite

Files: *
Copyright: 2026 GamingTux
License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.

Files: src/argon-oneup-battery/usr/src/oneUpPower-*
Copyright: Jeff Curless and contributors
License: GPL-2.0-only
 On Debian systems, the complete text of the GNU General Public License
 version 2 can be found in /usr/share/common-licenses/GPL-2.

Files: extras/argon-wfplug-batt/usr/src/wfplug-batt/*
Copyright: 2018-2025 Raspberry Pi
Comment: Derived from the Raspberry Pi wf-panel-pi/pplug-batt battery widget.
 These files carry an "All rights reserved" notice and are not covered by
 the repository's MIT license. See THIRD_PARTY.md.
EOF
}

package_dir() {
    local src_path="$1"
    local dest_dir="$2"
    local pkg="$3"

    local arch
    arch=$(grep "^Architecture:" "${src_path}/DEBIAN/control" | awk '{print $2}')
    local base_ver
    base_ver=$(grep "^Version:" "${src_path}/DEBIAN/control" | awk '{print $2}')
    local final_ver="${base_ver}${GIT_SUFFIX}"
    local deb_name="${pkg}_${final_ver}_${arch}.deb"

    echo "Building package: ${pkg} (${final_ver} [${arch}])..."

    local stage_dir
    stage_dir=$(mktemp -d)
    cp -a "${src_path}" "${stage_dir}/${pkg}"
    install_copyright "${stage_dir}/${pkg}" "${pkg}"

    if [ -n "${GIT_SUFFIX}" ]; then
        sed -i "s/^Version: .*/Version: ${final_ver}/" "${stage_dir}/${pkg}/DEBIAN/control"
        sed -i "s/argon-power-profiles (= [^)]*)/argon-power-profiles (= ${final_ver})/" "${stage_dir}/${pkg}/DEBIAN/control" 2>/dev/null || true
        sed -i "s/argon-power-profiles (<< [^)]*)/argon-power-profiles (<< ${final_ver})/" "${stage_dir}/${pkg}/DEBIAN/control" 2>/dev/null || true
    fi

    dpkg-deb --root-owner-group -b "${stage_dir}/${pkg}" "${dest_dir}/${deb_name}"
    rm -rf "${stage_dir}"
}

for pkg in argon-oneup-essentials argon-oneup-backlight argon-oneup-battery argon-oneup-lid argon-oneup-sensors argon-oneup-power-profiles argon-oneup-suspend rpi-vc4-edp cm5-mmc-fix argon-oneup-suite; do
    PKG_PATH="${SRC_DIR}/${pkg}"
    if [ -d "${PKG_PATH}" ]; then
        package_dir "${PKG_PATH}" "${DIST_DIR}" "${pkg}"
    fi
done

echo "=== Synchronizing External Packages (rpi-suspend) ==="
RPI_SUSPEND_SYNCED=false
RPI_SUSPEND_URL="https://github.com/GamingTux/rpi-suspend/releases/latest/download/rpi-suspend.deb"

# 1. Prefer local build if ../rpi-suspend exists and has a deb built
if [ -d "${REPO_DIR}/../rpi-suspend" ]; then
    LATEST_LOCAL_DEB=$(find "${REPO_DIR}/../rpi-suspend" -maxdepth 1 -name "rpi-suspend_*.deb" | sort -V | tail -n 1)
    if [ -n "${LATEST_LOCAL_DEB}" ] && [ -f "${LATEST_LOCAL_DEB}" ]; then
        cp -f "${LATEST_LOCAL_DEB}" "${DIST_DIR}/"
        RPI_SUSPEND_SYNCED=true
        echo "Synchronized local rpi-suspend from ${LATEST_LOCAL_DEB}."
    fi
fi

# 2. Download from GitHub Releases if not synced locally or in CI environment
if [ "${RPI_SUSPEND_SYNCED}" = false ]; then
    echo "Downloading latest rpi-suspend from GitHub Releases (${RPI_SUSPEND_URL})..."
    TMP_DEB=$(mktemp "${DIST_DIR}/rpi-suspend.XXXXXX.deb")
    if curl -fsSL -o "${TMP_DEB}" "${RPI_SUSPEND_URL}" 2>/dev/null; then
        VER=$(dpkg-deb -f "${TMP_DEB}" Version 2>/dev/null || echo "latest")
        ARCH=$(dpkg-deb -f "${TMP_DEB}" Architecture 2>/dev/null || echo "all")
        mv -f "${TMP_DEB}" "${DIST_DIR}/rpi-suspend_${VER}_${ARCH}.deb"
        RPI_SUSPEND_SYNCED=true
        echo "Downloaded rpi-suspend (${VER} [${ARCH}]) successfully."
    else
        rm -f "${TMP_DEB}"
    fi
fi

# 3. Fallback: Check if already present in parent / Downloads
if [ "${RPI_SUSPEND_SYNCED}" = false ]; then
    if [ -f "${REPO_DIR}/../rpi-suspend.deb" ]; then
        cp -f "${REPO_DIR}/../rpi-suspend.deb" "${DIST_DIR}/"
        echo "Used fallback rpi-suspend.deb from ../rpi-suspend.deb."
        RPI_SUSPEND_SYNCED=true
    fi
fi

if [ "${RPI_SUSPEND_SYNCED}" = false ]; then
    echo "WARNING: Could not fetch rpi-suspend package. Please ensure internet access or provide rpi-suspend.deb."
fi

echo "=== Rebuilding / Verifying wf-panel-pi battery widget ==="
LIBBATT_DIR="${EXTRAS_SRC_DIR}/argon-wfplug-batt/usr/share/argon-oneup/wf-panel-pi"
LIBBATT_BIN="${LIBBATT_DIR}/libbatt.so"
LIBBATT_SUM="${LIBBATT_DIR}/libbatt.so.sha256"
LIBBATT_SRC="${EXTRAS_SRC_DIR}/argon-wfplug-batt/usr/src/wfplug-batt"

if [ -f "${LIBBATT_BIN}" ] && [ -f "${LIBBATT_SUM}" ]; then
    ( cd "${LIBBATT_DIR}" && sha256sum -c "$(basename "${LIBBATT_SUM}")" ) || {
        echo "ERROR: ${LIBBATT_BIN} does not match its recorded SHA256." >&2
        exit 1
    }
fi

if [ "${REBUILD_LIBBATT:-0}" = "1" ]; then
    WF_PANEL_PI_SRC="${WF_PANEL_PI_SRC:-${REPO_DIR}/../wf-panel-pi}"
    WF_PANEL_PI_INC="${WF_PANEL_PI_SRC}/src/wf-panel-pi"
    [ -f "${WF_PANEL_PI_INC}/plugin.h" ] || WF_PANEL_PI_INC="${WF_PANEL_PI_SRC}/src"
    if [ ! -f "${WF_PANEL_PI_INC}/plugin.h" ] || [ ! -f "${WF_PANEL_PI_INC}/widget.hpp" ]; then
        echo "ERROR: REBUILD_LIBBATT=1 but wf-panel-pi headers were not found in ${WF_PANEL_PI_SRC}." >&2
        echo "       Set WF_PANEL_PI_SRC to a wf-panel-pi source tree." >&2
        exit 1
    fi
    if ! pkg-config --exists gtkmm-3.0; then
        echo "ERROR: REBUILD_LIBBATT=1 but the gtkmm-3.0 development files are missing." >&2
        exit 1
    fi
    if ! pkg-config --exists gtk-layer-shell-0; then
        echo "ERROR: REBUILD_LIBBATT=1 but the gtk-layer-shell development files are missing." >&2
        exit 1
    fi
    make -C "${LIBBATT_SRC}" clean all \
        WF_PANEL_PI_SRC="${WF_PANEL_PI_SRC}" WF_PANEL_PI_INC="${WF_PANEL_PI_INC}" \
        CC="${CC_BIN}" CXX="${CXX_BIN}"
    cp -f "${LIBBATT_SRC}/libbatt.so" "${LIBBATT_BIN}"
    "${STRIP_BIN}" "${LIBBATT_BIN}" 2>/dev/null || true
    if [ "${UPDATE_LIBBATT_SHA:-0}" = "1" ]; then
        ( cd "${LIBBATT_DIR}" && sha256sum libbatt.so > libbatt.so.sha256 )
    else
        ( cd "${LIBBATT_DIR}" && sha256sum -c libbatt.so.sha256 ) || {
            echo "WARNING: rebuilt libbatt.so differs from the recorded SHA256." >&2
            echo "         Re-run with UPDATE_LIBBATT_SHA=1 to accept the new binary." >&2
        }
    fi
else
    echo "Using verified prebuilt libbatt.so (set REBUILD_LIBBATT=1 to rebuild from source)."
fi

echo "=== Building Argon ONE UP Extras (Optional Fixes, Standby, Widgets & Applets) ==="

for pkg in argon-oneup-plasma-widget argon-wfplug-batt ksystemstats-rpi5-fix rpi-pishutdown; do
    PKG_PATH="${EXTRAS_SRC_DIR}/${pkg}"
    if [ -d "${PKG_PATH}" ]; then
        package_dir "${PKG_PATH}" "${EXTRAS_DIST_DIR}" "${pkg}"
    fi
done

cd "${DIST_DIR}"
sha256sum *.deb extras/*.deb > SHA256SUMS
echo "=== All packages built successfully into ${DIST_DIR} and ${EXTRAS_DIST_DIR} ==="
ls -lh "${DIST_DIR}"/*.deb "${EXTRAS_DIST_DIR}"/*.deb
