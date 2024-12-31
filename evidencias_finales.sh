#!/bin/bash
#!/bin/expect -f
#Este script recolecta las evidencias finales de los sistemas abell
read -p "Por favor, ingresa el serial de la orden: " orden

output_final="/root/evidencias/$orden"
rackjson="/data/purescale/smash/ipas.mgen/.zero/private/storagezoneStore/ipas/mgen/racks/*$orden"

if [ -d "$output_final" ];then
    echo 
else
    echo "**** CREANDO CARPETA DE EVIDENCIAS ****"
fi
    mkdir -p /root/evidencias/$orden
    

reportlog(){
    cd /root/Documents/Report/
    echo "**** EJECUTANDO REPORT.LOG ****"
    ./report
    echo "**** AÑADIENDO REPORT.LOG A LAS EVIDENCIAS DEL SISTEMA ****"
    cp 9155-ABL\ $orden*.log $output_final
    provutility
}

provutility(){
    echo "**** COPIANDO PROVUTILITY.LOG A LAS EVIDENCIAS DEL SISTEMA ****"
    cd /data/purescale/smash/ipas.mgen/.zero/private/storagezoneStore/ipas/mgen/racks/*$orden
    archivo_rhel="rhel.json"
    yes="yes"
    user="kni"
    password="passw0rd"
    hostname=$(jq -r '.rhel[] | select(.type == "provisioner") | .ipv6' rhel.json)
    rm -rf /root/.ssh/known_hosts

    expect -c "
    spawn scp $user@\\[$hostname\\]:/home/kni/isfLogs/provutility.log $output_final
    expect {
            \"(yes/no)?\" {
                send \"$yes\r\"
                exp_continue
                }
                \"assword:\" {
                    send \"$password\r\"
                }
            }
    expect eof
    "

    cd $output_final
    mv provutility.log provutility_$orden.log
   
    vgen_cabling
}

vgen_cabling(){
    echo "**** COPIANDO VGEN_CABLING A LAS EVIDENCIAS DEL SISTEMA ****"
    cd /data/purescale/smash/ipas.mgen/logs/
    archivo_vgen=$(ls -t vgen_cabling_* | head -n 1)
    cp $archivo_vgen $output_final
    clag
}

clag(){
    echo "**** RECOLECTANDO CLAG ****"

    clag_merion="$output_final/clag_merions.txt"
    clag_tors="$output_final/clag_tors.txt"

    touch "$clag_merion"
    touch "$clag_tors"

    > "$clag_merion"
    > "$clag_tors"

#archivos json
    cd $rackjson/mgmtSwitch

    archivo_merion1_json="1.json"
    archivo_merion2_json="2.json"

#credenciales merion
    ipv6_merion1=$(jq -r ".ula" "$archivo_merion1_json")
    password_merion1=$(jq -c ".users[]" "$archivo_merion1_json" | jq -r ".password" | head -n 1)
    ipv6_merion2=$(jq -r ".ula" "$archivo_merion2_json")
    password_merion2=$(jq -c ".users[]" "$archivo_merion2_json" | jq -r ".password" | head -n 1)

    echo "**** MERION 1 ****" >> $clag_merion
    echo
    sshpass -p "$password_merion1" ssh -o StrictHostKeyChecking=no "CEUSER@${ipv6_merion1}" 'net show clag' >> "$clag_merion"
    echo
    echo "**** MERION 2 ****" >> $clag_merion
    echo
    sshpass -p "$password_merion2" ssh -o StrictHostKeyChecking=no "CEUSER@${ipv6_merion2}" 'net show clag' >> "$clag_merion"
    echo
 
    cd $rackjson/tor

    archivo_tor1_json="1.json"
    archivo_tor2_json="2.json"

#credenciales tor
    ipv6_tor1=$(jq -r ".ula" "$archivo_tor1_json")
    password_tor1=$(jq -c ".users[]" "$archivo_tor1_json" | jq -r ".password" | head -n 1)
    ipv6_tor2=$(jq -r ".ula" "$archivo_tor2_json")
    password_tor2=$(jq -c ".users[]" "$archivo_tor2_json" | jq -r ".password" | head -n 1)

#ejecutando clag

    echo "**** TOR 1 ****" >> "$clag_tors"
    echo 
    sshpass -p "$password_tor1" ssh -o StrictHostKeyChecking=no "CEUSER@${ipv6_tor1}" 'net show clag' >> "$clag_tors"
    echo 
    echo "**** TOR 2 ****" >> "$clag_tors"
    echo 
    sshpass -p "$password_tor2" ssh -o StrictHostKeyChecking=no "CEUSER@${ipv6_tor2}" 'net show clag' >> "$clag_tors"
    echo
    contraseñas_por_default
}

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
reportlog

echo
echo "**** COPIA EL SIGUIENTE SCRIP DESDE UN DIRECTORIO CONOCIDO DE TU LAPTOP ****"
echo "**** scp -r root@LAPTOPIP:$output_final . ****"