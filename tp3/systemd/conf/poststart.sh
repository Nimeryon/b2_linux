#!/bin/bash
# Thomas
# 09/10/2020
# Script de poststart backup

target_dir="${1}"
target_path="$(echo "${target_dir%/}" | awk -F "/" 'NF>1{print $NF}')"

date="$(date +%Y%m%d_%H%M%S)"
backup_name="${target_path}_${date}"
backup_dir="/opt/backup"
backup_path="${backup_dir}/${target_path}/${backup_name}.tar.gz"

if [[ $(ls "${backup_dir}/${target_path}" | wc -l) -gt max_backup_number ]]
then
    oldest_file=$(ls -t "${backup_dir}/${target_path}" | tail -1)
    rm -rf "${backup_dir}/${target_path}/${oldest_file}"
fi