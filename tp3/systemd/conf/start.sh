#!/bin/bash
# Thomas
# 09/10/2020
# Script de start backup

target_dir="${1}"
target_path="$(echo "${target_dir%/}" | awk -F "/" 'NF>1{print $NF}')"

date="$(date +%Y%m%d_%H%M%S)"
backup_name="${target_path}_${date}"
backup_dir="/opt/backups"
backup_path="${backup_dir}/${target_path}/${backup_name}.tar.gz"

if [[ ! -d "${backup_dir}/${target_path}" ]]
then
    mkdir "${backup_dir}/${target_path}"
fi

tar -czvf \
    ${backup_path} \
    ${target_dir} \
    1> /dev/null \
    2> /dev/null

if [[ $(echo $?) -ne 0 ]]
then
    echo "Une erreur est survenue lors de la compréssion" >&2
    exit 1
else
    echo "La compréssion à réussi dans ${backup_dir}/${target_path}" >&1
fi