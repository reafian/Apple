#! /bin/bash

resolv_status() {
	if grep -q fe80::46fe:3bff:fe36:3adb /etc/resolv.conf
  	then
		echo 1
	fi	
}

restart_network() {
	logger Wrong DNS Server - Restarting Network!
	networksetup -setairportpower en0 off
	sleep 5
	networksetup -setairportpower en0 on
}

while true
do
	logger Checking IPv6 DNS server
	status=$(resolv_status)
	if [[ $status == 1 ]]
	then
		restart_network
	fi
	sleep 300
done