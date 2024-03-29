#!/bin/bash
# Based on: https://learn.adafruit.com/setting-up-a-raspberry-pi-as-a-wifi-access-point/install-software

GREEN='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RST='\033[0m'

CONFIG_DIR="./hotspot_config"
SSID="PiHotspot"
password="pihotspot123"

echo -n -e "${YELLOW}Update apt repositories? (Y/n)${RST} "
read -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]
then
	sudo apt-get -y update
fi


####### HOSTAPD #######
echo -e "\n${BLUE}[*] Installing hostapd to create wireless access point${RST}"
sudo apt-get -y install hostapd
echo -e "\n${BLUE}[*] Configuring the access point${RST}"
sudo cp ${CONFIG_DIR}/hostapd.conf /etc/hostapd/hostapd.conf
echo -e "SSID: $SSID"
sudo sed -i "s/{SSID}/${SSID}/" /etc/hostapd/hostapd.conf
echo -e "Password: $password"
sudo sed -i "s/{password}/${password}/" /etc/hostapd/hostapd.conf
sudo cp ${CONFIG_DIR}/default-hostapd /etc/default/hostapd


####### ISC DHCP SERVER #######
echo -e "\n${BLUE}[*] Installing isc-dhcp-server for DHCP on the access point${RST}"
sudo apt-get -y install isc-dhcp-server
sudo cp ${CONFIG_DIR}/dhcpd.conf /etc/dhcp/dhcpd.conf
sudo cp ${CONFIG_DIR}/default-isc-dhcp-server /etc/default/isc-dhcp-server


####### INTERFACES ########
echo -e "\n${BLUE}[*] Backing up old interfaces file to /etc/network/interfaces.bak${RST}"
sudo cp /etc/network/interfaces /etc/network/interfaces.bak
echo -e "\n${BLUE}[*] Configuring eth0 and wlan0 interfaces${RST}"
echo -e "${YELLOW}[!] Might lose connection for a while${RST}"
sudo cp ${CONFIG_DIR}/interfaces /etc/network/interfaces
sudo service networking restart
sudo ifconfig wlan0 192.168.42.1


####### NAT ########
echo -e "\n${BLUE}[*] Enabling Network Address Translation${RST}"
# Check if NAT is already enabled
grep "^net.ipv4.ip_forward=1$" /etc/sysctl.conf
if [ $? -ne 0 ]
then
	sudo sh -c "echo \"net.ipv4.ip_forward=1\" >> /etc/sysctl.conf"
fi
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"


######## IPTABLES ##########
echo -e "\n${BLUE}[*] Installing iptables-persistent${RST}"
sudo apt-get -y install iptables-persistent
echo -e "\n${BLUE}[*] Creating iptables forwarding rules"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
echo -e "${BLUE}[*] Saving the iptables rules${RST}"
sudo sh -c "iptables-save > /etc/iptables/rules.v4"


######## SERVICES #########
echo -e "\n${YELLOW}[*] Unmasking hostapd service${RST}"
sudo systemctl unmask hostapd.service
echo -e "\n${BLUE}[*] Starting the services${RST}"
sudo service hostapd restart
sudo service isc-dhcp-server restart
if [ $? -ne 0 ]
then
	echo -e "${RED}[!] Failed to start isc-dhcp-server. Removing /run/dhcpd.pid (https://lb.raspberrypi.org/forums/viewtopic.php?t=210310)${RST}"
	sudo rm /run/dhcpd.pid
	sudo service isc-dhcp-server restart
fi
echo -e "\n${GREEN}[+] hostapd status:${RST}"
service hostapd status
echo -e "\n${GREEN}[+] isc-dhcp-server status:${RST}"
service isc-dhcp-server status

echo -e "\n${BLUE}[*] Setting up services to start on boot${RST}"
sudo update-rc.d hostapd enable
sudo update-rc.d isc-dhcp-server enable

echo -e "\n${GREEN}[+] Finished installing hotspot${RST}"
