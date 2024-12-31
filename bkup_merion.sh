#!/bin/bash

read -p "Por favor, ingresa el serial de la orden: " orden
carpeta_salida="/data/purescale/smash/ipas.mgen/.zero/private/storagezoneStore/ipas/mgen/racks/9155-ABL\ $orden/mgmtSwitch/"

cd /data/purescale/smash/ipas.mgen/.zero/private/storagezoneStore/ipas/mgen/racks/*$orden/mgmtSwitch

config_bkup1="config_bkup1.txt"
config_bkup2="config_bkup2.txt"

touch "$config_bkup1"
touch "$config_bkup2"

> "$config_bkup1"
> "$config_bkup2"

archivo_switch1_json="1.json"
archivo_switch2_json="2.json"

ipv6_switch1=$(jq -r ".ula" "$archivo_switch1_json")
password=$(jq -c ".users[]" 1.json | jq -r ".password" | head -n 1)
echo "...Conectandose al switch AS4610_1..."
sshpass -p "$password" ssh -o StrictHostKeyChecking=no "CEUSER@${ipv6_switch1}" 'sudo net show configuration commands ' >> "$config_bkup1"
echo "Agregando:"
echo "sudo reboot" | tee -a $config_bkup1
echo "Al archivo $config_bkup1"

ipv6_switch2=$(jq -r ".ula" "$archivo_switch2_json")
password2=$(jq -c ".users[]" 2.json | jq -r ".password" | head -n 1)
echo "...Conectandose al switch AS4610_2..."
sshpass -p "$password2" ssh -o StrictHostKeyChecking=no "CEUSER@${ipv6_switch2}" 'sudo net show configuration commands ' >> "$config_bkup2"
echo "Agregando:"
echo "sudo reboot" | tee -a $config_bkup2
echo "Al archivo $config_bkup2"

echo "**** ¡¡¡Backups creados!!! ****"

echo "**** Los backup se han guardado en $carpeta_salida ****"