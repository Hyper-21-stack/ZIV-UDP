『✙ ɦყρεɾ ✙, [3/9/2025 6:21 PM]
#!/bin/bash

# GitHub Repo Details
GITHUB_USER="Hyper-21-stack"
GITHUB_REPO="ZIV-UDP"
RELEASE_TAG="v1.0.0"
FILE_NAME="zi-amd"
GITHUB_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO/releases/download/$RELEASE_TAG/$FILE_NAME"

# Function to check if a value is a number
is_number() {
    [[ $1 =~ ^[0-9]+$ ]]
}

# Colors for output
YELLOW='\033[1;33m'
NC='\033[0m'

# Ensure the script is run as root
if [ "$(whoami)" != "root" ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

# Navigate to root directory
cd /root || exit
clear

# Display menu
echo ""
echo -e "${YELLOW}Zivpn UDP Services${NC}"
echo -e "\033[1;32m1. Install Zivpn UDP\033[0m"
echo -e "\033[1;32m2. Create Auth\033[0m"
echo -e "\033[1;32m3. Show Active Users\033[0m"
echo -e "\033[1;32m0. Exit\033[0m"

# Read user input
read -p "$(echo -e "${YELLOW}Select a number from 0 to 3: ${NC}")" input

# Validate input
if [[ ! "$input" =~ ^[0-9]+$ ]]; then
    echo -e "$YELLOW Invalid input. Please enter a valid number. $NC"
    exit 1
fi

clear

# Handle user selection
case $input in
    1)
        echo -e "${YELLOW}Installing ZIVPN Hysteria UDP...${NC}"
        cd /root || exit

        # Stop and disable existing service
        systemctl stop ziv-server.service
        systemctl disable ziv-server.service

        # Remove old files
        rm -rf /etc/systemd/system/ziv-server.service
        rm -rf /root/zv

        # Create and navigate to new directory
        mkdir -p /root/zv
        cd /root/zv || exit

        # Download the latest release if not already downloaded
        if [ ! -e "$FILE_NAME" ]; then
            wget "$GITHUB_URL" -O "$FILE_NAME"
        fi
        chmod 755 "$FILE_NAME"

        # Generate SSL certificate
        openssl ecparam -genkey -name prime256v1 -out ca.key
        openssl req -new -x509 -days 36500 -key ca.key -out ca.crt -subj "/CN=bing.com"

        # Prompt for authentication strings
        echo ""
        echo -e "${YELLOW}Create Zivpn Passwords${NC}"
        echo -e "\033[1;32mNote: Multiple Auth (e.g., a,b,c)\033[0m"

        read -p "Auth Str: " input_config
        if [ -z "$input_config" ]; then
            echo -e "$YELLOW Authentication cannot be empty. Exiting... $NC"
            exit 1
        fi

        echo "$input_config" > /root/zv/authusers

        # Format authentication for JSON
        IFS=',' read -r -a config <<< "$input_config"
        auth_str=$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')

        # Prompt for remote UDP port
        while true; do
            echo -e "${YELLOW}"
            read -p "Remote UDP Port: " remote_udp_port
            echo -e "${NC}"

            if is_number "$remote_udp_port" && [ "$remote_udp_port" -ge 1 ] && [ "$remote_udp_port" -le 65534 ]; then
                if netstat -tulnp | grep -q "::$remote_udp_port"; then
                    echo -e "${YELLOW}Error: The selected port is already in use.${NC}"
                else
                    break
                fi
            else
                echo -e "${YELLOW}Invalid input. Please enter a valid number between 1 and 65534.${NC}"
            fi
        done

        # Generate config.json
        CONFIG_PATH="/root/zv/config.json"
        json_content=$(cat <<EOF
{
    "listen": "$(curl -s https://api.ipify.org):$remote_udp_port",
    "cert": "/root/zv/ca.crt",
    "key": "/root/zv/ca.key",
    "obfs": "zivpn",
    "auth": {
        "mode": "passwords",
        "config": [$auth_str]
    }
}
EOF
        )

        echo "$json_content" > "$CONFIG_PATH"

        if [ ! -e "$CONFIG_PATH" ]; then
            echo -e "${YELLOW}Error: Unable to save config.json${NC}"
            exit 1
        fi

        chmod 755 "$CONFIG_PATH"

        # Create systemd service file
        cat <<EOF > /etc/systemd/system/ziv-server.service
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

『✙ ɦყρεɾ ✙, [3/9/2025 6:21 PM]
# Enable and start service
        systemctl enable ziv-server.service
        systemctl start ziv-server.service

        echo -e "${YELLOW}💚 UDP HYSTERIA INSTALLED SUCCESSFULLY 💚${NC}"
        exit 0
        ;;

    2)
        echo -e "${YELLOW}Create Auth Option is under development.${NC}"
        exit 0
        ;;

    3)
        echo -e "${YELLOW}Active Users:$(cat /root/zv/authusers)${NC}"
        exit 0
        ;;

    0)
        echo -e "${YELLOW}Exiting...${NC}"
        exit 0
        ;;

    *)
        echo -e "${YELLOW}Invalid selection. Exiting...${NC}"
        exit 1
        ;;
esac
