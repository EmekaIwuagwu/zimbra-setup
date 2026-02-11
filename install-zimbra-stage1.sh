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
ZIMBRA_VERSION="10.1.0_PLUS_GA_4655"
ZIMBRA_URL="https://files.zimbra.com/downloads/10.1.0_PLUS_GA/zcs-${ZIMBRA_VERSION}.UBUNTU22_64.20241101151835.tgz"
DOWNLOAD_DIR="/tmp/zimbra-installer"

log "Downloading Zimbra ${ZIMBRA_VERSION}..."
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

if [ ! -f "zcs-${ZIMBRA_VERSION}.UBUNTU22_64.20241101151835.tgz" ]; then
    wget --no-check-certificate "$ZIMBRA_URL" -O "zcs-${ZIMBRA_VERSION}.UBUNTU22_64.20241101151835.tgz"
fi

log "Extracting installer..."
tar xzf "zcs-${ZIMBRA_VERSION}.UBUNTU22_64.20241101151835.tgz"
cd "zcs-${ZIMBRA_VERSION}.UBUNTU22_64.20241101151835"

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

# Run installer with -s flag (skip configuration)
./install.sh -s << 'INSTALLER_EOF'
y
y
y
INSTALLER_EOF

log ""
log "=========================================="
log "Stage 1 Complete: Packages Installed"
log "=========================================="
log ""
log "Next steps:"
log "1. Run: sudo bash install-zimbra-stage2.sh"
log "2. This will configure LDAP with full visibility"
log ""
