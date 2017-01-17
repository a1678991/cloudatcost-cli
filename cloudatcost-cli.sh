#!/bin/bash
# !!!! set $MAIL and $KEY !!!!

if [ -z "$MAIL" ] || [ -z "$KEY" ]; then
        echo 'Please set $MAIL and $KEY!!'
        exit 1
fi
if which jq >/dev/null 2>&1; then

check_response ()
{
	STATUS=`echo $RESPONSE | jq .status | cut -d '"' -f 2`
	if [ $STATUS = error ]; then
		echo "Error occurred."
		echo $RESPONSE | jq .error_description
		exit 1
	elif [ $STATUS = ok ]; then
		echo "Success!!"
	else
		echo "Error"
		echo $STATUS
		echo $RESPONSE
		exit 1
	fi
}
show_usage ()
{
    echo "Usage:"
    echo "  -l list servers"
    echo "  -r show resouces"
    exit 0
}
get_resources () {
	RESPONSE=`curl -k -s "https://panel.cloudatcost.com/api/v1/cloudpro/resources.php?key=$KEY&login=$MAIL&ip_bypass=1"`
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
	RESPONSE=`curl -k -s -X GET "https://panel.cloudatcost.com/api/v1/listservers.php?key=$KEY&login=$MAIL&ip_bypass=1"`
	check_response
	echo $RESPONSE | jq '.data[] | {SID: .sid, name: .servername, vmname: .vmname, Mode: .mode, IP: .ip, OS: .template, Status: .status, Pass: .rootpass, Host: .hostname}'

}
list_tasks () {
	RESPONSE=`curl -k -s -X GET "https://panel.cloudatcost.com/api/v1/listtasks.php?key=$KEY&login=$MAIL&ip_bypass=1"`
	check_response
	echo $RESPONSE | jq .
}
show_resources () {
        get_resources
        echo "TotalCPU: $TOTAL_CPU UsedCPU: $USED_CPU AvailableCPU: $AVAILABLE_CPU"
        echo "TotalRAM: $TOTAL_RAM MB UsedRAM: $USED_RAM MB AvailableRAM: $AVAILABLE_RAM MB"
        echo "TotalSSD: $TOTAL_STORAGE GB UsedSSD: $USED_STORAGE GB AvailableSSD: $AVAILABLE_STORAGE GB"
}
select_server () {
	list_servers
	echo -n "Enter server SID :"
	read SID
}
list_ip () {
	select_server
	curl -k -s "https://panel.cloudatcost.com/panel/_config/pop/ipv4.php?SID=$SID"
}
add_ip () {
	select_server
	curl "https://panel.cloudatcost.com/panel/_config/pop/ipv4.php?add=yes&SID=$SID" -s | cut -d ">" -f2 | cut -d "<" -f1
}
#option
while getopts lrh opt
do
    case $opt in
        l)      OPETYPE=l
                ;;
        r)      OPETYPE=r
                ;;
        h)      show_usage
                ;;
        \?)	break
                ;;
        esac
done

if [ -z "$OPETYPE" ]; then
	echo -n "Choose oepration [B]uild/[L]istserver/[D]eleteserver/check[R]esources:/[P]ower/Run[M]ode/list[T]asks/Enter[C]onsole :"
	read OPETYPE
fi
if [ $OPETYPE = "b" ] || [ $OPETYPE = "B" ]; then
	if [ -z "$OS" ]; then
		echo -n "Enter DC{1-3}:"
		read DC
		echo "OS List"
		RESPONSE=`curl -k -s "https://panel.cloudatcost.com/api/v1/listtemplates.php?key=$KEY&login=$MAIL&ip_bypass=1"`
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

	RESPONSE=`curl -k -s -X POST https://panel.cloudatcost.com/api/v1/cloudpro/build.php --data "key=$KEY&login=$MAIL&datacenter=$DC&cpu=$CPU&ram=$RAM&storage=$STORAGE&os=$OS&ip_bypass=1"`
	check_response
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
		RESPONSE=`curl -k -s -X POST https://panel.cloudatcost.com/api/v1/cloudpro/delete.php --data "key=$KEY&login=$MAIL&sid=$SID&ip_bypass=1"`
		check_response
		echo $RESPONSE | jq
	fi
elif [ $OPETYPE = "r" ] || [ $OPETYPE = "R" ]; then
	show_resources
elif [ $OPETYPE = "p" ] || [ $OPETYPE = "P" ]; then
	select_server
	echo -n "Action [poweron ,poweroff, reset] :"
	read ACTION
	RESPONSE=`curl -k -s -X POST https://panel.cloudatcost.com/api/v1/powerop.php --data "key=$KEY&login=$MAIL&sid=$SID&action=$ACTION&ip_bypass=1"`
	check_response
	echo $RESPONSE | jq .
elif [ $OPETYPE = "m" ] || [ $OPETYPE = "M" ]; then
	select_server
	if [ -z "$MODE" ]; then
		echo -n "Enter mode [normal/safe] :"
		read MODE
	fi
	RESPONSE=`curl -k -s -X POST https://panel.cloudatcost.com/api/v1/runmode.php --data "key=$KEY&login=$MAIL&sid=$SID&mode=$MODE&ip_bypass=1"`
	echo $RESPONSE | jq .
elif [ $OPETYPE = "c" ] || [ $OPETYPE = "C" ]; then
	select_server
	RESPONSE=`curl -k -X POST https://panel.cloudatcost.com/api/v1/console.php --data "key=$KEY&login=$MAIL&sid=$SID&ip_bypass=1"`
	check_response
	echo $RESPONSE | jq .
elif [ $OPETYPE = "t" ] || [ $OPETYPE = "T" ]; then
        list_tasks
	echo $RESPONSE
fi
exit 0
else
	echo "Please install jq (https://stedolan.github.io/jq/)"
fi
