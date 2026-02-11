#!/bin/bash
################################################################################
# Zimbra Installation - Stage 2: Manual LDAP Setup & Configuration
# This script configures Zimbra with FULL visibility into LDAP startup
################################################################################

set -e
set -o pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="/var/log/zimbra-stage2-$(date +%Y%m%d-%H%M%S).log"

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

# Check if Stage 1 was completed
if [ ! -d "/opt/zimbra" ]; then
    log_error "Stage 1 not completed. Run install-zimbra-stage1.sh first"
    exit 1
fi

log "=========================================="
log "Zimbra Stage 2: LDAP Setup & Configuration"
log "=========================================="
log "Log file: $LOG_FILE"

# Load configuration
if [ -f "./zimbra-config.conf" ]; then
    source ./zimbra-config.conf
else
    log_error "zimbra-config.conf not found"
    exit 1
fi

# Set hostname
log "Configuring hostname..."
hostnamectl set-hostname "$ZIMBRA_HOSTNAME"

# Update /etc/hosts
log "Updating /etc/hosts..."
if ! grep -q "$ZIMBRA_HOSTNAME" /etc/hosts; then
    echo "$SERVER_IP $ZIMBRA_HOSTNAME ${ZIMBRA_HOSTNAME%%.*}" >> /etc/hosts
fi

# Initialize LDAP manually with full visibility
log "Initializing LDAP database manually..."

# Create LDAP root password file
LDAP_ROOT_PW=$(openssl rand -base64 32)
echo -n "$LDAP_ROOT_PW" > /opt/zimbra/.ldap_root_password
chown zimbra:zimbra /opt/zimbra/.ldap_root_password
chmod 600 /opt/zimbra/.ldap_root_password

log "Starting LDAP initialization..."

# Run zmsetup with our configuration
su - zimbra << ZIMBRA_EOF
cd /opt/zimbra/bin

# Initialize LDAP
./zmldapinit

# Check if LDAP started
sleep 5
./ldap status

# If LDAP is running, create domain and admin
if [ \$? -eq 0 ]; then
    echo "LDAP is running - creating domain and admin account..."
    
    # Create domain
    ./zmprov cd $ZIMBRA_DOMAIN zimbraPublicServiceProtocol https zimbraPublicServiceHostname $ZIMBRA_HOSTNAME
    
    # Create admin account  
    ./zmprov ca admin@$ZIMBRA_DOMAIN "$ADMIN_PASSWORD" zimbraIsAdminAccount TRUE
    
    # Set services
    ./zmprov ms $ZIMBRA_HOSTNAME zimbraServiceEnabled mta
    ./zmprov ms $ZIMBRA_HOSTNAME zimbraServiceEnabled mailbox
    ./zmprov ms $ZIMBRA_HOSTNAME zimbraServiceEnabled antispam
    ./zmprov ms $ZIMBRA_HOSTNAME zimbraServiceEnabled antivirus
    ./zmprov ms $ZIMBRA_HOSTNAME zimbraServiceEnabled ldap
    ./zmprov ms $ZIMBRA_HOSTNAME zimbraServiceEnabled logger
    ./zmprov ms $ZIMBRA_HOSTNAME zimbraServiceEnabled snmp
    ./zmprov ms $ZIMBRA_HOSTNAME zimbraServiceEnabled spell
    ./zmprov ms $ZIMBRA_HOSTNAME zimbraServiceEnabled proxy
    ./zmprov ms $ZIMBRA_HOSTNAME zimbraServiceEnabled stats
    
    echo "Configuration complete!"
else
    echo "ERROR: LDAP failed to start"
    cat /opt/zimbra/log/slapd.log
    exit 1
fi
ZIMBRA_EOF

if [ $? -ne 0 ]; then
    log_error "LDAP initialization failed. Check /opt/zimbra/log/slapd.log"
    cat /opt/zimbra/log/slapd.log
    exit 1
fi

# Start all Zimbra services
log "Starting Zimbra services..."
su - zimbra -c "zmcontrol start"

# Wait for services to come up
sleep 10

# Check status
log "Checking service status..."
su - zimbra -c "zmcontrol status"

log ""
log "=========================================="
log "Installation Complete!"
log "=========================================="
log ""
log "Admin Console: https://$ZIMBRA_HOSTNAME:7071"
log "Webmail: https://$ZIMBRA_HOSTNAME"
log "Username: admin@$ZIMBRA_DOMAIN"
log "Password: $ADMIN_PASSWORD"
log ""
log "IMPORTANT: Install SSL certificate with:"
log "sudo /opt/zimbra/bin/zmcertmgr createca -new"
log ""
