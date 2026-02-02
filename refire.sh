#!/bin/bash
set -euo pipefail

# ===========================
# Refire (Bakery-style)
# Usage: ./refire.sh <coind>
# - Finds $HOME/<coin>-build/<coin>
# - Rebuilds depends per enabled recipe_book.conf target
# - Rebuilds main per enabled target
# - Release-only builds (stripped)
# - Artifacts in ./special-delivery
# - NO GIT operations (preserves local edits)
# ===========================

RUN_DIR="$(pwd -P)"
LOG_FILE="${RUN_DIR}/bakery.log"
RECIPE_BOOK="${RUN_DIR}/recipe_book.conf"
SPECIAL_DELIVERY="${RUN_DIR}/special-delivery"
RELEASE_SUFFIX="Release"

log() { echo -e "\033[1;32m[INFO]  $*\033[0m" | tee -a "$LOG_FILE"; }
err() { echo -e "\033[1;31m[ERROR] $*\033[0m" | tee -a "$LOG_FILE" >&2; }

usage() {
  err "Usage: $0 [coin]"
  err "Default coin: bitoreum"
  err "Example: $0 yerbas"
  exit 1
}

# --- Default coin (override by passing an arg) ---
DEFAULT_COIN="bitoreum"
COIN_NAME="${1:-$DEFAULT_COIN}"

REPO_PARENT="$HOME/${COIN_NAME}-build"
REPO_ROOT="$REPO_PARENT/${COIN_NAME}"
DEPENDSDIR="$REPO_ROOT/depends"
BUILD_BASE="$REPO_PARENT/build"
COMPRESS_DIR="$REPO_PARENT/compressed"

mkdir -p "$SPECIAL_DELIVERY" "$BUILD_BASE" "$COMPRESS_DIR"

# --- Sanity checks ---
if [[ ! -d "$REPO_ROOT" ]]; then
  err "Repo not found: $REPO_ROOT"
  err "Expected: $HOME/${COIN_NAME}-build/${COIN_NAME}"
  err "Run bakery.sh at least once (or clone/build manually) before refire."
  exit 1
fi
if [[ ! -d "$DEPENDSDIR" ]]; then
  err "Depends folder not found: $DEPENDSDIR"
  err "Depends must exist before refire can rebuild."
  exit 1
fi
if [[ ! -d "$DEPENDSDIR/m4" && ! -f "$DEPENDSDIR/Makefile" ]]; then
  err "Depends directory exists but doesn't look like a depends tree: $DEPENDSDIR"
  exit 1
fi

log "Refire starting for coin: $COIN_NAME"
log "Repo: $REPO_ROOT"
log "Recipe book: $RECIPE_BOOK"
log "Delivery: $SPECIAL_DELIVERY"

# --- Default recipe_book.conf (same format as bakery) ---
_DEFAULT_RECIPE_BOOK="$(cat <<'CONF'
Linux 64-bit,y,QT=y
Linux 32-bit,y,QT=y
Linux ARM 32-bit,y,QT=y
Linux ARM 64-bit,y,QT=y
Raspberry Pi 4+,n,QT=y
Oracle Ampere ARM,n,QT=n
Windows 64-bit,y,QT=y
CONF
)"

valid_recipe_line() { [[ "$1" =~ ^[^,]+,(y|n),QT=(y|n)$ ]]; }

write_default_recipe_book() {
  log "Writing default recipe_book.conf -> ${RECIPE_BOOK}"
  printf '%s\n' "$_DEFAULT_RECIPE_BOOK" > "${RECIPE_BOOK}"
}

ensure_recipe_ok() {
  if [[ ! -f "$RECIPE_BOOK" ]]; then
    log "recipe_book.conf not found. Creating default."
    write_default_recipe_book
    return
  fi
  local ok=true
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    valid_recipe_line "$line" || { ok=false; break; }
  done < "$RECIPE_BOOK"
  if ! $ok; then
    err "recipe_book.conf invalid. Replacing with default."
    write_default_recipe_book
  fi
}

# --- Map friendly target -> host + flags (same as bakery) ---
map_target() {
  case "$1" in
    "Linux 64-bit")        echo "x86_64-pc-linux-gnu false false false";;
    "Linux 32-bit")        echo "i686-pc-linux-gnu false false false";;
    "Linux ARM 32-bit")    echo "arm-linux-gnueabihf false false false";;
    "Linux ARM 64-bit")    echo "aarch64-linux-gnu false false false";;
    "Raspberry Pi 4+")     echo "aarch64-linux-gnu true false false";;
    "Oracle Ampere ARM")   echo "aarch64-linux-gnu false true false";;
    "Windows 64-bit")      echo "x86_64-w64-mingw32 false false true";;
    *)                     echo "unknown false false false";;
  esac
}

detect_os_label() {
  local os; os="$(. /etc/os-release && echo "${ID}-${VERSION_ID}")"
  [[ "$os" == "ubuntu-18.04" ]] && os="Generic-Linux"
  echo "$os"
}

arch_type_label() {
  local host="$1" is_pi="$2" is_amp="$3" is_win="$4"
  if [[ "$is_pi" == "true" ]]; then
    echo "Pi4_ARM_64"
  elif [[ "$is_amp" == "true" ]]; then
    echo "Oracle-Ampere_ARM_64"
  elif [[ "$is_win" == "true" ]]; then
    echo "Win64_x86"
  else
    case "$host" in
      x86_64-pc-linux-gnu) echo "x86_64" ;;
      i686-pc-linux-gnu)   echo "x86_32" ;;
      arm-linux-gnueabihf) echo "ARM_32" ;;
      aarch64-linux-gnu)   echo "ARM_64" ;;
      *)                   echo "$host" ;;
    esac
  fi
}

compute_version() {
  if [[ -f "$REPO_ROOT/build.properties" ]]; then
    grep '^release-version=' "$REPO_ROOT/build.properties" | cut -d'=' -f2
  else
    date +%Y%m%d-%H%M%S
  fi
}

ensure_windows_toolchain() {
  log "Ensuring MinGW-w64 toolchain for Windows target..."
  sudo apt-get update -y
  sudo apt-get install -y g++-mingw-w64-x86-64 gcc-mingw-w64-x86-64 binutils-mingw-w64-x86-64 nsis
  sudo update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix || true
  sudo update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix || true
}

# --- Build a single target (Release-only) ---
build_target() {
  local friendly="$1" host="$2" qt="$3" is_pi="$4" is_amp="$5" is_win="$6"
  log "-*- Refiring goods: ${friendly} | HOST=${host} | QT=${qt} -*-"

# ---- Depends clean & rebuild ----
  pushd "$DEPENDSDIR" >/dev/null
  make clean || true
  make distclean || true
  local depends_flags=()
  [[ "${qt,,}" == "n" ]] && depends_flags+=(NO_QT=1)
  make -j"$(nproc)" HOST="$host" "${depends_flags[@]}"
  popd >/dev/null

# ---- Main clean, autogen, configure, build ----
  pushd "$REPO_ROOT" >/dev/null
  make clean || true
  make distclean || true
  ./autogen.sh

  local cfg_flags=""
  [[ "${qt,,}" == "n" ]] && cfg_flags+=" --with-gui=no"
  ./configure --prefix="${DEPENDSDIR}/${host}" ${cfg_flags}
  make -j"$(nproc)"

# ---- Determine binaries to package ----
  local binfiles=()
  if [[ "$is_win" == "true" ]]; then
    binfiles=("${COIN_NAME}-cli.exe" "${COIN_NAME}d.exe")
    [[ -f "src/${COIN_NAME}-tx.exe" ]] && binfiles+=("${COIN_NAME}-tx.exe")
    [[ "${qt,,}" == "y" ]] && binfiles+=("qt/${COIN_NAME}-qt.exe")
  else
    binfiles=("${COIN_NAME}-cli" "${COIN_NAME}d")
    [[ -f "src/${COIN_NAME}-tx" ]] && binfiles+=("${COIN_NAME}-tx")
    [[ "${qt,,}" == "y" ]] && binfiles+=("qt/${COIN_NAME}-qt")
  fi

  local bin_subdir="${COIN_NAME}-v${VERSION}"
  local out_dir="${BUILD_BASE}/${bin_subdir}"
  rm -rf "$out_dir"
  mkdir -p "$out_dir"

  for b in "${binfiles[@]}"; do
    [[ -f "src/${b}" ]] || { err "Missing binary: src/${b}"; popd >/dev/null; return 1; }
    cp "src/${b}" "$out_dir/"
  done

# ---- HOST aware strip ----
  local strip_tool
  case "$host" in
    x86_64-w64-mingw32)   strip_tool="x86_64-w64-mingw32-strip" ;;
    arm-linux-gnueabihf)  strip_tool="arm-linux-gnueabihf-strip" ;;
    aarch64-linux-gnu)    strip_tool="aarch64-linux-gnu-strip" ;;
    i686-pc-linux-gnu)    strip_tool="i686-linux-gnu-strip" ;;
    *)                    strip_tool="strip" ;;
  esac
  if ! command -v "$strip_tool" >/dev/null 2>&1; then
    err "strip tool '$strip_tool' not found; using fallback 'strip'"
    strip_tool="strip"
  fi
  "$strip_tool" "$out_dir"/* || err "strip failed (continuing)"

# ---- Checksums inside tree (per-build) ----
  local checksum_file="${out_dir}/checksums-${VERSION}.txt"
  : > "$checksum_file"
  echo "sha256sum:" >> "$checksum_file"
  (cd "$BUILD_BASE" && find "$bin_subdir" -type f -exec sha256sum {} \;) >> "$checksum_file" 2>/dev/null || true
  echo "openssl-sha256:" >> "$checksum_file"
  (cd "$BUILD_BASE" && find "$bin_subdir" -type f -exec openssl dgst -sha256 -r {} \;) >> "$checksum_file" 2>/dev/null || true

# ---- Archive and deliver ----
  local os_label arch_label archive_name
  os_label="$(detect_os_label)"
  arch_label="$(arch_type_label "$host" "$is_pi" "$is_amp" "$is_win")"

  if [[ "$is_win" == "true" ]]; then
    archive_name="${COIN_NAME}-Generic-${arch_label}-${RELEASE_SUFFIX}-${VERSION}.zip"
    (cd "$BUILD_BASE" && zip -r "${COMPRESS_DIR}/${archive_name}" "$bin_subdir")
  else
    archive_name="${COIN_NAME}-${os_label}_${arch_label}-${RELEASE_SUFFIX}-${VERSION}.tar.gz"
    (cd "$BUILD_BASE" && tar -cf - "$bin_subdir" | gzip -9 > "${COMPRESS_DIR}/${archive_name}")
  fi

  mv -f "${COMPRESS_DIR}/${archive_name}" "$SPECIAL_DELIVERY/"
  log "Refired & packaged: ${SPECIAL_DELIVERY}/${archive_name}"
  popd >/dev/null
  return 0
}

# --- Main flow ---
ensure_recipe_ok
mkdir -p "$SPECIAL_DELIVERY" "$COMPRESS_DIR" "$BUILD_BASE"

VERSION="$(compute_version)"
log "Refire batch start (coin: ${COIN_NAME})"
if [[ -f "$REPO_ROOT/build.properties" ]]; then
  log "Using release-version: ${VERSION}"
else
  log "No build.properties found; using fallback version: ${VERSION}"
fi

# If Windows target is enabled in recipe book, ensure toolchain
if grep -E "^Windows 64-bit,y,QT=" "$RECIPE_BOOK" >/dev/null 2>&1; then
  ensure_windows_toolchain
fi

# --- Build loop (enabled targets) ---
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  IFS=',' read -r friendly enabled qtfield <<< "$line"
  [[ "${enabled,,}" != "y" ]] && continue
  qt="${qtfield#QT=}"
  qt="${qt,,}"

  read host is_pi is_amp is_win <<<"$(map_target "$friendly")"
  [[ "$host" == "unknown" ]] && { err "Skipping unknown: $friendly"; continue; }

  build_target "$friendly" "$host" "$qt" "$is_pi" "$is_amp" "$is_win" || {
    err "Build failed for ${friendly}; aborting."
    exit 1
  }
done < "$RECIPE_BOOK"

# --- Final global checksums (for everything in special-delivery) ---
GLOBAL_SUM="${SPECIAL_DELIVERY}/checksums-${VERSION}.txt"
: > "$GLOBAL_SUM"
shopt -s nullglob
for f in "${SPECIAL_DELIVERY}"/*.tar.gz "${SPECIAL_DELIVERY}"/*.zip; do
  [[ -e "$f" ]] || continue
  echo "sha256sum: $(sha256sum "$f")" >> "$GLOBAL_SUM" || err "sha256sum failed for $f"
  echo "openssl-sha256: $(openssl dgst -sha256 -r "$f")" >> "$GLOBAL_SUM" || err "openssl sha256 failed for $f"
done
log "Wrote global checksums -> ${GLOBAL_SUM}"
log "Batch of Refired Goods Complete. Artifacts in ${SPECIAL_DELIVERY}"
