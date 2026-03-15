#!/usr/bin/env bash
set -euo pipefail

[[ "${BASH_SOURCE[0]}" != "$0" ]] || {
  echo "[ERROR] asset_pull.sh is a library and should be sourced, not executed directly..." >&2
  exit 1
}

# --- Paths --- #

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LOCAL_KITCHEN_LIB="${SCRIPT_DIR}/assets/kitchen.lib"
FIRST_RUN_APP="${SCRIPT_DIR}/first_run"
BAKE_OPT_ROOT="/opt/bake"
OPT_BAKE_INFO="${BAKE_OPT_ROOT}/bake.info"
OPT_KITCHEN_LIB="${BAKE_OPT_ROOT}/kitchen.lib"

fetch_kitchen_lib_from_github() {
  local tmp_file="/tmp/kitchen.lib.$$"
  local fetched=""

  if command -v curl >/dev/null 2>&1; then
    for ref in dev release; do
      curl -fsSL \
        "https://raw.githubusercontent.com/Nikovash/bake/${ref}/assets/kitchen.lib" \
        -o "$tmp_file" && fetched="yes" && break || true
    done
  elif command -v wget >/dev/null 2>&1; then
    for ref in dev release; do
      wget -qO "$tmp_file" \
        "https://raw.githubusercontent.com/Nikovash/bake/${ref}/assets/kitchen.lib" \
        && fetched="yes" && break || true
    done
  fi

  [[ "${fetched:-}" == "yes" && -s "$tmp_file" ]]
}

read_kitchen_version_from_file() {
  local file="$1"
  [[ -f "$file" ]] || return 1

  grep -E '^[[:space:]]*KITCHEN_LIB_VERSION[[:space:]]*=' "$file" \
    | head -n1 \
    | cut -d= -f2- \
    | tr -d '"' \
    | tr -d "'" \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

read_kitchen_version_from_info() {
  [[ -f "$OPT_BAKE_INFO" ]] || return 1

  grep -E '^KITCHEN_LIB_VERSION=' "$OPT_BAKE_INFO" \
    | head -n1 \
    | cut -d= -f2-
}

set_info_value() {
  local key="$1"
  local value="$2"

  sudo touch "$OPT_BAKE_INFO"

  if grep -qE "^${key}=" "$OPT_BAKE_INFO"; then
    sudo sed -i "s|^${key}=.*|${key}=${value}|" "$OPT_BAKE_INFO"
  else
    echo "${key}=${value}" | sudo tee -a "$OPT_BAKE_INFO" >/dev/null
  fi
}

install_local_kitchen_to_opt() {
  [[ -f "$LOCAL_KITCHEN_LIB" ]] || return 1

  sudo mkdir -p "$BAKE_OPT_ROOT"
  sudo cp -f "$LOCAL_KITCHEN_LIB" "$OPT_KITCHEN_LIB"
  sudo chmod 644 "$OPT_KITCHEN_LIB"

  local ver
  ver="$(read_kitchen_version_from_file "$LOCAL_KITCHEN_LIB" || true)"
  [[ -n "${ver:-}" ]] && set_info_value KITCHEN_LIB_VERSION "$ver"

  [[ -f "$OPT_KITCHEN_LIB" ]]
}

install_downloaded_kitchen_to_opt() {
  local tmp_file="/tmp/kitchen.lib.$$"
  [[ -f "$tmp_file" ]] || return 1

  sudo mkdir -p "$BAKE_OPT_ROOT"
  sudo cp -f "$tmp_file" "$OPT_KITCHEN_LIB"
  sudo chmod 644 "$OPT_KITCHEN_LIB"

  mkdir -p "${SCRIPT_DIR}/assets"
  cp -f "$tmp_file" "$LOCAL_KITCHEN_LIB" 2>/dev/null || true

  local ver
  ver="$(read_kitchen_version_from_file "$tmp_file" || true)"
  [[ -n "${ver:-}" ]] && set_info_value KITCHEN_LIB_VERSION "$ver"

  rm -f "$tmp_file"
  [[ -f "$OPT_KITCHEN_LIB" ]]
}

upgrade_opt_kitchen_if_needed() {
  [[ -f "$LOCAL_KITCHEN_LIB" ]] || return 0
  [[ -f "$OPT_KITCHEN_LIB" ]] || return 0

  local repo_ver opt_ver
  repo_ver="$(read_kitchen_version_from_file "$LOCAL_KITCHEN_LIB" || true)"
  opt_ver="$(read_kitchen_version_from_file "$OPT_KITCHEN_LIB" || read_kitchen_version_from_info || true)"

  [[ -n "${repo_ver:-}" ]] || return 0
  [[ "$repo_ver" == "${opt_ver:-}" ]] && return 0

  echo "[Bake] Updating system kitchen.lib -> ${repo_ver}"
  sudo cp -f "$LOCAL_KITCHEN_LIB" "$OPT_KITCHEN_LIB"
  sudo chmod 644 "$OPT_KITCHEN_LIB"
  set_info_value KITCHEN_LIB_VERSION "$repo_ver"
}

repair_opt_runtime_if_needed() {
  [[ -f "$OPT_BAKE_INFO" ]] || return 1
  [[ -f "$OPT_KITCHEN_LIB" ]] && return 0

  if install_local_kitchen_to_opt; then
    return 0
  fi

  fetch_kitchen_lib_from_github && install_downloaded_kitchen_to_opt
}

ensure_kitchen_lib() {
  if [[ -f "$OPT_KITCHEN_LIB" ]]; then
    upgrade_opt_kitchen_if_needed
    return 0
  fi

  if repair_opt_runtime_if_needed; then
    upgrade_opt_kitchen_if_needed
    return 0
  fi

  if [[ ! -f "$OPT_BAKE_INFO" ]]; then
    if [[ -x "$FIRST_RUN_APP" ]]; then
      "$FIRST_RUN_APP" -r
      if [[ -f "$OPT_KITCHEN_LIB" ]]; then
        upgrade_opt_kitchen_if_needed
        return 0
      fi
    fi
  fi

  if install_local_kitchen_to_opt; then
    upgrade_opt_kitchen_if_needed
    return 0
  fi

  if fetch_kitchen_lib_from_github && install_downloaded_kitchen_to_opt; then
    upgrade_opt_kitchen_if_needed
    return 0
  fi

  rm -f "/tmp/kitchen.lib.$$" 2>/dev/null || true
  echo "[ERROR] Could not obtain kitchen.lib." >&2
  exit 1
}
