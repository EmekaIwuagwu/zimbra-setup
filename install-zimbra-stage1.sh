#!/bin/bash
################################################################################
# Zimbra Installation - Stage 1: Package Installation Only
# This script installs Zimbra packages WITHOUT attempting configuration
################################################################################

set -e
set -o pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="/var/log/zimbra-stage1-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "${LOG_FILE}"
}

# Check root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

log "=========================================="
log "Zimbra Stage 1: Package Installation Only"
log "=========================================="
log "Log file: $LOG_FILE"

# Disable AppArmor completely
if systemctl is-active --quiet apparmor; then
    log "Disabling AppArmor..."
    systemctl stop apparmor
    systemctl disable apparmor
fi

# Stop conflicting services
log "Stopping conflicting services..."
for service in postfix sendmail; do
    if systemctl is-active --quiet $service; then
        systemctl stop $service
        systemctl disable $service
    fi
done

# Download Zimbra
ZIMBRA_VERSION="10.1.0"
ZIMBRA_DOWNLOAD_URL="https://packages.zcsplus.com/dlz/zcs-PLUS-${ZIMBRA_VERSION}_GA_4655.UBUNTU22_64.20240819064312.tgz"
DOWNLOAD_DIR="/tmp/zimbra-install"

log "Downloading Zimbra ${ZIMBRA_VERSION}..."
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

if [ ! -f "zimbra-installer.tgz" ]; then
    wget --no-check-certificate -O zimbra-installer.tgz "$ZIMBRA_DOWNLOAD_URL"
    if [ $? -ne 0 ]; then
        log_error "Failed to download Zimbra. Check your internet connection."
        exit 1
    fi
else
    log "Zimbra installer already downloaded"
fi

log "Extracting installer..."
tar xzf zimbra-installer.tgz

# Find extracted directory
ZIMBRA_EXTRACT_DIR=$(find . -maxdepth 1 -type d -name "zcs-*" | head -n 1)

if [ -z "$ZIMBRA_EXTRACT_DIR" ]; then
    log_error "Failed to extract Zimbra installer"
    exit 1
fi

cd "$ZIMBRA_EXTRACT_DIR"
log "Using installer: $ZIMBRA_EXTRACT_DIR"

# Install system dependencies
log "Installing system dependencies..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    netcat-openbsd \
    sudo \
    libidn12 \
    libpcre3 \
    libgmp10 \
    libexpat1 \
    libstdc++6 \
    perl \
    perl-modules \
    libaio1 \
    resolvconf \
    unzip \
    pax \
    sysstat \
    sqlite3

# Create a modified install script that ONLY installs packages
log "Installing Zimbra packages (NO configuration)..."

# Run installer with -s flag (skip configuration) and answer all prompts
# The multiple "y" answers handle: license, system modification, and package installation confirmations
yes | ./install.sh -s 2>&1 | tee -a "$LOG_FILE"

if [ ${PIPESTATUS[1]} -ne 0 ]; then
    log_error "Package installation failed. Check $LOG_FILE for details"
    exit 1
fi

log ""
log "=========================================="
log "Stage 1 Complete: Packages Installed"
log "=========================================="
log ""
log "Next steps:"
log "1. Run: sudo bash install-zimbra-stage2.sh"
log "2. This will configure LDAP with full visibility"
log ""
