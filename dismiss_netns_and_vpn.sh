#!/bin/bash

source sources/extra.sh

function show_help 
 { 
 	c_print "Green" "This script dismisses network namespace <NAMESPACE> and stops transmission, socat, and openvpn"
 	c_print "Bold" "Example: sudo ./dismiss_netns.sh -p <SCRIPT_ROOT>"
 	c_print "Bold" "\t\t-p <SCRIPT_ROOT>: set here where the script is located. It is necessary if the main script is not called from the root directory of the script itself (Default: $HOME/torrentns)."
  c_print "Bold" "\t\t-n <NAMESPACE>: set here the namespace you want to delete! (Default: torrent)"

  exit
 }

NETNS=""
SCRIPT_ROOT=""
while getopts "h?p:n:" opt
 do
 	case "$opt" in
 	h|\?)
 		show_help
 		;;
 	p)
 		SCRIPT_ROOT=$OPTARG
 		;;
    n)
 		NETNS=$OPTARG
 		;;
 	*)
 		show_help
 		;;
 	esac
 done


if [ -z $SCRIPT_ROOT ]
	then
 		c_print "Yellow" "SCRIPT_ROOT not defined, fall back to defaults ($HOME/torrentns)"
        SCRIPT_ROOT="$HOME/torrentns"

 	else
	 	c_print "Green" "SCRIPT_ROOT set to ${SCRIPT_ROOT}"
fi

if [ -z $NETNS ]
	then
 		c_print "Yellow" "NAMESPACE not defined, fall back to defaults (torrent)"
        NETNS="torrent"
 	else
	 	c_print "Green" "NAMESPACE set to ${NETNS}"
fi


sudo ip netns del $NETNS
#vars defined in sources/extra.sh
sudo ifconfig $BRIDGE down
sudo brctl delbr $BRIDGE

c_print "White" "Remove all possible socat port forwarding"
for i in $(ps aux|grep "socat tcp-listen:9091,reuseaddr,fork tcp-connect:"|grep -v grep|awk '{print $2}')
do
  sudo kill -9 $i
done
c_print "BGreen" "[DONE]"
 
c_print "White" "Kill all possible transmission processes"
for i in $(ps aux|grep transmission|grep -v grep|awk '{print $2}')
do
  sudo kill -9 $i
done
#last resort
sudo /etc/init.d/transmission-daemon stop
sudo killall -HUP transmission-da
c_print "BGreen" "[DONE]"

#this also deletes $VETH_NS
sudo ip link delete $VETH_ROOT 

c_print "White" "Stopping openvpn..."
sudo pkill openvpn
c_print "BGreen" "[DONE]"