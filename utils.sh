#!/bin/bash
set -euo pipefail

fatal() {
  printf "%s\n" "$*" >&2
  exit 1
}

require() {
  [ "$#" -eq 2 ] || fatal "require: expected app name and text"
  local app_name="$1"
  local text="$2"

  command -v "${app_name}" >/dev/null 2>&1 || fatal "${text}"
}

