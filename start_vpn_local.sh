#!/bin/bash

source sources/extra.sh

 
function show_help 
 { 
 	c_print "Green" "This script starts VPN connection locally"
 	c_print "Bold" "Example: sudo ./start_vpn_local.sh -p <SCRIPT_ROOT>"
 	c_print "Bold" "\t\t-p <SCRIPT_ROOT>: set here where the script is located. It is necessary if the main script is not called from the root directory of the script itself (Default: $HOME/torrentns)."
 	exit
 }

SCRIPT_ROOT=""
while getopts "h?p:" opt
 do
 	case "$opt" in
 	h|\?)
 		show_help
 		;;
 	p)
 		SCRIPT_ROOT=$OPTARG
 		;;
 
 	*)
 		show_help
 		;;
 	esac
 done


if [ -z $SCRIPT_ROOT ]
	then
 		c_print "Yellow" "SCRIPT_ROOT not defined, fall back to defaults ($HOME/torrentns)"
 	else
	 	c_print "Green" "SCRIPT_ROOT set to ${SCRIPT_ROOT}"
 fi


c_print "White" "Start VPN connection..."
cd $SCRIPT_ROOT/nordVPN/
sudo  openvpn --daemon --config $SCRIPT_ROOT/nordVPN/sg498.ovpn
cd ..
#sudo nordvpn connect sg
c_print "BGreen" "[DONE]"

