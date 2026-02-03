#!/bin/bash
set -Eeuo pipefail

# ===========================
# Dishy The Kitchen Helper (dishy.sh)
# - Usage: ./dishy.sh [-c <coin>] [-i]
#   -c <coin>   : set coin name (default: bitoreum)
#   -i          : INIT mode — reset back to "fresh download" state:
#                 deletes:
#                   - $HOME/<coin>-build
#                   - ./special-delivery
#                   - ./run-logs
#                   - ./bakery.log
#                   - ./bake_bread.log ./bake_creampie.log ./previous_bake.log
#
# Environment knobs (optional):
#   DISHY_DRYRUN=1     : preview deletions (no changes)
#   DISHY_KEEP_LOGS=1  : preserve ./run-logs (ignored in INIT mode)
#   NO_COLOR=1         : disable terminal colors
# ===========================

usage() {
  cat <<EOF
Usage:
  $0 [-c <coin>] [-i] [-h]

Options:
  -c <coin>   Coin name (default: bitoreum)
  -i          INIT mode: delete \$HOME/<coin>-build and ALL local logs (fresh state)
  -h          Show help

Env:
  DISHY_DRYRUN=1     Preview deletions (no changes)
  DISHY_KEEP_LOGS=1  Preserve ./run-logs (ignored in INIT mode)
  NO_COLOR=1         Disable terminal colors

Examples:
  $0
  $0 -c yerbas
  $0 -c bitoreum -i
  DISHY_DRYRUN=1 $0 -c yerbas -i
EOF
}

COIN_NAME="bitoreum"
COIN_SET=0
INIT_MODE=0

while getopts ":c:ih" opt; do
  case "$opt" in
    c) COIN_NAME="$OPTARG"; COIN_SET=1 ;;
    i) INIT_MODE=1 ;;
    h) usage; exit 0 ;;
    :) echo "[ERROR] Option -$OPTARG requires an argument."; usage; exit 1 ;;
    \?) echo "[ERROR] Unknown option: -$OPTARG"; usage; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

# Back-compat: allow a single positional coin if -c not used
if [[ $# -gt 0 ]]; then
  if [[ $COIN_SET -eq 0 && $# -eq 1 ]]; then
    COIN_NAME="$1"
  else
    echo "[ERROR] Unexpected extra arguments: $*"
    usage
    exit 1
  fi
fi

RUN_DIR="$(pwd -P)"
[[ -n "$RUN_DIR" ]] || { echo "[ERROR] RUN_DIR is empty (refusing to continue)"; exit 1; }
[[ "$RUN_DIR" != "/" ]] || { echo "[ERROR] Refusing to run from /"; exit 1; }
[[ "$RUN_DIR" == /* ]] || { echo "[ERROR] RUN_DIR not absolute: $RUN_DIR"; exit 1; }

BUILD_DIR="$HOME/${COIN_NAME}-build"
SPECIAL_DELIVERY_DIR="$RUN_DIR/special-delivery"
LOG_ROOT="$RUN_DIR/run-logs"

BAKE_BREAD_LOG="$RUN_DIR/bake_bread.log"
BAKE_CREAMPIE_LOG="$RUN_DIR/bake_creampie.log"
BAKERY_LOG="$RUN_DIR/bakery.log"
PREVIOUS_BAKE_LOG="$RUN_DIR/previous_bake.log"

DRYRUN="${DISHY_DRYRUN:-0}"
KEEP_LOGS="${DISHY_KEEP_LOGS:-0}"

# INIT overrides KEEP_LOGS (init means wipe everything)
if [[ "$INIT_MODE" == "1" ]]; then
  KEEP_LOGS=0
fi

# --- Terminal colors only ---
if [[ -t 1 && "${NO_COLOR:-0}" != "1" ]]; then
  C_INFO=$'\033[1;32m'
  C_ERR=$'\033[1;31m'
  C_RST=$'\033[0m'
else
  C_INFO=""; C_ERR=""; C_RST=""
fi

log() { echo -e "${C_INFO}[INFO]${C_RST}  $*"; }
err() { echo -e "${C_ERR}[ERROR]${C_RST} $*" >&2; }
die() { err "$*"; exit 1; }

trap 'status=$?; err "dishy failed (exit $status) at line $LINENO: $BASH_COMMAND"; err "RUN_DIR=$RUN_DIR COIN_NAME=$COIN_NAME DRYRUN=$DRYRUN KEEP_LOGS=$KEEP_LOGS INIT_MODE=$INIT_MODE"; exit $status' ERR

# --- Safer rm wrappers ---
rm_safe() {
  local target="$1"
  [[ -n "$target" ]] || die "Refusing empty path"
  [[ "$target" != *$'\n'* ]] || die "Refusing path with newline: $target"

  if [[ "$DRYRUN" == "1" ]]; then
    log "[DRYRUN] would remove: $target"
    return 0
  fi

  rm -rf -- "$target"
}

rm_file_safe() {
  local target="$1"
  [[ -n "$target" ]] || die "Refusing empty path"
  [[ "$target" != *$'\n'* ]] || die "Refusing path with newline: $target"

  if [[ "$DRYRUN" == "1" ]]; then
    log "[DRYRUN] would remove file: $target"
    return 0
  fi

  rm -f -- "$target"
}

log "HEARD — coin: $COIN_NAME"
log "RUN_DIR: $RUN_DIR"
[[ "$DRYRUN" == "1" ]] && log "DRYRUN enabled — no deletions will occur."
[[ "$INIT_MODE" == "1" ]] && log "INIT mode enabled — full wipe (fresh download state)."

# ---------------------------
# INIT MODE: wipe everything
# ---------------------------
if [[ "$INIT_MODE" == "1" ]]; then
  # --- Remove BUILD_DIR (fresh download state) ---
  if [[ -d "$BUILD_DIR" ]]; then
    if [[ "$BUILD_DIR" == "$HOME/"* && "$BUILD_DIR" != "$HOME" && "$BUILD_DIR" != "/" ]]; then
      log "INIT: Removing build directory: $BUILD_DIR"
      rm_safe "$BUILD_DIR"
    else
      die "Refusing to remove unsafe path: $BUILD_DIR"
    fi
  else
    log "INIT: No build directory to remove: $BUILD_DIR"
  fi

  # --- Remove special-delivery (pinned) ---
  if [[ -d "$SPECIAL_DELIVERY_DIR" ]]; then
    [[ "$SPECIAL_DELIVERY_DIR" == "$RUN_DIR/special-delivery" ]] || die "Refusing unexpected path: $SPECIAL_DELIVERY_DIR"
    log "INIT: Removing special-delivery directory: $SPECIAL_DELIVERY_DIR"
    rm_safe "$SPECIAL_DELIVERY_DIR"
  else
    log "INIT: No special-delivery directory to remove: $SPECIAL_DELIVERY_DIR"
  fi

  # --- Remove run-logs (pinned) ---
  if [[ -d "$LOG_ROOT" ]]; then
    [[ "$LOG_ROOT" == "$RUN_DIR/run-logs" ]] || die "Refusing unexpected log root: $LOG_ROOT"
    log "INIT: Removing run logs: $LOG_ROOT"
    rm_safe "$LOG_ROOT"
  else
    log "INIT: No run-logs directory to remove: $LOG_ROOT"
  fi

  # --- Remove specific logs ---
  log "INIT: Shredding logs & wiping whiteboard, CHEF"
  rm_file_safe "$BAKE_BREAD_LOG"
  rm_file_safe "$BAKE_CREAMPIE_LOG"
  rm_file_safe "$PREVIOUS_BAKE_LOG"

  # --- Remove bakery.log (pinned) ---
  [[ "$BAKERY_LOG" == "$RUN_DIR/bakery.log" ]] || die "Refusing unexpected bakery log path: $BAKERY_LOG"
  rm_file_safe "$BAKERY_LOG"

  log "INIT complete. Fresh download state achieved, CHEF..."
  exit 0
fi

# ---------------------------------------
# NORMAL MODE: clean outputs + logs, keep build
# ---------------------------------------

# --- Remove special-delivery folder (pinned) ---
if [[ -d "$SPECIAL_DELIVERY_DIR" ]]; then
  [[ "$SPECIAL_DELIVERY_DIR" == "$RUN_DIR/special-delivery" ]] || die "Refusing unexpected path: $SPECIAL_DELIVERY_DIR"
  log "Removing special-delivery directory: $SPECIAL_DELIVERY_DIR"
  rm_safe "$SPECIAL_DELIVERY_DIR"
else
  log "No special-delivery directory to remove: $SPECIAL_DELIVERY_DIR"
fi

# --- Remove run-logs (pinned) ---
if [[ "$KEEP_LOGS" == "1" ]]; then
  log "KEEP_LOGS enabled — preserving run logs: $LOG_ROOT"
else
  if [[ -d "$LOG_ROOT" ]]; then
    [[ "$LOG_ROOT" == "$RUN_DIR/run-logs" ]] || die "Refusing unexpected log root: $LOG_ROOT"
    log "Removing run logs: $LOG_ROOT"
    rm_safe "$LOG_ROOT"
  else
    log "No run-logs directory to remove: $LOG_ROOT"
  fi
fi

# --- Remove specific logs ---
log "Shredding logs & wiping whiteboard, CHEF"
rm_file_safe "$BAKE_BREAD_LOG"
rm_file_safe "$BAKE_CREAMPIE_LOG"
rm_file_safe "$PREVIOUS_BAKE_LOG"

# --- Bakery log handling: truncate (pinned) ---
[[ "$BAKERY_LOG" == "$RUN_DIR/bakery.log" ]] || die "Refusing unexpected bakery log path: $BAKERY_LOG"

if [[ "$DRYRUN" == "1" ]]; then
  if [[ -f "$BAKERY_LOG" ]]; then
    log "[DRYRUN] would truncate: $BAKERY_LOG"
  else
    log "[DRYRUN] would create empty: $BAKERY_LOG"
  fi
else
  existed=0
  [[ -f "$BAKERY_LOG" ]] && existed=1
  : > "$BAKERY_LOG"
  ((existed)) && log "Truncated bakery.log" || log "Created empty bakery.log"
fi

log "The kitchen is clean, CHEF..."
