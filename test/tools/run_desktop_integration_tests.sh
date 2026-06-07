#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

resolve_flutter_cmd() {
  if [[ -n "${FLUTTER_BIN:-}" ]]; then
    printf '%s\n' "$FLUTTER_BIN"
    return 0
  fi

  if command -v flutter >/dev/null 2>&1; then
    printf '%s\n' "flutter"
    return 0
  fi

  if command -v fvm >/dev/null 2>&1; then
    printf '%s\n' "fvm flutter"
    return 0
  fi

  echo "flutter executable not found. Add flutter to PATH, install fvm, or set FLUTTER_BIN." >&2
  exit 1
}

resolve_desktop_device() {
  if [[ -n "${DESKTOP_DEVICE:-}" ]]; then
    printf '%s\n' "$DESKTOP_DEVICE"
    return 0
  fi

  case "$(uname -s)" in
    Darwin)
      printf '%s\n' "macos"
      ;;
    Linux)
      printf '%s\n' "linux"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      printf '%s\n' "windows"
      ;;
    *)
      echo "Unsupported OS. Set DESKTOP_DEVICE explicitly to macos, linux, or windows." >&2
      exit 1
      ;;
  esac
}

FLUTTER_CMD="$(resolve_flutter_cmd)"
DESKTOP_DEVICE="$(resolve_desktop_device)"

cd "$ROOT_DIR"

run_test() {
  local test_path="$1"

  echo "== Running ${test_path} on ${DESKTOP_DEVICE} =="
  if [[ "$DESKTOP_DEVICE" == "macos" ]]; then
    set +e
    eval "$FLUTTER_CMD test \"$test_path\" -d \"$DESKTOP_DEVICE\"" \
      2> >(perl -pe 's/Failed to foreground app; open returned 1//g' >&2)
    local exit_code=$?
    set -e
  else
    set +e
    eval "$FLUTTER_CMD test \"$test_path\" -d \"$DESKTOP_DEVICE\""
    local exit_code=$?
    set -e
  fi
  return "$exit_code"
}

run_test integration_test/root/favorite_sync_flow_test.dart
run_test integration_test/watchlist/watchlist_flow_test.dart
