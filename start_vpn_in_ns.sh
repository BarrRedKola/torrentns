#!/bin/bash

source sources/extra.sh

 
function show_help 
 { 
 	c_print "Green" "This script starts VPN connection in the namespace <NAMESPACE>"
 	c_print "Bold" "Example: sudo ./start_vpn_in_ns.sh -p <SCRIPT_ROOT> -n <NAMESPACE>"
 	c_print "Bold" "\t\t-p <SCRIPT_ROOT>: set here where the script is located. It is necessary if the main script is not called from the root directory of the script itself (Default: $HOME/torrentns)."
    c_print "Bold" "\t\t-n <NAMESPACE>: set here the namespace you want to be connected to VPN! (Default: torrent)"
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

c_print "White" "Start VPN connection..."
cd $SCRIPT_ROOT/nordVPN/
sudo ip netns exec $NETNS openvpn --daemon --config $SCRIPT_ROOT/nordVPN/sg498.ovpn
cd ..
#sudo nordvpn connect sg
c_print "BGreen" "[DONE]"

