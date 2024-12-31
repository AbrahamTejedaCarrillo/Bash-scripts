#!/bin/bash

# Solicitamos el serial de la orden y lo guardo en la varaiable orden
read -p "Por favor, ingresa el serial de la orden: " orden

# Creamos el directorio de evidencias si no existe y lo guardo en la variable carpeta de evidencias
carpeta_evidencias="/root/evidencias"
if [ -d "$carpeta_evidencias" ]; then
echo "...Directorio de evidencias existe..."
echo "...Continuando..."
else
echo "...El directorio de evidencias no existe, creandolo..."
mkdir -p /root/evidencias
fi

#Creamos el directorio de la orden si no existe 
output_final="/root/evidencias/$orden"
if [ -d "$output_final" ];then
echo "...Ingresando a las evidencias del sistema..."
else
echo "...Creando evidencias del sistema..."
fi
mkdir -p /root/evidencias/$orden

# Definimos mi archivo de salida 
output_file="/root/evidencias/$orden/Discos_y_planares_$orden.txt"

# Limpiamos el archivo de salida si ya existe
> "$output_file"

# Cambiamos a la ruta donde se encuentran los archivos json del sistema (de donde tomaremos la información)
cd /data/purescale/smash/ipas.mgen/.zero/private/storagezoneStore/ipas/mgen/racks/*$orden

# Recorremos las carpetas que comienzan con "sr", las cuales contienen los archivos .json de los nodos
for directorio_sr in sr*/; do
    #verificamos que exista
    if [ -d "$directorio_sr" ]; then
        # Buscamos que haya archivos terminacion .json en la carpeta
        for archivos_nodos_json in "$directorio_sr"*.json; do
            #verificamos que existan
            if [ -f "$archivos_nodos_json" ]; then
                #Este cachito imprime en cual nodo se está haciendo la iteracion
                for nodo in $archivos_nodos_json; do
                    echo -e "\nDISCOS $nodo" >> "$output_file"
                done
                #jq sirve para leer archivos json, aqui lee el array que diga nvme(discos), la salida la guarda en la variable curly_discos
                jq -c '.nvme[]' "$archivos_nodos_json" | while read -r curly_discos; do
                    #guardamos las salidas de la lectura que hace jq en el bloque curly discos en cada uno de sus componentes
                    serialNumber=$(echo "$curly_discos" | jq -r '.serialNumber')
                    capacity=$(echo "$curly_discos" | jq -r '.capacity')
                    manufacture=$(echo "$curly_discos" | jq -r '.manufacture')
                    
                    # Concatenamos
                    Discos="$manufacture $serialNumber $capacity"
                    
                    # Escribimos las evidencias de discos en el archivo de salida
                    echo "$Discos" >> "$output_file"
                done
            fi
        done 
    fi
done

echo "...Revision de discos completada..."
echo "...Revisando las planares..."
cd /data/purescale/smash/ipas.mgen/.zero/private/storagezoneStore/ipas/mgen/racks/*$orden
archivo_rhel="rhel.json"
rm -rf /root/.ssh/known_hosts

jq -c '.rhel[]' "$archivo_rhel" | while read -r item_array; do
    hostname=$(echo "$item_array" | jq -r '.ipv6')
    locacion=$(echo "$item_array" | jq -r '.location')
    echo "$item_array" | jq -c '.users[]' | while read -r item_curly; do 
            user_rhel=$(echo "$item_curly" | jq -r '.user')
            password_rhel=$(echo "$item_curly" | jq -r '.password')   
    echo "...Conectandose a $locacion..."
    for rhel_del_nodo in $archivo_rhel; do
        echo -e "\nPlanar nodo $locacion" >> $output_file
        done
    sshpass -p "$password_rhel" ssh -o StrictHostKeyChecking=no "$user_rhel@${hostname}" 'sudo dmidecode -t 1' >> "$output_file" 2>> "$output_file"
    
    if [ $? -ne 0 ]; then
        echo "error al conectarse a $locacion"
    fi
    done
done

echo "las evidencias se han guardado en: $output_file"
echo "**** COPIA EL SIGUIENTE SCRIP DESDE UN DIRECTORIO CONOCIDO DE TU LAPTOP: *****"
echo "****>> scp root@ip_laptop:$output_file . <<****"
exit 0

