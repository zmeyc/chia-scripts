#!/bin/bash
set -euo pipefail
script_root="$(cd "$(dirname "$(readlink "$([[ "${OSTYPE}" == linux* ]] && echo "-f")" "$0")")"; pwd)"
source "${script_root}/lib/utils.sh"

APPNAME=chia-mount

usage() {
  if [ $# -eq 0 ]; then
    echo ""
    echo "${APPNAME}"
    echo ""
    echo "Usage:"
    echo ""
    printf "%s\n" "  ${APPNAME} <subcommand> [arguments]"
    echo ""
    echo "Where subcommand is:"
    echo ""
    echo "  add <device>   Add device to /etc/fstab and mount it by label."
    echo "                 Be sure to check /etc/fstab and make neccessary"
    echo "                 adjustments. Also create mount point and assign"
    echo "                 access rights to current user. Perform initial"
    echo "                 mounting. *** SHOULD BE CALLED ONCE ***"
    echo ""
    exit 1
  fi
}

do_add() {
  [ "$#" -eq 1 ] || fatal "Expected device name"
  local dev_name="$1"
  local label
  label="$(sudo e2label "${dev_name}")"
  printf "Disk label: %s\n" "${label}"

  local mountpoint
  mountpoint="/mnt/${label}"

  printf "Creating mountpoint: %s\n" "${mountpoint}"
  sudo mkdir -p "${mountpoint}"

  echo "Updating /etc/fstab"
  printf "LABEL=%s %s auto nosuid,nodev,nofail,noatime 0 0\n" "${label}" "${mountpoint}" | sudo tee -a /etc/fstab

  printf "Mounting: %s\n" "${mountpoint}"
  sudo mount "${mountpoint}"

  echo "Changing files ownership"
  sudo chown -R "$(id -u):$(id -g)" "${mountpoint}"

  echo "Done."
}

[ "$#" -ge 1 ] || {
  usage
  exit 1
}

subcommand="$1"
shift

case "$subcommand" in
add)
  do_add "$@"
  ;;
*)
  fatal "Unknown subcommand $subcommand"
  ;;
esac

