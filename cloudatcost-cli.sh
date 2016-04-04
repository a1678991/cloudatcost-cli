#!/bin/bash
# !!!! set MAIL and KEY !!!!
MAIL=
KEY=

if which jq >/dev/null 2>&1; then

get_resources () {
	RESOURCES=`curl -k -s "https://panel.cloudatcost.com/api/v1/cloudpro/resources.php?key=$KEY&login=$MAIL" | jq .data`
	TOTAL=`echo $RESOURCES | jq .total`
	USED=`echo $RESOURCES | jq .used`
	TOTAL_CPU=`echo $TOTAL | jq -r .cpu_total`
	TOTAL_RAM=`echo $TOTAL | jq -r .ram_total`
	TOTAL_STORAGE=`echo $TOTAL | jq -r .storage_total`
	USED_CPU=`echo $USED | jq -r .cpu_used`
	USED_RAM=`echo $USED | jq -r .ram_used`
	USED_STORAGE=`echo $USED | jq -r .storage_used`
	AVAILABLE_CPU=`expr $TOTAL_CPU - $USED_CPU`
	AVAILABLE_RAM=`expr $TOTAL_RAM - $USED_RAM`
	AVAILABLE_STORAGE=`expr $TOTAL_STORAGE - $USED_STORAGE`
}

if [ -z "$OPETYPE" ]; then
	echo -n "Choose oepration [B]uild/[L]istserver/[D]eleteserver(not yet)/check[R]esources:/Run[M]ode :"
	read OPETYPE
fi
if [ $OPETYPE = "b" ] || [ $OPETYPE = "B" ]; then
	if [ -z "$OS" ]; then
		echo "OS List"
		curl -k -s "https://panel.cloudatcost.com/api/v1/listtemplates.php?key=$KEY&login=$MAIL" |jq .data[] | jq -r  '{(.ce_id): .name}' |grep ":"
		echo -n "Enter OS number:"
		read OS
	fi
	get_resources
	if [ -z "$CPU" ]; then
		echo "TotalCPU: $TOTAL_CPU UsedCPU: $USED_CPU AvailableCPU: $AVAILABLE_CPU"
		echo -n "Enter CPU :"
		read CPU
	fi
	if [ -z "$RAM" ]; then
		echo "TotalRAM: $TOTAL_RAM MB UsedRAM: $USED_RAM MB AvailableRAM: $AVAILABLE_RAM MB"
		echo -n "Enter RAM (MB) :"
		read RAM
	fi
	if [ -z "$STORAGE" ]; then
		echo "TotalSSD: $TOTAL_STORAGE GB UsedSSD: $USED_STORAGE GB AvailableSSD: $AVAILABLE_STORAGE GB"
		echo -n "Enter SSD (GB) :"
		read STORAGE
	fi

	curl -k -s -X POST https://panel.cloudatcost.com/api/v1/cloudpro/build.php --data "key=$KEY&login=$MAIL&cpu=$CPU&ram=$RAM&storage=$STORAGE&os=$OS" |jq .
  
  
elif [ $OPETYPE = "l" ] || [ $OPETYPE = "L" ]; then
	SERVERLIST=`curl -k -s -X GET "https://panel.cloudatcost.com/api/v1/listservers.php?key=$KEY&login=$MAIL"`
	echo `echo $SERVERLIST | jq '.data[] | {SID: .sid, name: .servername, ip: .ip, OS: .template}'`
elif [ $OPETYPE = "d" ] || [ $OPETYPE = "D" ]; then
    echo "Creating..."
elif [ $OPETYPE = "r" ] || [ $OPETYPE = "R" ]; then
	get_resources
	echo "TotalCPU: $TOTAL_CPU UsedCPU: $USED_CPU AvailableCPU: $AVAILABLE_CPU"
	echo "TotalRAM: $TOTAL_RAM MB UsedRAM: $USED_RAM MB AvailableRAM: $AVAILABLE_RAM MB"
	echo "TotalSSD: $TOTAL_STORAGE GB UsedSSD: $USED_STORAGE GB AvailableSSD: $AVAILABLE_STORAGE GB"
elif [ $OPETYPE = "m" ] || [ $OPETYPE = "M" ]; then
	if [ -z "$SID" ]; then
	if [ -z "$MODE" ]; then
		echo "Server List"
		SERVERLIST=`curl -k -s -X GET "https://panel.cloudatcost.com/api/v1/listservers.php?key=$KEY&login=$MAIL"`
		echo `echo $SERVERLIST | jq '.data[] | {SID: .sid, name: .servername, ip: .ip, OS: .template}'`
		echo -n "Enter server SID:"
		read SID
		echo  "normal / safe"
		echo -n "Enter mode:"
		read MODE
	fi
	fi
	curl -X PUT https://panel.cloudatcost.com/api/v1/runmode.php --data "key=$KEY&login=$MAIL&sid=$SID&mode=$MODE"
fi
  
else
	echo "Please install jq (https://stedolan.github.io/jq/)"
fi
