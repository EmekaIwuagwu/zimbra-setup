#!/bin/bash

################################################################################
# Quick Server Setup Script for maybax.de
# Configures hostname and basic settings before Zimbra installation
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

HOSTNAME="mail.maybax.de"
DOMAIN="maybax.de"
SERVER_IP="173.249.1.171"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Server Setup for maybax.de${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    exit 1
fi

# Set hostname
echo -e "${BLUE}Setting hostname to $HOSTNAME...${NC}"
hostnamectl set-hostname "$HOSTNAME"
echo -e "${GREEN}✓ Hostname set${NC}\n"

# Update /etc/hosts
echo -e "${BLUE}Updating /etc/hosts file...${NC}"

# Backup original
cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d%H%M%S)

# Remove old entries
sed -i '/maybax.de/d' /etc/hosts
sed -i '/mail.oregonstate/d' /etc/hosts

# Add new entries
cat >> /etc/hosts <<EOF

# Zimbra Mail Server Configuration
$SERVER_IP $HOSTNAME mail
127.0.0.1 localhost
EOF

echo -e "${GREEN}✓ /etc/hosts updated${NC}\n"

# Verify hostname configuration
echo -e "${BLUE}Verifying hostname configuration...${NC}"
echo -e "  Hostname: $(hostname)"
echo -e "  FQDN: $(hostname -f)"
echo -e "  IP: $(hostname -I | awk '{print $1}')"
echo ""

# Update system
echo -e "${BLUE}Updating system packages...${NC}"
apt-get update -qq
echo -e "${GREEN}✓ Package lists updated${NC}\n"

# Install basic utilities if not present
echo -e "${BLUE}Installing basic utilities...${NC}"
apt-get install -y -qq dnsutils net-tools curl wget git vim 2>&1 | grep -v "already"
echo -e "${GREEN}✓ Utilities installed${NC}\n"

# Configure timezone
echo -e "${BLUE}Setting timezone to Europe/Berlin...${NC}"
timedatectl set-timezone Europe/Berlin
echo -e "${GREEN}✓ Timezone set${NC}\n"

# Enable NTP time sync
echo -e "${BLUE}Enabling time synchronization...${NC}"
timedatectl set-ntp on
echo -e "${GREEN}✓ Time sync enabled${NC}\n"

# Show current configuration
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Current Server Configuration${NC}"
echo -e "${BLUE}========================================${NC}\n"
echo -e "  Hostname: ${GREEN}$(hostname -f)${NC}"
echo -e "  IP Address: ${GREEN}$(hostname -I | awk '{print $1}')${NC}"
echo -e "  Timezone: ${GREEN}$(timedatectl | grep "Time zone" | awk '{print $3}')${NC}"
echo -e "  Time Sync: ${GREEN}$(timedatectl | grep "synchronized" | awk '{print $3}')${NC}"
echo -e ""

# Test DNS resolution
echo -e "${BLUE}Testing DNS resolution for $HOSTNAME...${NC}"
if nslookup $HOSTNAME &> /dev/null; then
    RESOLVED_IP=$(nslookup $HOSTNAME | grep -A1 "Name:" | grep "Address:" | awk '{print $2}')
    if [[ "$RESOLVED_IP" == "$SERVER_IP" ]]; then
        echo -e "${GREEN}✓ DNS resolution successful: $HOSTNAME → $SERVER_IP${NC}\n"
    else
        echo -e "${YELLOW}⚠ Warning: DNS resolves to $RESOLVED_IP instead of $SERVER_IP${NC}"
        echo -e "${YELLOW}  This is OK if you haven't configured DNS yet${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠ Warning: DNS resolution failed${NC}"
    echo -e "${YELLOW}  Please configure DNS records at Spaceship.com${NC}\n"
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Server setup complete!${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "Next steps:"
echo -e "  1. Configure DNS at Spaceship.com (see DNS_SETUP_GUIDE.md)"
echo -e "  2. Wait for DNS propagation (1-4 hours)"
echo -e "  3. Run: ${YELLOW}./verify-dns.sh${NC} to check DNS"
echo -e "  4. Run: ${YELLOW}./pre-install-check.sh${NC} for system check"
echo -e "  5. Run: ${YELLOW}./install-zimbra.sh${NC} to install Zimbra"
echo -e ""
