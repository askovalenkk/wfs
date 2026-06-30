#!/bin/bash

# ------ Website Fast Setup (WFS) ------
# (c) Kovalenko Andrei 2026
# MIT License

colorized_echo() {
    local color=$1
    local text=$2

    case $color in
        "red") printf "\e[91m${text}\e[0m\n" ;;
        "green") printf "\e[92m${text}\e[0m\n" ;;
        "yellow") printf "\e[93m${text}\e[0m\n" ;;
        "blue") printf "\e[94m${text}\e[0m\n" ;;
        "magenta") printf "\e[95m${text}\e[0m\n" ;;
        "cyan") printf "\e[96m${text}\e[0m\n" ;;
        *) echo "${text}" ;;
    esac
}

colorized_echo cyan "---------------------------------------------"
colorized_echo cyan "      ___              ___           ___  "
colorized_echo cyan "     /\  \            /\__\         /\__\ "
colorized_echo cyan "    _\:\  \          /:/ _/_       /:/ _/_  "
colorized_echo cyan "   /\ \:\  \        /:/ /\__\     /:/ /\  \ "
colorized_echo cyan "  _\:\ \:\  \      /:/ /:/  /    /:/ /::\  \ "
colorized_echo cyan " /\ \:\ \:\__\    /:/_/:/  /    /:/_/:/\:\__\ "
colorized_echo cyan " \:\ \:\/:/  /    \:\/:/  /     \:\/:/ /:/  /"
colorized_echo cyan "  \:\ \::/  /      \::/__/       \::/ /:/  / "
colorized_echo cyan "   \:\/:/  /        \:\  \        \/_/:/  /"
colorized_echo cyan "    \::/  /          \:\__\         /:/  / "
colorized_echo cyan "     \/__/            \/__/         \/__/        WEBSITE FAST SETUP"
echo " "
colorized_echo cyan 'Website Fast Setup (WFS) is a script that will help you quickly setup your website with NGINX Web-Server and CertBot. To run this script use the "wfs" command. Before using this command please make sure that you has updated DNS-records (it may take up to 48 hours).'
colorized_echo cyan "Source code: https://www.github.com/askovalenkk/wfs"

if [ "$EUID" -ne 0 ]; then
    colorized_echo red 'Please run as root using "sudo wfs".' >&2
    exit 1
fi

if [ -f "/usr/local/bin/wfs/wfs.sh" ]; then
    chmod +x wfs.sh
    sudo mv wfs.sh /usr/local/bin/wfs
fi

color() {
    local color=$1
    local prompt=$2
    local input
    case $color in
        red) color_code='\e[31m' ;;
        green) color_code='\e[32m' ;;
        yellow) color_code='\e[33m' ;;
        blue) color_code='\e[34m' ;;
        purple) color_code='\e[35m' ;;
        cyan) color_code='\e[36m' ;;
        white) color_code='\e[37m' ;;
        *) color_code='\e[0m' ;;
    esac
    read -p "$(echo -e "${color_code}${prompt}\e[0m")" input
    echo "$input"
}

check_email() {
    local email=$1
    local email_regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    [[ "$email" =~ $email_regex ]]
}

check_domain() {
    local domain=$1
    local domain_regex="^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$"
    [[ "$domain" =~ $domain_regex ]]
}

get_input_1() {
    local prompt=$1
    local validation_fn=$2
    local input
    local attempts=0
    while [[ $attempts -lt 3 ]]; do
        input=$(color cyan "$prompt")
        $validation_fn "$input" && return 0
        ((attempts++))
        colorized_echo red "Error: wrong answer."
    done
    colorized_echo red "Too many invalid attempts. Exiting..."
    exit 1
}

get_input_2() {
    local prompt=$1
    local input
    read -p "$(echo -e "\e[96m$prompt\e[0m")" input
    echo "$input"
}

check_dns_match() {
    local domain=$1
    local server_ip
    local actual_ip

    server_ip=$(curl -s ifconfig.me)
    actual_ip=$(nslookup "$domain" > /dev/null 2>&1| awk '/^Address: / { print $2 }' | tail -n1)

    if [[ "$server_ip" != "$actual_ip" ]]; then
        colorized_echo red "Error: DNS record does not match the server's IP."
        exit 1
    fi
}

echo ""
echo ""
email=$(get_input_1 "Please write your email for issuing an SSL certificate: " check_email)
domain=$(get_input_1 "Please write your domain name: " check_domain)

ans1=$(get_input_2 "Do you want to install Nginx? [Y/n]: ")
if [[ "$ans1" == "n" || "$ans1" == "N" ]]; then
    exit 1
fi

colorized_echo cyan "Updating packages..."
apt update > /dev/null 2>/dev/null
colorized_echo green "Done."

colorized_echo cyan "Installing Nginx..."
if dpkg -l | grep -q nginx; then
    colorized_echo yellow "Nginx is already installed."
else
    if apt-get install -y nginx > /dev/null 2>&1; then
        colorized_echo green "Done."
    else
        colorized_echo red "Error: Failed to install Nginx."
        exit 1
    fi
fi

ans1=$(get_input_2 "Do you want to install CertBot? [Y/n]: ")
if [[ "$ans1" == "n" || "$ans1" == "N" ]]; then
    exit 1
fi

colorized_echo cyan "Installing CertBot..."
if dpkg -l | grep -q certbot; then
    colorized_echo yellow "CertBot is already installed."
else
    if apt-get install -y python3-certbot-nginx > /dev/null 2>&1; then
        colorized_echo green "Done."
    else
        colorized_echo red "Error: Failed to install CertBot."
        exit 1
    fi
fi

colorized_echo cyan "Looking up for DNS records..."
check_dns_match "$domain"
