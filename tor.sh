#!/bin/bash
# Based on: https://learn.adafruit.com/onion-pi/install-tor

GREEN='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RST='\033[0m'

echo -n -e "${YELLOW}Install Wifi Hotspot? (Y/n)${RST} "
read -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]
then
	./hotspot.sh
else
	echo -n -e "${YELLOW}Update apt repositories? (Y/n)${RST} "
	read -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Nn]$ ]]
	then
		sudo apt-get -y update
	fi
fi


####### TOR ########
echo -e "\n${BLUE}[*] Installing and configuring tor${RST}"
sudo apt-get -y install tor
sudo cp torrc /etc/tor/torrc


####### IPTABLES #######
echo -e "\n${BLUE}[*] Saving previous iptables rules to /etc/iptables.bak${RST}"
sudo sh -c "iptables-save > /etc/iptables.bak"
if [ -f /etc/iptables/rules.v4 ]
then
	echo -e "\n${BLUE}[*] Saving previous iptables-persistent rules to /etc/iptables/rules.v4.bak${RST}"
	sudo cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.bak
fi

echo -e "\n${BLUE}[*] Removing old iptables rules and adding new rules${RST}"
sudo iptables -F
sudo iptables -F -t nat
sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 22 -j REDIRECT --to-ports 22
sudo iptables -t nat -A PREROUTING -i wlan0 -p udp --dport 53 -j REDIRECT --to-ports 53
sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --syn -j REDIRECT --to-ports 9040
sudo sh -c "iptables-save > /etc/iptables/rules.v4"


####### SERVICE #######
echo -e "\n${BLUE}[*] Restarting tor${RST}"
sudo service tor restart
echo -e "\n${GREEN}[+] tor status:${RST}"
service tor status

echo -e "\n${BLUE}[*] Setting up tor to start on boot${RST}"
sudo update-rc.d tor enable

echo -e "\n${GREEN}[+] Done${RST}"
