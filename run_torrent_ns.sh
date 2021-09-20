#!/bin/bash
 
source sources/extra.sh

 
function show_help 
 { 
 	c_print "Green" "This script fires up a Linux networking namespace and starts a transmission server in it!"
	c_print "Green" "Within the namespace, openvpn is running (with nordVPN credentials) to hide torrent data, but only torrent data, from any eavesdropper (e.g., ISP)."
 	c_print "Bold" "Example: sudo ./run_torrent_ns.sh -p <SCRIPT_ROOT> -n <NAMESPACE>"
 	c_print "Bold" "\t\t-p <SCRIPT_ROOT>: set here where the script is located. It is necessary if the main script is not called from the root directory of the script itself (Default: $HOME/torrentns)."
	c_print "Bold" "\t\t-n <NAMESPACE>: set here the namespace you want to use! (Default: torrent)"
	c_print "Bold" "\t\t-t <TRANSMISSION_CONFIG_DIR>: set here the path to your transmission config dir! (Default: $HOME/.config/transmission-daemon/)"

	exit
 }


#the only variables we have to pay attention to
NETNS=""
SCRIPT_ROOT=""
TRANSMISSION_DIR=""


while getopts "h?p:n:t:" opt
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
 	t)
 		TRANSMISSION_DIR=$OPTARG
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

if [ -z $TRANSMISSION_DIR ]
	then
 		c_print "Yellow" "TRANSMISSION_DIR not defined, fall back to defaults ($HOME/.config/transmission-daemon)"
		TRANSMISSION_DIR="$HOME/.config/transmission-daemon"
 	else
	 	c_print "Green" "TRANSMISSION_DIR set to ${TRANSMISSION_DIR}"
fi



#this somehow crashes and won't continue :S
#c_print "White" "Dismiss previous starts..."
#sudo $SCRIPT_ROOT/dismiss_netns_and_vpn.sh -p $SCRIPT_ROOT -n $NETNS
#c_print "BGreen" "[DONE]"

c_print "White" "Create NS ${NETNS}..."
sudo ip netns add $NETNS
c_print "BGreen" "[DONE]"


c_print "White" "Create veth pairs..."
sudo ip link add $VETH_ROOT type veth peer name $VETH_NS
c_print "BGreen" "[DONE]"

c_print "White" "Add veth to ${NETNS}..."
sudo ip link set $VETH_NS netns $NETNS
c_print "BGreen" "[DONE]"



c_print "White" "Assign IPs to veths..."
sudo ip netns exec $NETNS ip addr add 172.16.1.100/24 dev $VETH_NS
sudo ip netns exec $NETNS ip link set dev $VETH_NS up
sudo ip netns exec $NETNS ip link set dev lo up
c_print "BGreen" "[DONE]"

c_print "White" "Create bridge..."
sudo brctl addbr $BRIDGE
sudo brctl addif $BRIDGE $VETH_ROOT
sudo ifconfig $BRIDGE 172.16.1.1 netmask 255.255.255.0 up
c_print "BGreen" "[DONE]"

c_print "White" "Add default gw to ${NETNS}..."
sudo ip netns exec $NETNS ip route add default via 172.16.1.1
sudo ifconfig $VETH_ROOT up
c_print "BGreen" "[DONE]"

c_print "White" "Add custom resolv.conf for google/cloudflare for ${NETNS}...it cannot use local one as ${NETNS} is in a VPN"
sudo mkdir -p /etc/netns/${NETNS}
sudo echo "nameserver 1.1.1.1" | sudo tee /etc/netns/${NETNS}/resolv.conf
sudo echo "nameserver 8.8.8.8" | sudo tee -a /etc/netns/${NETNS}/resolv.conf
c_print "BGreen" "[DONE]"


c_print "White" "Add internet access to the bridge/namespaces..."
sudo echo 1 |sudo tee /proc/sys/net/ipv4/ip_forward
sudo iptables -t nat -A POSTROUTING -s 172.16.1.0/24 -j MASQUERADE
c_print "BGreen" "[DONE]"


c_print "White" "Start transmission with config-dir ${TRANSMISSION_DIR}..."
sudo ip netns exec $NETNS transmission-daemon --config-dir $TRANSMISSION_DIR
c_print "BGreen" "[DONE]"

c_print "White" "Start socket between host namespace and network namespace..."
sudo socat tcp-listen:9091,reuseaddr,fork tcp-connect:172.16.1.100:9091 &
c_print "BGreen" "[DONE]"


#c_print "White" "Add 1.1.1.1 to /etc/resolv.conf otherwise namespace  $NETNS does not have domain resolution..."
#sudo echo "nameserver 1.1.1.1" |sudo tee -a /etc/resolv.conf
#c_print "BGreen" "[DONE]"


c_print "White" "Start openvpn connection!"
#sudo $SCRIPT_ROOT/start_vpn_local.sh -p $SCRIPT_ROOT
sudo $SCRIPT_ROOT/start_vpn_in_ns.sh -p $SCRIPT_ROOT  -n $NETNS
