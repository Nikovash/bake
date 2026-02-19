#!/bin/bash
set -Eeuo pipefail

# ===========================
# Refire (Bakery-style)
# Usage: ./refire.sh [coin] [-rf <release_name_override>]
# - Finds $HOME/<coin>-build/<coin>
# - Rebuilds depends per enabled recipe_book.conf target
# - Rebuilds main per enabled target
# - Release-only builds (stripped)  [can disable via STRIP_BINARIES=0]
# - Artifacts in ./special-delivery
# - NO GIT operations (preserves local edits)
#
# -rf "some Text"  => archive "Release" segment becomes "some_text"
# ===========================

RUN_DIR="$(pwd -P)"
LOG_FILE="${RUN_DIR}/bakery.log"
RECIPE_BOOK="${RUN_DIR}/recipe_book.conf"
SPECIAL_DELIVERY="${RUN_DIR}/special-delivery"
RELEASE_SUFFIX_DEFAULT="Release"

# --- Optional strip control (default on) ---
STRIP_BINARIES="${STRIP_BINARIES:-1}"

# --- Default coin (override by passing an arg) ---
DEFAULT_COIN="bitoreum"
COIN_NAME=""
RELEASE_SUFFIX="$RELEASE_SUFFIX_DEFAULT"

# ---------- helpers ----------
ts() { date "+%Y-%m-%d %H:%M:%S"; }

# snake-case-ish: "Some Text" -> "some_text"
to_release_slug() {
  local s="${1:-}"
  # lowercase
  s="$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]')"
  # non-alnum -> underscore
  s="$(printf '%s' "$s" | sed -E 's/[^a-z0-9]+/_/g')"
  # trim leading/trailing underscores
  s="$(printf '%s' "$s" | sed -E 's/^_+//; s/_+$//')"
  # collapse repeats
  s="$(printf '%s' "$s" | sed -E 's/_+/_/g')"
  printf '%s' "$s"
}

# ANSI color only for terminal (never in bakery.log)
if [[ -t 1 && "${NO_COLOR:-0}" != "1" ]]; then
  C_INFO=$'\033[1;32m'
  C_ERR=$'\033[1;31m'
  C_RST=$'\033[0m'
else
  C_INFO=""
  C_ERR=""
  C_RST=""
fi

log() {
  echo -e "${C_INFO}[INFO]${C_RST}  $*"
  printf "%s [INFO]  %s\n" "$(ts)" "$*" >> "$LOG_FILE"
  printf "%s [INFO]  %s\n" "$(ts)" "$*" >> "$SUMMARY_LOG"
}

err() {
  echo -e "${C_ERR}[ERROR]${C_RST} $*" >&2
  printf "%s [ERROR] %s\n" "$(ts)" "$*" >> "$LOG_FILE"
  printf "%s [ERROR] %s\n" "$(ts)" "$*" >> "$SUMMARY_LOG"
}

die() { err "$*"; exit 1; }

usage() {
  err "Usage: $0 [coin] [-rf <release_name_override>]"
  err "Examples:"
  err "  $0"
  err "  $0 yerbas"
  err "  $0 yerbas -rf \"some Text\""
  err "  $0 -rf nightly yerbas"
  exit 1
}

# ---------- arg parsing ----------
# Allow coin and flags in either order.
# For -rf, accept multiple words until next recognized flag or end.
parse_args() {
  local args=("$@")
  local i=0

  while [[ $i -lt ${#args[@]} ]]; do
    case "${args[$i]}" in
      -h|--help)
        usage
        ;;
      -rf)
        i=$((i+1))
        [[ $i -lt ${#args[@]} ]] || die "-rf requires a value (e.g. -rf \"some Text\")"
        local parts=()
        while [[ $i -lt ${#args[@]} ]]; do
          # stop if next token looks like a flag we recognize
          case "${args[$i]}" in
            -h|--help|-rf) break ;;
          esac
          # stop if token begins with '-' (future-proof-ish)
          if [[ "${args[$i]}" == -* ]]; then
            break
          fi
          parts+=("${args[$i]}")
          i=$((i+1))
        done
        i=$((i-1)) # compensate for outer loop increment

        local raw="${parts[*]}"
        local slug
        slug="$(to_release_slug "$raw")"
        [[ -n "$slug" ]] || die "-rf value became empty after sanitizing; pick something like \"nightly\""
        RELEASE_SUFFIX="$slug"
        ;;
      *)
        # first non-flag token becomes coin, ignore extras (keeps behavior predictable)
        if [[ -z "${COIN_NAME}" && "${args[$i]}" != -* ]]; then
          COIN_NAME="${args[$i]}"
        else
          err "Unknown/extra argument: ${args[$i]}"
          usage
        fi
        ;;
    esac
    i=$((i+1))
  done

  [[ -n "$COIN_NAME" ]] || COIN_NAME="$DEFAULT_COIN"
}
parse_args "$@"

# ---------- paths ----------
REPO_PARENT="$HOME/${COIN_NAME}-build"
REPO_ROOT="$REPO_PARENT/${COIN_NAME}"
DEPENDSDIR="$REPO_ROOT/depends"
BUILD_BASE="$REPO_PARENT/build"
COMPRESS_DIR="$REPO_PARENT/compressed"

mkdir -p "$SPECIAL_DELIVERY" "$BUILD_BASE" "$COMPRESS_DIR"

# --- Run-scoped logs ---
RUN_ID="$(date +%Y%m%d-%H%M%S)"
LOG_ROOT="${RUN_DIR}/run-logs/${COIN_NAME}/${RUN_ID}"
BUILD_LOG="${LOG_ROOT}/build"
BUILD_DEPENDS_LOG="${LOG_ROOT}/depends"
SUMMARY_LOG="${LOG_ROOT}/summary.log"

mkdir -p "$BUILD_LOG" "$BUILD_DEPENDS_LOG"
: > "$SUMMARY_LOG"

# On any error, point to logs
on_fail() {
  local ec=$?
  err "Refire failed (exit=${ec}) at line ${BASH_LINENO[0]}: ${BASH_COMMAND}"
  err "Run logs: ${LOG_ROOT}"
  err "Summary:  ${SUMMARY_LOG}"
  exit "$ec"
}
trap on_fail ERR

# --- Sanity checks ---
[[ -d "$REPO_ROOT" ]]     || die "Repo not found: $REPO_ROOT (expected $HOME/${COIN_NAME}-build/${COIN_NAME})"
[[ -d "$DEPENDSDIR" ]]    || die "Depends folder not found: $DEPENDSDIR"
[[ -f "$DEPENDSDIR/Makefile" || -d "$DEPENDSDIR/m4" ]] || die "Depends exists but doesn't look like depends tree: $DEPENDSDIR"

log "Refire starting for coin: $COIN_NAME"
log "Repo: $REPO_ROOT"
log "Recipe book: $RECIPE_BOOK"
log "Delivery: $SPECIAL_DELIVERY"
log "Run logs: $LOG_ROOT"
log "Release suffix: ${RELEASE_SUFFIX}"

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

# Allow blank lines + comments
valid_recipe_line() {
  local line="$1"
  [[ -z "$line" ]] && return 0
  [[ "$line" =~ ^[[:space:]]*# ]] && return 0
  [[ "$line" =~ ^[^,]+,(y|n),QT=(y|n)$ ]]
}

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
  local ok=true line
  while IFS= read -r line || [[ -n "$line" ]]; do
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

# Ubuntu 18.x => Generic  (as requested)
detect_os_label() {
  local id ver
  # shellcheck disable=SC1091
  . /etc/os-release
  id="${ID:-unknown}"
  ver="${VERSION_ID:-unknown}"

  if [[ "$id" == "ubuntu" && "$ver" =~ ^18\. ]]; then
    echo "Generic"
    return
  fi

  echo "${id}-${ver}"
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
  sudo apt-get install -y g++-mingw-w64-x86-64 gcc-mingw-w64-x86-64 binutils-mingw-w64-x86-64 nsis zip
  sudo update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix || true
  sudo update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix || true
}

sanitize_tag() {
  # keep only: A–Z a–z 0–9 . _ -
  echo "$1" | tr -cs 'A-Za-z0-9._-' '_'
}

# --- Main flow init ---
ensure_recipe_ok
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

# --- Build a single target ---
build_target() {
  local friendly="$1" host="$2" qt="$3" is_pi="$4" is_amp="$5" is_win="$6"
  log "-*- Refiring: ${friendly} | HOST=${host} | QT=${qt} -*-"

  local did_push_repo=0 did_push_dep=0
  cleanup_dirs() {
    ((did_push_repo)) && popd >/dev/null || true
    ((did_push_dep))  && popd >/dev/null || true
  }
  trap cleanup_dirs RETURN

  # Depends flags
  local depends_flags=()
  [[ "${qt,,}" == "n" ]] && depends_flags+=(NO_QT=1)

  local tag_raw="${friendly}-${host}-qt${qt}"
  local tag; tag="$(sanitize_tag "$tag_raw")"

  local arch_label; arch_label="$(arch_type_label "$host" "$is_pi" "$is_amp" "$is_win")"

  # ---- IMPORTANT: match bakery folder naming inside archives ----
  local bin_subdir="${COIN_NAME}-v${VERSION}"
  local out_dir="${BUILD_BASE}/${bin_subdir}"

  # ---- Depends clean & rebuild ----
  pushd "$DEPENDSDIR" >/dev/null
  did_push_dep=1

  make clean     >/dev/null 2>&1 || true
  make distclean >/dev/null 2>&1 || true

  log "Depends build log -> ${BUILD_DEPENDS_LOG}/${tag}.main.log"
  make -j"$(nproc)" HOST="$host" "${depends_flags[@]}" 2>&1 | tee "${BUILD_DEPENDS_LOG}/${tag}.main.log"
  for t in error warning fail; do
    grep -i -C 3 "$t" "${BUILD_DEPENDS_LOG}/${tag}.main.log" > "${BUILD_DEPENDS_LOG}/${tag}.${t}.log" || true
  done
  popd >/dev/null
  did_push_dep=0

  # ---- Main clean, autogen, configure, build ----
  pushd "$REPO_ROOT" >/dev/null
  did_push_repo=1

  make clean     >/dev/null 2>&1 || true
  make distclean >/dev/null 2>&1 || true

  ./autogen.sh 2>&1 | tee "${BUILD_LOG}/${tag}.autogen.log"

  local cfg_flags=()
  [[ "${qt,,}" == "n" ]] && cfg_flags+=(--with-gui=no)

  # Use depends config.site + explicit host (important for cross targets)
  local config_site="${DEPENDSDIR}/${host}/share/config.site"
  [[ -f "$config_site" ]] || err "CONFIG_SITE missing (${config_site}) — configure may fail for cross targets."

  log "Configure log -> ${BUILD_LOG}/${tag}.configure.log"
  CONFIG_SITE="$config_site" ./configure \
    --prefix=/ \
    --host="$host" \
    "${cfg_flags[@]}" 2>&1 | tee "${BUILD_LOG}/${tag}.configure.log"

  log "Build log -> ${BUILD_LOG}/${tag}.main.log"
  make -j"$(nproc)" 2>&1 | tee "${BUILD_LOG}/${tag}.main.log"

  for t in error warning fail; do
    grep -i -C 3 "$t" "${BUILD_LOG}/${tag}.main.log" > "${BUILD_LOG}/${tag}.${t}.log" || true
  done

  # ---- Determine binaries to package ----
  local binfiles=()
  if [[ "$is_win" == "true" ]]; then
    if [[ "${qt,,}" == "y" ]]; then
      binfiles=("${COIN_NAME}-cli.exe" "${COIN_NAME}d.exe" "qt/${COIN_NAME}-qt.exe")
    else
      binfiles=("${COIN_NAME}-cli.exe" "${COIN_NAME}d.exe")
    fi
  else
    if [[ "${qt,,}" == "y" ]]; then
      binfiles=("${COIN_NAME}-cli" "${COIN_NAME}d" "qt/${COIN_NAME}-qt")
    else
      binfiles=("${COIN_NAME}-cli" "${COIN_NAME}d")
    fi
  fi

  rm -rf "$out_dir"
  mkdir -p "$out_dir" "$COMPRESS_DIR" "$SPECIAL_DELIVERY"

  for b in "${binfiles[@]}"; do
    [[ -f "src/${b}" ]] || die "Missing binary: ${REPO_ROOT}/src/${b}"
    cp "src/${b}" "$out_dir/"
  done
  popd >/dev/null
  did_push_repo=0

  # ---- Strip (optional) ----
  if [[ "$STRIP_BINARIES" == "1" ]]; then
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
    "$strip_tool" "$out_dir"/* >/dev/null 2>&1 || err "strip failed (continuing)"
  else
    log "STRIP_BINARIES=0 (skipping strip)"
  fi

  # ---- Checksums inside tree (per-build) ----
  local checksum_file="${out_dir}/checksums-${VERSION}.txt"
  : > "$checksum_file"
  echo "sha256sum:" >> "$checksum_file"
  (cd "$BUILD_BASE" && find "$bin_subdir" -type f -exec sha256sum {} \;) >> "$checksum_file" 2>/dev/null || true
  echo "openssl-sha256:" >> "$checksum_file"
  (cd "$BUILD_BASE" && find "$bin_subdir" -type f -exec openssl dgst -sha256 -r {} \;) >> "$checksum_file" 2>/dev/null || true

  # ---- Archive name and compress (match bakery convention) ----
  local os_label archive_name
  os_label="$(detect_os_label)"

  if [[ "$is_win" == "true" ]]; then
    archive_name="${COIN_NAME}-Generic-${arch_label}-${RELEASE_SUFFIX}-${VERSION}.zip"
    (cd "$BUILD_BASE" && zip -r "${COMPRESS_DIR}/${archive_name}" "$bin_subdir") >/dev/null
  else
    archive_name="${COIN_NAME}-${os_label}_${arch_label}-${RELEASE_SUFFIX}-${VERSION}.tar.gz"
    (cd "$BUILD_BASE" && tar -cf - "$bin_subdir" | gzip -9 > "${COMPRESS_DIR}/${archive_name}")
  fi

  mv -f "${COMPRESS_DIR}/${archive_name}" "$SPECIAL_DELIVERY/"
  log "Baked & packaged: ${SPECIAL_DELIVERY}/${archive_name}"
  printf "%s [INFO]  artifact=%s target=%s host=%s qt=%s\n" "$(ts)" "${archive_name}" "${friendly}" "${host}" "${qt}" >> "$SUMMARY_LOG"
}

# --- Build loop (enabled targets) ---
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  [[ "$line" =~ ^[[:space:]]*# ]] && continue

  IFS=',' read -r friendly enabled qtfield <<< "$line"
  [[ "${enabled,,}" != "y" ]] && continue

  qt="${qtfield#QT=}"
  qt="${qt,,}"

  read -r host is_pi is_amp is_win <<<"$(map_target "$friendly")"
  [[ "$host" == "unknown" ]] && { err "Skipping unknown: $friendly"; continue; }

  build_target "$friendly" "$host" "$qt" "$is_pi" "$is_amp" "$is_win"
done < "$RECIPE_BOOK"

# --- Final global checksums (for everything in special-delivery) ---
GLOBAL_SUM="${SPECIAL_DELIVERY}/checksums-${VERSION}.txt"
: > "$GLOBAL_SUM"

shopt -s nullglob
for f in "${SPECIAL_DELIVERY}"/*.tar.gz "${SPECIAL_DELIVERY}"/*.zip; do
  echo "sha256sum: $(sha256sum "$f")" >> "$GLOBAL_SUM" || err "sha256sum failed for $f"
  echo "openssl-sha256: $(openssl dgst -sha256 -r "$f")" >> "$GLOBAL_SUM" || err "openssl sha256 failed for $f"
done

log "Wrote global checksums -> ${GLOBAL_SUM}"
log "Batch complete. Artifacts in ${SPECIAL_DELIVERY}"
log "Run summary: ${SUMMARY_LOG}"
