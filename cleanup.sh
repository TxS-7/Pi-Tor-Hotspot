#!/bin/bash
# Based on: https://learn.adafruit.com/onion-pi/install-tor

GREEN='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RST='\033[0m'


####### TOR ########
echo -e "\n${BLUE}[*] Uninstalling tor${RST}"
sudo apt-get purge -y tor
sudo rm -rf /etc/tor/


####### IPTABLES #######
echo -e "\n${BLUE}[*] Removing iptables rules${RST}"
sudo iptables -F
sudo iptables -F -t nat
sudo rm /etc/iptables/rules.v4


####### NAT #######
echo -e "\n${BLUE}[*] Disabling NAT${RST}"
sudo sh -c "echo 0 > /proc/sys/net/ipv4/ip_forward"
sudo sed -i '/^net.ipv4.ip_forward=1$/d' /etc/sysctl.conf


####### INTERFACES #######
echo -e "\n${BLUE}[*] Restoring old interfaces${RST}"
sudo mv /etc/network/interfaces.bak /etc/network/interfaces


####### ISC DHCP SERVER #######
echo -e "\n${BLUE}[*] Uninstalling isc-dhcp-server${RST}"
sudo apt-get purge -y isc-dhcp-server


####### HOSTAPD #######
echo -e "\n${BLUE}[*] Uninstalling hostapd${RST}"
sudo apt-get purge -y hostapd
sudo rm -rf /etc/hostapd/

echo -e "\n${GREEN}[+] Done${RST}"
