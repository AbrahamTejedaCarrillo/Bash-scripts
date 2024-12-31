#!/bin/bash
read -p "Por favor, ingresa el serial de la orden: " orden

output_final="/root/evidencias/$orden"
rackjson="/data/purescale/smash/ipas.mgen/.zero/private/storagezoneStore/ipas/mgen/racks/*$orden"


if [ -d "$output_final" ];then
    echo 
else
    echo "**** CREANDO CARPETA DE EVIDENCIAS ****"
fi
    mkdir -p /root/evidencias/$orden






contraseñas_por_default(){

    echo "**** VERIFICANDO LAS CONTRASEÑAS EN EL ARCHIVO kickstart.json ****"
    echo
    archivo_evidencias="$output_final/evidencia_contrasenas.txt" 
    >"$archivo_evidencias"
    cd $rackjson
    echo "**** Ejecutando grep PASSW0RD kickstart.json ****"
    echo "**** Ejecutando grep PASSW0RD kickstart.json ****" >> "$archivo_evidencias"
    if grep -q PASSW0RD kickstart.json; then
        echo "-------->   Se encontraron coincidencias, favor de revisar   <--------" >> "$archivo_evidencias"
        echo "-------->   Se encontraron coincidencias, favor de revisar   <--------"
    else
        echo "-------->   No se encontraron coincidencias   <--------" >> "$archivo_evidencias"
        echo "-------->   No se encontraron coincidencias   <--------"
    fi

    echo
    echo >> "$archivo_evidencias"
    
    echo "**** Ejecutando grep Cumulus* kickstart.json ****"
    echo "**** Ejecutando grep Cumulus* kickstart.json ****" >> "$archivo_evidencias"
    if grep -q Cumulus* kickstart.json; then
        echo "-------->   Se encontraron coincidencias, favor de revisar   <--------" >> "$archivo_evidencias"
        echo "-------->   Se encontraron coincidencias, favor de revisar   <--------"
    else
        echo "-------->   No se encontraron coincidencias   <--------" >> "$archivo_evidencias"
        echo "-------->   No se encontraron coincidencias   <--------"
    fi
}

contraseñas_por_default
