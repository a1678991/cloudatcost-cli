#!/bin/bash
# !!!! set $MAIL and $KEY !!!!

if [ -z "$MAIL" ] || [ -z "$KEY" ]; then
        echo "Please set MAIL and KEY!!"
        exit
fi
if which jq >/dev/null 2>&1; then

check_response ()
{
	echo "What are you?"
	echo "↓↓↓"
	echo $RESPONSE
	echo "↑↑↑"
	STATUS=`echo $RESPONSE | jq .status`
	echo "and ..."
	echo "$STATUS"
	if [ $STATUS = "error" ]; then
		echo "Hello!!"
		DESCRIPTION=`echo $RETURN | jq .error_description`
		echo "Error occurred."
		echo "$DESCRIPTION"
		exit 1
	fi
	echo "I'm death"
	if [ $? -ne 0 ]; then
		echo "How are you?"
		exit 1
	fi
}
#show_usage ()
#{
#    echo "Usage:"
#    echo "  -m MailAdress"
#    echo "  -k api key"
#    echo "  -l list servers"
#    echo "  -r show resouces"
#    exit 1
#}
get_resources () {
	RESPONSE=`curl -k -s "https://panel.cloudatcost.com/api/v1/cloudpro/resources.php?key=$KEY&login=$MAIL"`
	check_response
	RESOURCES=`echo $RESPONSE | jq .data`
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
list_servers () {
	echo "I'm fine."
	RESPONSE=`curl -k -s -X GET "https://panel.cloudatcost.com/api/v1/listservers.php?key=$KEY&login=$MAIL"`
	check_response
	echo $RESPONSE | jq '.data[] | {SID: .sid, name: .servername, Mode: .mode, IP: .ip, OS: .template, Status: .status, Pass: .rootpass, Host: .hostname}'
	echo "Thank you."

}
show_resources () {
        get_resources
        echo "TotalCPU: $TOTAL_CPU UsedCPU: $USED_CPU AvailableCPU: $AVAILABLE_CPU"
        echo "TotalRAM: $TOTAL_RAM MB UsedRAM: $USED_RAM MB AvailableRAM: $AVAILABLE_RAM MB"
        echo "TotalSSD: $TOTAL_STORAGE GB UsedSSD: $USED_STORAGE GB AvailableSSD: $AVAILABLE_STORAGE GB"
}
select_server() {
	list_servers
	echo -n "Enter server SID :"
	read SID
}

#option
#while getopts :m:k:l:r:h opt
#do
#    case $opt in
#        m)      MAIL=$OPTARG
#                ;;
#        k)      KEY=$OPTARG
#                ;;
#        l)      list_servers && exit 0
#                ;;
#        r)      show_resources && exit 0
#                ;;
#        h)      show_usage
#                ;;
#        \?)     show_usage
#                ;;
#        esac
#done

if [ -z "$OPETYPE" ]; then
	echo -n "Choose oepration [B]uild/[L]istserver/[D]eleteserver/check[R]esources:/Run[M]ode/Enter[C]onsole :"
	read OPETYPE
fi
if [ $OPETYPE = "b" ] || [ $OPETYPE = "B" ]; then
	if [ -z "$OS" ]; then
		echo "OS List"
		RESPONSE=`curl -k -s "https://panel.cloudatcost.com/api/v1/listtemplates.php?key=$KEY&login=$MAIL"`
		check_response
		echo $RESPONSE |jq -r '.data[] | {ID: .ce_id, Detail: .name}'
		echo -n "Enter OS ID:"
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

	RESPONSE=`curl -k -s -X POST https://panel.cloudatcost.com/api/v1/cloudpro/build.php --data "key=$KEY&login=$MAIL&cpu=$CPU&ram=$RAM&storage=$STORAGE&os=$OS"`
	check_status
	echo $RESPONSE | jq .

elif [ $OPETYPE = "l" ] || [ $OPETYPE = "L" ]; then
	list_servers
elif [ $OPETYPE = "d" ] || [ $OPETYPE = "D" ]; then
	select_server
	if [ -z "$CONFIRM" ]; then
		echo "Really delete this server ?"
		echo "SID: $SID"
		echo -n "Y/N :"
		read CONFIRM
	fi
	if [ $CONFIRM = "y" ] || [ $CONFIRM = "Y" ]; then
		RESPONSE=`curl -k -s -X POST https://panel.cloudatcost.com/api/v1/cloudpro/delete.php --data "key=$KEY&login=$MAIL&sid=$SID"`
		echo $RESPONSE | jq
	fi
elif [ $OPETYPE = "r" ] || [ $OPETYPE = "R" ]; then
	show_resources
elif [ $OPETYPE = "m" ] || [ $OPETYPE = "M" ]; then
	select_server
	if [ -z "$MODE" ]; then
		echo -n "Enter mode [normal/safe] :"
		read MODE
	fi
	RESPONSE=`curl -k -s -X POST https://panel.cloudatcost.com/api/v1/runmode.php --data "key=$KEY&login=$MAIL&sid=$SID&mode=$MODE"`
	echo $RESPONSE | jq
elif [ $OPETYPE = "c" ] || [ $OPETYPE = "C" ]; then
	select_server
	RESPONSE=`curl -k -X POST https://panel.cloudatcost.com/api/v1/console.php --data "key=$KEY&login=$MAIL&sid=$SID"`
	check_response
	echo $RESPONSE | jq .
fi


else
	echo "Please install jq (https://stedolan.github.io/jq/)"
fi
