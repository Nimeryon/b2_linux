#!/bin/bash
# Thomas
# 28/09/2020
# Script de backup avec une limite de 7 backups

target_dir="${1}"
target_path="$(echo "${target_dir%/}" | awk -F "/" 'NF>1{print $NF}')"

date="$(date +%Y%m%d_%H%M%S)"
backup_name="${target_path}_${date}"
backup_dir="/opt/backup"
backup_path="${backup_dir}/${target_path}/${backup_name}.tar.gz"

backup_useruid="1003"
max_backup_number=7

if [[ $UID -ne ${backup_useruid} ]]
then
    echo "Ce script doit être éxecuté avec l'utilisateur backup" >&2
    exit 1
fi

if [[ ! -d "${target_dir}" ]]
then
    echo "Le dossier spécifié n'existe pas !" >&2
    exit 1
fi

backup_folder ()
{
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
}

delete_outdated_backup ()
{
    if [[ $(ls "${backup_dir}/${target_path}" | wc -l) -gt max_backup_number ]]
    then
        oldest_file=$(ls -t "${backup_dir}/${target_path}" | tail -1)
        rm -rf "${backup_dir}/${target_path}/${oldest_file}"
    fi
}

backup_folder
delete_outdated_backup