#!/bin/bash
set -euo pipefail
script_root="$(cd "$(dirname "$(readlink "$([[ "${OSTYPE}" == linux* ]] && echo "-f")" "$0")")"; pwd)"

APPNAME=run-single-plotter

chia="${HOME}/chia-blockchain/venv/bin/chia"

TMP_DIR=${1?param missing - TMP_DIR}
TMP2_DIR=${2?param missing - TMP2_DIR}
DEST_DIR=${3?param missing - DEST_DIR}
BUFFER=${4?param missing - BUFFER}
K=${K:-32}
BUCKETS=${BUCKETS:-128}
THREADS=${THREADS:-2}
LOGS_DIR="${HOME}/chia-logs"

printf "Creating logs directory (if not exists): %s\n" "${LOGS_DIR}"
mkdir -p "${LOGS_DIR}"

stop_all_file="${HOME}/.chia-plotting-stop"
stop_single_file="${HOME}/.chia-plotting-stop-$(basename "${TMP_DIR}")"

log_filename_prefix="$(date +"%Y-%m-%d-%H-%M-%S")"

while true; do
  if [ "${TMP_DIR}" = "${TMP2_DIR}" ]; then
    "${script_root}/../chia-plotter.sh" clean "${TMP_DIR}"
    log_file="${LOGS_DIR}/${log_filename_prefix}--$(basename "${TMP_DIR}")--to--$(basename "${DEST_DIR}").txt"
  else
    "${script_root}/../chia-plotter.sh" clean "${TMP_DIR}"
    "${script_root}/../chia-plotter.sh" clean "${TMP2_DIR}"
    log_file="${LOGS_DIR}/${log_filename_prefix}--$(basename "${TMP_DIR}")--via--$(basename "${TMP2_DIR}")--to--$(basename "${DEST_DIR}").txt"
  fi

  echo "${chia}" plots create -k "${K}" -u "${BUCKETS}" -b "${BUFFER}" -r "${THREADS}" -t "${TMP_DIR}" -2 "${TMP2_DIR}" -d "${DEST_DIR}" >> "${log_file}"
  "${chia}" plots create -k "${K}" -u "${BUCKETS}" -b "${BUFFER}" -r "${THREADS}" -t "${TMP_DIR}" -2 "${TMP2_DIR}" -d "${DEST_DIR}" 2>&1 | ts '%Y-%m-%d %H:%M:%.S ' | tee -a "${log_file}"

  if [ -f "${stop_single_file}" ]; then
    echo "Found ${stop_single_file}, stopping."
    exit 0
  fi

  if [ -f "${stop_all_file}" ]; then
    echo "Found ${stop_all_file}, stopping."
    exit 0
  fi
done

