curl "https://panel.cloudatcost.com/panel/_config/pop/ipv4.php?add=yes&SID=254871717" -s | cut -d ">" -f2 | cut -d "<" -f1
