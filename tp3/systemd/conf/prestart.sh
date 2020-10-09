#!/bin/bash
# Thomas
# 09/10/2020
# Script de prestart backup

target_dir="${1}"
backup_useruid="1002"
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