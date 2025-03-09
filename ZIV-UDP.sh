#!/bin/bash

GITHUB_USER="Hyper-21-stack"
GITHUB_REPO="ZIV-UDP"
RELEASE_TAG="v1.0.0"
FILE_NAME="udp-zivpn-linux-arm64"  # Updated to match the actual asset name
GITHUB_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO/releases/download/$RELEASE_TAG/$FILE_NAME"

is_number() {
    [[ $1 =~ ^[0-9]+$ ]]
}

YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$(whoami)" != "root" ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

cd /root
clear

echo ""
echo -e "\033[1;33mZivpn UDP Services\033[0m"
echo -e "\033[1;32m1. Zivpn Udp\033[0m"
echo -e "\033[1;32m2. Create Auth \033[0m"
echo -e "\033[1;32m3. Active Users  \033[0m"
echo -e "\033[1;32m0. Exit \033[0m"

# Select an Option
read -p "$(echo -e "\033[1;33mSelect a number from 0 to 3: \033[0m")" input

# Check if input is a number
if [[ "$input" =~ ^[0-9]+$ ]]; then
    selected_option=$input
else
    echo -e "$YELLOW"
    echo "Invalid input. Please enter a valid number."
    echo -e "$NC"
    exit 1
fi

clear

case $selected_option in
    1)
        echo -e "\033[1;33mInstalling ZIVPN Hysteria Udp...\033[0m"
        cd /root
        systemctl stop ziv-server.service
        systemctl disable ziv-server.service
        rm -rf /etc/systemd/system/ziv-server.service
        rm -rf /root/zv
        mkdir zv
        cd zv

        udp_script="/root/zv/$FILE_NAME"

        if [ ! -e "$udp_script" ]; then
            wget "$GITHUB_URL" -O "$FILE_NAME"
        fi

        chmod 755 "$FILE_NAME"
        openssl ecparam -genkey -name prime256v1 -out ca.key
        openssl req -new -x509 -days 36500 -key ca.key -out ca.crt -subj "/CN=bing.com"

        echo ""
        echo -e "\033[1;33mCreate Zivpn Passwords\033[0m"
        echo -e "\033[1;32mNote: Multiple Auth ( ex: a,b,c )\033[0m"
        echo -e "$YELLOW"
        read -p "Auth Str: " input_config
        echo -e "$NC"

        if [ -n "$input_config" ]; then
            IFS=',' read -r -a config <<< "$input_config"
            if [ ${#config[@]} -eq 1 ]; then
                config+=(${config[0]})
            fi
        else
            echo -e "$YELLOW"
            echo "Enter auth separated by commas"
            echo -e "$NC"
            exit 1
        fi

        echo "$input_config" > /root/zv/authusers
        obfs="zivpn"
        auth_str=$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')

        while true; do
            echo -e "$YELLOW"
            read -p "Remote UDP Port: " remote_udp_port
            echo -e "$NC"

            if is_number "$remote_udp_port" && [ "$remote_udp_port" -ge 1 ] && [ "$remote_udp_port" -le 65534 ]; then
                if netstat -tulnp | grep -q "::$remote_udp_port"; then
                    echo -e "$YELLOW"
                    echo "Error: The selected port has already been used"
                    echo -e "$NC"
                else
                    break
                fi
            else
                echo -e "$YELLOW"
                echo "Invalid input. Please enter a valid number between 1 and 65534."
                echo -e "$NC"
            fi
        done

        file_path="/root/zv/config.json"
        json_content='{"listen":"'"$(curl -s https://api.ipify.org)"':'"$remote_udp_port"'","cert":"/root/zv/ca.crt","key":"/root/zv/ca.key","obfs":"'"$obfs"'","auth":{"mode":"passwords","config":['"$auth_str"']}}'
        echo "$json_content" > "$file_path"

        if [ ! -e "$file_path" ]; then
            echo -e "$YELLOW"
            echo "Error: Unable to save the config.json file"
            echo -e "$NC"
            exit 1
        fi

        chmod 755 /root/zv/config.json

        cat <<EOF >/etc/systemd/system/ziv-server.service
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/root
ExecStart=/root/zv/$FILE_NAME server -c /root/zv/config.json
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

        systemctl enable ziv-server.service
        systemctl start ziv-server.service

        echo -e "$YELLOW"
        echo "💚 UDP HYSTERIA INSTALLED SUCCESSFULLY 💚"
        echo -e "$NC"

『✙ ɦყρεɾ ✙, [3/9/2025 7:32 PM]
exit 0
        ;;

    2)
        echo ""
        echo -e "\033[1;33mActive auth: \033[1;36m(\033[1;33m $(awk -F, 'NR==1 { print }' /root/zv/authusers | sed "s/\"/ /g" | sed "s/,/ /g") \033[1;36m)\033[0m"
        rm -rf /root/zv/authusers
        echo -e "\033[1;32mMultiple Auth ( ex: a,b,c )\033[0m"
        echo -e "$YELLOW"
        read -p "Auth Str: " input_config
        echo -e "$NC"

        if [ -n "$input_config" ]; then
            IFS=',' read -r -a config <<< "$input_config"
            if [ ${#config[@]} -eq 1 ]; then
                config+=(${config[0]})
            fi
        else
            echo -e "$YELLOW"
            echo "Enter auth separated by commas"
            echo -e "$NC"
            exit 1
        fi

        echo "$input_config" > /root/zv/authusers
        systemctl restart ziv-server.service

        echo -e "$YELLOW"
        echo "Auth updated successfully."
        echo -e "$NC"

        exit 0
        ;;

    3)
        echo ""
        echo -e "\033[1;32mActive Auth/Users:\033[0m"
        echo ""
        echo -e "\033[1;33m\033[1;36m[ \033[1;33m$(awk -F, 'NR==1 { print }' /root/zv/authusers | sed "s/\"/ /g" | sed "s/,/ /g") \033[1;36m]\033[0m"
        echo ""
        read -p "Press any key to exit ↩️︎" key
        exit 0
        ;;

    0)
        echo -e "\033[1;33mExiting...\033[0m"
        exit 0
        ;;

    *)
        echo -e "$YELLOW"
        echo "Invalid option. Please select a valid number."
        echo -e "$NC"
        exit 1
        ;;
esac
