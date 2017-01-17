	curl "https://panel.cloudatcost.com/panel/_config/pop/ipv4.php?add=yes&SID=$SID" -s | cut -d ">" -f2 | cut -d "<" -f1
