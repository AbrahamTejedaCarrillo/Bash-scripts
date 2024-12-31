#!/bin/bash
#!/bin/expect -f

enter_lla(){
	echo "Enter node number:"
	read -r node_number
	node_llas=()
	for number in $(seq 1 "$node_number")
	do
		echo "Enter LLA of LM$((number+1))"
		read -r node_lla
		node_llas+=("$node_lla")
	done
	creating_lla "$node_llas"
}


creating_lla(){
	nodes="$1"	
	echo "Cambiando la contraseña del nodo: ${nodes[0]}"
	for node in "${node_llas[@]}"; do
    node_lla=${node:0:4}:${node:4:4}:${node:8:4}:${node:12:4}
		connecting_ssh "$node_lla"
	done
}

connecting_ssh(){
	user="USERID"
	#user="brayan"
	new_password="Poipoi09poipoipoi"
	old_password="PASSW0RD"
	port="enp0s25"
	comando_manish="accseccfg -am local -lp 0 -pe 0 -pew 0 -pc off -pl 8 -ci 0 -lf 0 -chgnew off -rc 0"
	comando_manish2="users -1 -n USERID -p PASSW0RD"
	yes="yes"
	lla=$1	
	rm -rf /root/.ssh/known_hosts

	expect -c "

	spawn ssh $user@fe80::$lla%enp0s25
	
	expect \"(yes/no)?\"
	send \"$yes\r\"

	expect \"assword:\"
	send \"$old_password\r\"
	
	expect \"assword:\"
        send \"$old_password\r\"
	
	expect \"New password:\"
	send \"$new_password\r\"

	expect \"Retype new password:\"
	send \"$new_password\r\"

	# Interactuar con la sesión para continuar si es necesario

	expect \"system>\"
	send \"$comando_manish\r\"

	expect \"system>\"
	send \"$comando_manish2\r\"
	expect eof

	"
}
enter_lla


exit

