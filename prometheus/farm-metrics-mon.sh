#!/bin/bash
set -euo pipefail
script_root="$(cd "$(dirname "$(readlink "$([[ "${OSTYPE}" == linux* ]] && echo "-f")" "$0")")"; pwd)"
source "${script_root}/../lib/utils.sh"

APPNAME=farm-metrics-collector

extract_number() {
  grep -Eo '[+-]?[0-9]+([.][0-9]+)?'
}

get_farming_status() {
  printf "%s" "$1" | sed -n -e 's/^Farming status: \([.[:alnum:]]\+\).*/\1/p'
}

get_total_chia_farmed() {
  printf "%s" "$1" | sed -n -e 's/^Total chia farmed: \([.[:alnum:]]\+\).*/\1/p'
}

get_user_transaction_fees() {
  printf "%s" "$1" | sed -n -e 's/^User transaction fees: \([.[:alnum:]]\+\).*/\1/p'
}

get_block_rewards() {
  printf "%s" "$1" | sed -n -e 's/^Block rewards: \([.[:alnum:]]\+\).*/\1/p'
}

get_last_height_farmed() {
  printf "%s" "$1" | sed -n -e 's/^Last height farmed: \([.[:alnum:]]\+\).*/\1/p'
}

get_plot_count() {
  printf "%s" "$1" | sed -n -e 's/^Plot count: \([.[:alnum:]]\+\).*/\1/p'
}

get_total_size_of_plots_tib() {
  printf "%s" "$1" | sed -n -e 's/^Total size of plots: \([.[:alnum:]]\+\).*/\1/p'
}

get_estimated_network_space_pib() {
  printf "%s" "$1" | sed -n -e 's/^Estimated network space: \([.[:alnum:]]\+\).*/\1/p'
}

get_expected_time_to_win_hours() {
  printf "%s" "$1" | sed -n -e 's/^Expected time to win: \([.[:alnum:]]\+\).*/\1/p'
}

is_farming() {
  if [ "$(get_farming_status "$1")" == "Farming" ]; then
    echo "1"
  else
    echo "0"
  fi
}

chia="${HOME}/chia-blockchain/venv/bin/chia"

summary="$("${chia}" farm summary)"

printf "farm__farming_status %s\n" "$(get_farming_status "${summary}")"
printf "farm__total_chia_farmed %s\n" "$(get_total_chia_farmed "${summary}")"
printf "farm__user_transaction_fees %s\n" "$(get_user_transaction_fees "${summary}")"
printf "farm__block_rewards %s\n" "$(get_block_rewards "${summary}")"
printf "farm__last_height_farmed %s\n" "$(get_last_height_farmed "${summary}")"
printf "farm__plot_count %s\n" "$(get_plot_count "${summary}")"
printf "farm__total_size_of_plots_tib %s\n" "$(get_total_size_of_plots_tib "${summary}")"
printf "farm__estimated_network_space_pib %s\n" "$(get_estimated_network_space_pib "${summary}")"
printf "farm__expected_time_to_win_hours %s\n" "$(get_expected_time_to_win_hours "${summary}")"
printf "is_farming %s\n" "$(is_farming "${summary}")"
printf "plotters_active %s\n" "$(screen -ls | grep "chia-" | wc -l)"
printf "mounted_partitions_count %s\n" "$(mount|grep /mnt/|wc -l)"

