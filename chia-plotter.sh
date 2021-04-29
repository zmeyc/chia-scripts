#!/bin/bash
set -euo pipefail
script_root="$(cd "$(dirname "$(readlink "$([[ "${OSTYPE}" == linux* ]] && echo "-f")" "$0")")"; pwd)"
source "${script_root}/lib/utils.sh"

APPNAME=chia-plot

RESERVE_MEMORY_MB=6144

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
    echo "  plot <tmp-dir> [tmp2-dir] <dest-dir>"
    echo "    Plot to dest-dir using tmp-dir. Optionally specify tmp2-dir."
    echo ""
    echo "  list"
    echo "    List all plotting sessions."
    echo ""
    echo "  attach <tmp-dir>"
    echo "    Attach to a session related to specified tmp dir."
    echo ""
    echo "  kill <tmp-dir>"
    echo "    Kill a session related to specified tmp dir."
    echo ""
    echo "  kill-all"
    echo "    Kill all plotting sessions."
    echo ""
    echo "  clean <dir>"
    echo "    Clean all temporary files on specified disk."
    echo "    Be careful not to do this while plotting is"
    echo "    in progress."
    echo ""
    exit 1
  fi
}

get_total_memory_mb() {
  require calc "Please install calc: apt install calc"

  calc "floor($(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024)"
}

get_memory_for_plotting_mb() {
  local total
  total="$(get_total_memory_mb)"
  calc "${total} - ${RESERVE_MEMORY_MB}"
}

get_cpu_threads() {
  nproc --all
}

get_memory_for_single_plotter_mb() {
  local total
  total="$(get_memory_for_plotting_mb)"

  local cpu_theads
  cpu_threads="$(get_cpu_threads)"

  calc "${total} / ${cpu_threads}"
}

do_plot() {
  [ "$#" -eq 3 ] || [ "$#" -eq 2 ] || fatal "Expected tmp and dest dir names OR tmp, tmp2 and dest dir names"
  local tmp_dir
  local tmp2_dir
  local dest_dir
  if [ "$#" -eq 3 ]; then
    tmp_dir="$1"
    tmp2_dir="$2"
    dest_dir="$3"
  else
    tmp_dir="$1"
    tmp2_dir="${tmp_dir}"
    dest_dir="$2"
  fi

  require ts "Please install ts: apt install moreutils"
  require screen "Please install screen: apt install screen"

  if screen -list | grep -q "chia-$(basename "${tmp_dir}")"; then
    fatal "Session already exists"
  fi

  local total_memory
  total_memory="$(get_total_memory_mb)"

  local memory_for_plotting
  memory_for_plotting="$(get_memory_for_plotting_mb)"

  local cpu_theads
  cpu_threads="$(get_cpu_threads)"

  local memory_for_single_plotter
  memory_for_single_plotter="$(calc "min(3400, floor(${memory_for_plotting} / ${cpu_threads}))")"

  printf "Total memory (MB):              %d\n" "${total_memory}"
  printf "Memory for plotting (MB):       %d\n" "${memory_for_plotting}"
  printf "Number of CPU threads:          %d\n" "${cpu_threads}"
  printf "Memory for single plotter (MB): %d (2000 min, 3400 recomended)\n" "${memory_for_single_plotter}"
  printf "Tmp dir:                        %s\n" "${tmp_dir}"
  printf "Tmp2 dir:                       %s\n" "${tmp2_dir}"
  printf "Dest dir:                       %s\n" "${dest_dir}"
  echo ""

  echo "Starting plotting..."
  echo screen -dmS "chia-$(basename "${tmp_dir}")" "${script_root}/lib/run-single-plotter.sh" "${tmp_dir}" "${tmp2_dir}" "${dest_dir}" "${memory_for_single_plotter}"
  screen -dmS "chia-$(basename "${tmp_dir}")" "${script_root}/lib/run-single-plotter.sh" "${tmp_dir}" "${tmp2_dir}" "${dest_dir}" "${memory_for_single_plotter}"
}

do_list() {
  screen -ls | grep chia-
}

do_attach() {
  [ "$#" -eq 1 ] || fatal "Expected dir name"
  local dir="$1"

  screen -r "chia-$(basename "${dir}")"
}

do_kill() {
  [ "$#" -eq 1 ] || fatal "Expected dir name"
  local dir="$1"

  screen -XS "chia-$(basename "${dir}")" quit
}

do_kill_all() {
  screen -ls | grep chia- | cut -d. -f1 | awk '{print $1}' | xargs kill
}

do_clean() {
  [ "$#" -eq 1 ] || fatal "Expected dir name"
  local dir="$1"

  printf "Cleaning all temporary files on: %s\n" "${dir}"
  find "${dir}" -name "plot-*.tmp" -exec rm -f {} \;
}

[ "$#" -ge 1 ] || {
  usage
  exit 1
}

subcommand="$1"
shift

case "$subcommand" in
plot)
  do_plot "$@"
  ;;
list)
  do_list "$@"
  ;;
attach)
  do_attach "$@"
  ;;
kill)
  do_kill "$@"
  ;;
kill-all)
  do_kill_all "#@"
  ;;
clean)
  do_clean "$@"
  ;;
*)
  fatal "Unknown subcommand $subcommand"
  ;;
esac

