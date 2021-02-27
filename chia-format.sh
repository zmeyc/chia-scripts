#!/bin/bash
set -euo pipefail

APPNAME=chia-format

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
    echo "  ext4-single <device> <label>"
    echo ""
    echo "    Initialize a single partition spanning entire disk,"
    echo "    label with 'label'"
    echo ""
    echo "  ext4-tmp-dest <device> <label-prefix>"
    echo ""
    echo "    Initialize two partitions: tmp (350 gb) and the rest"
    echo "    of disk. Label with 'label't and 'label'd"
    echo ""
    echo "Example:"
    echo "  chia-format ext4-tmp-dest /dev/sdzzz wd14-01"
    echo ""
    exit 1
  fi
}

ext4_format() {
  [ "$#" -eq 2 ] || fatal "ext4_format: expected device name and label"
  local dev_name="$1"
  local label="$2"

  mkfs.ext4 -F -T largefile4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0 -O ^has_journal -L "${label}" "${dev_name}"
}

do_ext4_single() {
  [ "$#" -eq 2 ] || fatal "Expected device name and label."
  local dev_name="$1"
  local label="$2"

  ext4_format "${dev_name}" "${label}"
}

do_ext4_tmp_dest() {
  [ "$#" -eq 2 ] || fatal "Expected device name and label."
  local dev_name="$1"
  local label="$2"

  /sbin/parted "${dev_name}" mklabel gpt --script
  /sbin/parted "${dev_name}" mkpart primary 0% 350GiB --script
  /sbin/parted "${dev_name}" mkpart primary 350GiB 100% --script
  sleep 1
  ext4_format "${dev_name}1" "${label}t"
  ext4_format "${dev_name}2" "${label}d"
}

[ "$#" -ge 1 ] || {
  usage
  exit 1
}

subcommand="$1"
shift

case "$subcommand" in
ext4-single)
  do_ext4_single "$@"
  ;;
ext4-tmp-dest)
  do_ext4_tmp_dest "$@"
  ;;
*)
  fatal "Unknown subcommand $subcommand"
  ;;
esac

