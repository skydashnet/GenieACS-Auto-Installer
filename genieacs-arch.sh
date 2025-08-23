#!/usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'
NC='\033[0m'

clear

echo -e "${GREEN}"
cat << "EOF"
  /$$$$$$  /$$                       /$$                     /$$           /$$   /$$ /$$$$$$$$ /$$$$$$$$
 /$$__  $$| $$                      | $$                    | $$          | $$$ | $$| $$_____/|__  $$__/
| $$  \__/| $$   /$$ /$$   /$$  /$$$$$$$  /$$$$$$   /$$$$$$$| $$$$$$$     | $$$$| $$| $$         | $$
|  $$$$$$ | $$  /$$/| $$  | $$ /$$__  $$ |____  $$ /$$_____/| $$__  $$    | $$ $$ $$| $$$$$      | $$
 \____  $$| $$$$$$/ | $$  | $$| $$  | $$  /$$$$$$$|  $$$$$$ | $$  \ $$    | $$  $$$$| $$__/      | $$
 /$$  \ $$| $$_  $$ | $$  | $$| $$  | $$ /$$__  $$ \____  $$| $$  | $$    | $$\  $$$| $$         | $$
|  $$$$$$/| $$ \  $$|  $$$$$$$|  $$$$$$$|  $$$$$$$ /$$$$$$$/| $$  | $$ /$$| $$ \  $$| $$$$$$$$   | $$
 \______/ |__/  \__/ \____  $$|\_______/ \_______/|_______/ |__/  |__/|__/|__/  \__/|________/   |__/
                     /$$  | $$|
                    |  $$$$$$/
                     \______/
EOF
echo -e "${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}        GenieACS Auto Installer for EndeavourOS/Arch Linux                 ${NC}"
echo -e "${GREEN}============================================================================${NC}"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script as root (sudo).${NC}"
  exit 1
fi

local_ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -1)

echo -e "${GREEN}Do you want to continue? (y/Y/Enter to continue, n/N to cancel)${NC}"
read -r confirmation

echo -e "${YELLOW}Checking internet connection...${NC}"
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${RED}No internet connection detected. Please check your network and try again.${NC}"
    exit 1
fi

echo -e "${YELLOW}Testing AUR connectivity...${NC}"
aur_available=true
if ! curl -s --connect-timeout 10 "https://aur.archlinux.org" > /dev/null; then
    echo -e "${YELLOW}AUR connection issues detected. Will use alternative installation methods.${NC}"
    aur_available=false
fi

if [[ "$confirmation" =~ ^[Nn]$ ]]; then
    echo -e "${RED}Installation cancelled. No changes were made.${NC}"
    exit 1
elif [[ "$confirmation" =~ ^[Yy]$ ]] || [[ -z "$confirmation" ]]; then
    echo -e "${GREEN}Starting installation...${NC}"
else
    echo -e "${RED}Invalid input. Installation cancelled.${NC}"
    exit 1
fi

echo -e "${BLUE}Enter custom port for GenieACS UI (default: 3000, press Enter for default):${NC}"
read -r custom_port

if [[ -z "$custom_port" ]]; then
    ui_port=3000
    echo -e "${YELLOW}Using default port: 3000${NC}"
elif [[ "$custom_port" =~ ^[0-9]+$ ]] && [ "$custom_port" -ge 1024 ] && [ "$custom_port" -le 65535 ]; then
    ui_port="$custom_port"
    echo -e "${YELLOW}Using custom port: $ui_port${NC}"
else
    echo -e "${RED}Invalid port number. Using default port: 3000${NC}"
    ui_port=3000
fi

echo -e "${YELLOW}Updating system packages...${RESET}"
pacman -Syu --noconfirm >/dev/null 2>&1

echo -e "${YELLOW}Installing basic dependencies...${RESET}"
pacman -S --noconfirm nodejs npm ufw >/dev/null 2>&1

if [ "$aur_available" = true ] && ! sudo -u "$ORIGINAL_USER" command -v yay &> /dev/null; then
    echo -e "${YELLOW}Installing yay (AUR helper)...${RESET}"
    pacman -S --noconfirm base-devel git >/dev/null 2>&1

    sudo -u "$ORIGINAL_USER" bash -c '
        cd /tmp
        rm -rf yay
        git clone https://aur.archlinux.org/yay.git >/dev/null 2>&1
        cd yay
        makepkg -si --noconfirm >/dev/null 2>&1
    '
elif [ "$aur_available" = false ]; then
    echo -e "${YELLOW}Skipping yay installation due to AUR connectivity issues.${NC}"
fi

echo -e "${BLUE}Setting up database...${NC}"

ORIGINAL_USER="${SUDO_USER:-$USER}"
if [ -z "$ORIGINAL_USER" ]; then
    echo -e "${RED}Cannot determine original user. Please run with sudo.${NC}"
    exit 1
fi

mongodb_installed=false

if [ "$aur_available" = true ]; then
    echo -e "${YELLOW}Installing MongoDB...${RESET}"

    pacman -S --noconfirm mongodb-tools >/dev/null 2>&1

    if sudo -u "$ORIGINAL_USER" timeout 60 yay -S --noconfirm mongodb-bin >/dev/null 2>&1; then
        echo -e "${GREEN}MongoDB installed successfully!${NC}"
        mongodb_installed=true

        systemctl enable --now mongodb >/dev/null 2>&1
        sleep 3

        if timeout 10 mongo --eval 'db.runCommand({ connectionStatus: 1 })' &>/dev/null || timeout 10 mongosh --eval 'db.runCommand({ connectionStatus: 1 })' &>/dev/null; then
            echo -e "${GREEN}MongoDB is running and accessible.${NC}"
            database_type="mongodb"
        else
            echo -e "${YELLOW}MongoDB installed but not responding. Using alternative...${NC}"
            mongodb_installed=false
        fi
    else
        echo -e "${YELLOW}MongoDB installation failed. Using alternative...${NC}"
    fi
else
    echo -e "${YELLOW}AUR not available. Skipping MongoDB installation.${NC}"
fi

if [ "$mongodb_installed" = false ]; then
    echo -e "${YELLOW}Installing Valkey (Redis-compatible)...${RESET}"

    if pacman -S --noconfirm valkey >/dev/null 2>&1; then
        systemctl enable --now valkey >/dev/null 2>&1
        sleep 2

        if valkey-cli ping 2>/dev/null | grep -q PONG; then
            echo -e "${GREEN}Valkey installed and running successfully!${NC}"
            database_type="valkey"
        elif redis-cli -p 6379 ping 2>/dev/null | grep -q PONG; then
            echo -e "${GREEN}Valkey installed and running!${NC}"
            database_type="valkey"
        else
            mkdir -p /var/lib/valkey
            chown valkey:valkey /var/lib/valkey 2>/dev/null || true
            systemctl restart valkey >/dev/null 2>&1
            sleep 2

            if valkey-cli ping 2>/dev/null | grep -q PONG || redis-cli -p 6379 ping 2>/dev/null | grep -q PONG; then
                echo -e "${GREEN}Valkey is now working!${NC}"
                database_type="valkey"
            else
                echo -e "${YELLOW}Valkey installed but may need manual configuration.${NC}"
                database_type="valkey"
            fi
        fi
    else
        if pacman -S --noconfirm redis >/dev/null 2>&1; then
            systemctl enable --now redis >/dev/null 2>&1
            sleep 2
            echo -e "${GREEN}Redis installed as fallback!${NC}"
            database_type="redis"
        else
            echo -e "${RED}Failed to install any Redis-compatible database. Installation cannot continue.${NC}"
            exit 1
        fi
    fi
fi

echo -e "${YELLOW}Installing GenieACS...${RESET}"
npm install -g genieacs@1.2.13 >/dev/null 2>&1

useradd --system --no-create-home --user-group genieacs 2>/dev/null || true
mkdir -p /opt/genieacs/ext
mkdir -p /var/log/genieacs
chown -R genieacs:genieacs /opt/genieacs /var/log/genieacs

cat << EOF > /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
GENIEACS_EXT_DIR=/opt/genieacs/ext
GENIEACS_UI_JWT_SECRET=secret
GENIEACS_UI_PORT=$ui_port
EOF

if [ "$database_type" = "valkey" ] || [ "$database_type" = "redis" ]; then
    echo "GENIEACS_REDIS_HOST=127.0.0.1" >> /opt/genieacs/genieacs.env
    echo "GENIEACS_REDIS_PORT=6379" >> /opt/genieacs/genieacs.env
fi

chown genieacs:genieacs /opt/genieacs/genieacs.env
chmod 600 /opt/genieacs/genieacs.env

echo -e "${YELLOW}Creating services...${RESET}"
for svc in cwmp nbi fs ui; do
cat << EOF > /etc/systemd/system/genieacs-$svc.service
[Unit]
Description=GenieACS $svc
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-$svc
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
done

systemctl daemon-reload >/dev/null 2>&1

echo -e "${YELLOW}Starting GenieACS services...${RESET}"
for svc in cwmp nbi fs ui; do
    systemctl enable genieacs-$svc >/dev/null 2>&1
    if systemctl restart genieacs-$svc >/dev/null 2>&1; then
        echo -e "${GREEN}✓ genieacs-$svc started${NC}"
    else
        echo -e "${RED}✗ Failed to start genieacs-$svc${NC}"
    fi
done

echo -e "${YELLOW}Configuring firewall...${RESET}"
ufw allow $ui_port/tcp >/dev/null 2>&1
ufw allow 7547/tcp >/dev/null 2>&1
ufw allow 7557/tcp >/dev/null 2>&1
ufw allow 7567/tcp >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1

echo -e "${YELLOW}Verifying installation...${RESET}"
sleep 5

all_services_ok=true
for svc in cwmp nbi fs ui; do
    if systemctl is-active --quiet genieacs-$svc; then
        echo -e "${GREEN}✓ genieacs-$svc is running${NC}"
    else
        echo -e "${RED}✗ genieacs-$svc is not running${NC}"
        all_services_ok=false
    fi
done

echo
echo -e "${GREEN}============================================================================${NC}"
if [ "$all_services_ok" = true ]; then
    echo -e "${GREEN} GenieACS installation completed successfully!${NC}"
else
    echo -e "${YELLOW} GenieACS installation completed with some issues!${NC}"
    echo -e "${YELLOW} Check logs: sudo journalctl -u genieacs-<service-name>${NC}"
fi
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN} Database:   $database_type${NC}"
echo -e "${GREEN} UI:         http://$local_ip:$ui_port${NC}"
echo -e "${GREEN} USER:       admin${NC}"
echo -e "${GREEN} PASS:       admin${NC}"
echo -e "${GREEN} CWMP:       Port 7547${NC}"
echo -e "${GREEN} NBI:        Port 7557${NC}"
echo -e "${GREEN} FS:         Port 7567${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo -e "${BLUE} Useful commands:${NC}"
echo -e "${BLUE} - Check services: sudo systemctl status genieacs-{cwmp,nbi,fs,ui}${NC}"
echo -e "${BLUE} - View logs: sudo journalctl -u genieacs-ui -f${NC}"
echo -e "${BLUE} - Restart service: sudo systemctl restart genieacs-ui${NC}"
echo -e "${GREEN}============================================================================${NC}"
