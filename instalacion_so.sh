#!/bin/bash
#!/bin/expect -f

sacar_macs(){
#obtener las mac address
    mac_cana=$(ipmitool -I lanplus -H 10.0.0.21 -U admin -P admin raw 0x3c 0x38 0x10 | cut -d ' ' -f9-14 | tr ' ' :)
    mac_canb=$(ipmitool -I lanplus -H 10.0.0.22 -U admin -P admin raw 0x3c 0x38 0x11 | cut -d ' ' -f9-14 | tr ' ' :)


    if [[ $? -ne 0 || -z $mac_cana ]]; then
        echo "Error: No se pudo obtener la direccion MAC del canister A"
        exit 1
    fi

    if [[ $? -ne 0 || -z $mac_canb ]]; then
        echo "Error: No se pudo obtener la direccion MAC del canister B"
        exit 1
    fi

    echo
    echo "**** MAC ADDRESS CANISTER A $mac_cana ****"
    echo "**** MAC ADDRESS CANISTER B $mac_canb ****"
    echo
}


crear_definiciones(){

    mkdef -f -t node ess35001a groups=all,ess3500_x86_64 mac="$mac_cana" netboot=xnba arch=x86_64
    mkdef -f -t node ess35001b groups=all,ess3500_x86_64 mac="$mac_canb" netboot=xnba arch=x86_64

    #verificar nodos y configurar dhcp
    lsdef -t node
    makedhcp ess35001a,ess35001b
    makedhcp ess35001a,ess35001b -q

    #selecicionar el so
    nodeset ess35001a,ess35001b osimage=rhels8.8-x86_64-install-ess3500
}


rm -rf /root/.ssh/known_hosts

#variables globales
user="root"
password="cluster"
password2="ibmesscluster"
psu1_expect="0023"
psu2_expect="0023"


fw_psuA(){

    psu1_out=$(ipmitool -I lanplus -H 10.0.0.21 -U admin -P admin fru print 4 | egrep -i 'Release' | cut -d "-" -f 2)
    psu2_out=$(ipmitool -I lanplus -H 10.0.0.21 -U admin -P admin fru print 5 | egrep -i 'Release' | cut -d "-" -f 2)

    if [[ $? -ne 0 || -z $psu1_out ]]; then
        echo "Error: No se pudo visualizar el FW de la PSU 1 desde el canister A"
        exit 1
    fi

    if [[ $? -ne 0 || -z $psu2_out ]]; then
        echo "Error: No se pudo visualizar el fw de la PSU 2 desde el canister A"
        exit 1
    fi


    if [[ "$psu1_out" == "$psu1_expect" && "$psu2_out" == "$psu2_expect" ]]; then

        echo 
        echo "**** REVISANDO LOS NIVELES DE FW DE LAS PSUS ****"
        echo
        echo "**** VISTA DESDE EL CANISTER A ****"
        echo "**** Versión de firmware de la PSU 1 $psu1_out correcta ****"
        echo "**** Versión de firmware de la PSU 2 $psu2_out correcta ****"
        echo
    else
        echo "XXXX Versión de firmware incorrecta XXXX"
        echo "PSU 1: Esperado $psu1_expect, Obtenido $psu1_out"
        echo "PSU 2: Esperado $psu2_expect, Obtenido $psu2_out"
        echo
        exit 1
    fi
}

fw_psuB(){
    psu1_out2=$(ipmitool -I lanplus -H 10.0.0.22 -U admin -P admin fru print 4 | egrep -i 'Release' | cut -d "-" -f 2)
    psu2_out2=$(ipmitool -I lanplus -H 10.0.0.22 -U admin -P admin fru print 5 | egrep -i 'Release' | cut -d "-" -f 2)

    if [[ $? -ne 0 || -z $psu1_out2 ]]; then
        echo "Error: No se pudo visualizar el FW de la PSU 1 desde el canister B"
        exit 1
    fi

    if [[ $? -ne 0 || -z $psu2_out2 ]]; then
        echo "Error: No se pudo visualizar el fw de la PSU 2 desde el canister B"
        exit 1
    fi


    if [[ "$psu1_out2" == "$psu1_expect" && "$psu2_out2" == "$psu2_expect" ]]; then
        echo "**** VISTA DESDE EL CANISTER B ****"
        echo "**** Versión de firmware de la PSU 1 $psu1_out2 correcta ****"
        echo "**** Versión de firmware de la PSU 2 $psu2_out2 correcta ****"
        echo
    else
        echo "XXXX Versión de firmware incorrecta XXXX"
        echo "PSU 1: Esperado $psu1_expect, Obtenido $psu1_out2"
        echo "PSU 2: Esperado $psu2_expect, Obtenido $psu2_out2"
        echo
        exit 1
    fi

}

bootorder_A(){
    echo
    echo "**** Seteando boot order canister A ****"
    echo
    expect -c "
    set timeout 10
        spawn ipmitool -I lanplus -H 10.0.0.21 -U admin -P admin sol deactivate
        spawn ipmitool -I lanplus -H 10.0.0.21 -U admin -P admin sol activate
        
        expect \"]\"
            send \"\r\"


            expect {
        \"#\" {
            send_user \"Prompt # detectado, ejecutando efibootmgr...\n\"
            send \"\r\"
            }
        \"login:\" {
            send_user \"Login detectado, ingresando usuario y contraseña...\n\"
            send \"$user\r\"
            expect \"assword:\" 
            send \"$password\r\"
                expect {
                    \"ogin incorrect\" {
                        send_user \"Login incorrecto, intentando con segunda contraseña...\n\"
                        send \"$user\r\"
                        expect \"assword:\" 
                        send \"$password2\r\"
                    }
                \"#\" {
                    send_user \"Inicio de sesión correcto.\n\"
                }
                timeout {
                    send_user \"Error: Tiempo de espera agotado.\n\"
                    exit 1
                }
            }
        }
        timeout {
            send_user \"Error: Tiempo de espera agotado al verificar el prompt.\n\"
            exit 1
        }
    }

        expect \"# \"
            send \"efibootmgr | grep -i pxe | tail -n -1 | cut -d ' ' -f1 | cut -d 't' -f 2 | tr '*' ' '\r\"

        expect \"# \"

        set raw_output \$expect_out(buffer);
        set clean_output [lindex [split \$raw_output \"\n\"] 1] ;
        set clean_output [string trim \$clean_output] ;

        expect \"#\"
            send \"efibootmgr -n \$clean_output\r\"

        expect \"#\"
            send \"exit\r\"

        expect eof
        "
}

bootorder_B(){
    echo
    echo "**** Seteando boot order canister B ****"
    echo
    expect -c "
    set timeout 10
        spawn ipmitool -I lanplus -H 10.0.0.22 -U admin -P admin sol deactivate
        spawn ipmitool -I lanplus -H 10.0.0.22 -U admin -P admin sol activate
        
        expect \"]\"
            send \"\r\"


            expect {
        \"#\" {
            send_user \"Prompt # detectado, ejecutando efibootmgr...\n\"
            send \"\r\"
        }
        \"login:\" {
            send_user \"Login detectado, ingresando usuario y contraseña...\n\"
            send \"$user\r\"
            expect \"assword:\" 
            send \"$password\r\"
            expect {
                \"ogin incorrect\" {
                    send_user \"Login incorrecto, intentando con segunda contraseña...\n\"
                    send \"$user\r\"
                    expect \"assword:\" 
                    send \"$password2\r\"
                }
                \"#\" {
                    send_user \"Inicio de sesión correcto.\n\"
                }
                timeout {
                    send_user \"Error: Tiempo de espera agotado.\n\"
                    exit 1
                }
            }
        }
        timeout {
            send_user \"Error: Tiempo de espera agotado al verificar el prompt.\n\"
            exit 1
        }
    }

        expect \"# \"
            send \"efibootmgr | grep -i pxe | tail -n -1 | cut -d ' ' -f1 | cut -d 't' -f 2 | tr '*' ' '\r\"

        expect \"# \"

        set raw_output \$expect_out(buffer);
        set clean_output [lindex [split \$raw_output \"\n\"] 1] ;
        set clean_output [string trim \$clean_output] ;

        expect \"#\"
            send \"efibootmgr -n \$clean_output\r\"

        expect \"#\"
            send \"exit\r\"

        expect eof
        "
}

reiniciar_canisters(){
    xdsh ess35001a,ess35001b "systemctl reboot"
}

while true; do
    echo "¿El sistema ingresa al sistema operativo?"
    echo -e "1) Si\n2) No"
    read -r -p "Elige una opcion: " elinput
    if [ "$elinput" -eq 1 ]; then
        sacar_macs
        crear_definiciones
        fw_psuA
        fw_psuB
        bootorder_A
        bootorder_B
        reiniciar_canisters
        exit 1
    elif [ "$elinput" -eq 2 ]; then
        echo "Ingresa las MAC adress de los canister"
        read  -r -p "MAC address canister A: " mac_cana
        read -r -p "MAC address canister B: " mac_canb
        crear_definiciones
        exit 1
        #esto se hizo pensando en la variable que se tenga que forzar la instalacion del sistema operativo
    else
        echo "Ingrese una entrada valida (1 o 2)" 
    fi
done



#script desarrollado por Abraham Tejeda y el team de TE'S ESS