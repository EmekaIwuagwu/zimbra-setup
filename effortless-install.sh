#!/bin/bash
################################################################################
# Zimbra Effortless "Last Mile" Installer
# Target: Ubuntu 22.04 LTS (Jammy)
# Version: Zimbra 10.1 PLUS
################################################################################

set -o pipefail
set +H  # Disable bash history expansion for the '!' character

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="/var/log/zimbra-effortless.log"

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${LOG_FILE}"; }
log_error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "${LOG_FILE}"; }
log_warning() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "${LOG_FILE}"; }

# Check root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

# Load variables from current setup
ZIMBRA_DOMAIN="maybax.de"
ZIMBRA_HOSTNAME="mail.maybax.de"
ADMIN_PASSWORD='maybax2024!'
SERVER_IP="144.91.106.134"
ZIMBRA_VERSION="10.1.0"
ZIMBRA_DOWNLOAD_URL="https://packages.zcsplus.com/dlz/zcs-PLUS-10.1.0_GA_4655.UBUNTU22_64.20240819064312.tgz"

log "===================================================="
log "Zimbra Effortless Installation - Final Push"
log "===================================================="

# 1. PRE-INSTALL SYSTEM HARDENING
log "Step 1: Fixing port conflicts (DNS & LDAP)..."
systemctl stop systemd-resolved 2>/dev/null
systemctl disable systemd-resolved 2>/dev/null
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Stop system LDAP if it exists
systemctl stop slapd 2>/dev/null
systemctl disable slapd 2>/dev/null
fuser -k 389/tcp 2>/dev/null
fuser -k 53/tcp 2>/dev/null

# Fix hosts file
sed -i '/127.0.0.1 localhost/d' /etc/hosts
sed -i "/$ZIMBRA_HOSTNAME/d" /etc/hosts
echo "127.0.0.1 localhost" >> /etc/hosts
echo "$SERVER_IP $ZIMBRA_HOSTNAME mail" >> /etc/hosts

# 2. PACKAGE INSTALLATION (IF NOT ALREADY DONE)
if [ ! -d "/opt/zimbra/bin" ]; then
    log "Step 2: Downloading and Installing Packages..."
    mkdir -p /tmp/zimbra-install && cd /tmp/zimbra-install
    wget --no-check-certificate -O zimbra-installer.tgz "$ZIMBRA_DOWNLOAD_URL"
    tar xzf zimbra-installer.tgz
    ZIMBRA_DIR=$(find . -maxdepth 1 -type d -name "zcs-*" | head -n 1)
    cd "$ZIMBRA_DIR"
    
    # dependencies
    apt-get update
    apt-get install -y netcat-openbsd libidn12 libpcre3 libgmp10 libexpat1 libstdc++6 libaio1 resolvconf unzip pax sysstat sqlite3
    
    # install packages only
    yes | ./install.sh -s 2>&1 | tee -a "$LOG_FILE"
fi

# 3. LDAP NUKE AND PURE INITIALIZATION
log "Step 3: Performing Surgical LDAP Initialization..."
sudo su - zimbra -c "/opt/zimbra/bin/zmcontrol stop" 2>/dev/null || true
sudo fuser -k 389/tcp 2>/dev/null

# Wipe broken DB states
rm -rf /opt/zimbra/data/ldap/mdb/db/*
rm -rf /opt/zimbra/data/ldap/mdb/logs/*
rm -rf /opt/zimbra/data/ldap/config/*
mkdir -p /opt/zimbra/data/ldap/mdb/db /opt/zimbra/data/ldap/mdb/logs
chown -R zimbra:zimbra /opt/zimbra/data/ldap

# Initialize LDAP with explicit Master password
su - zimbra -c "/opt/zimbra/libexec/zmldapinit --p '$ADMIN_PASSWORD'"

# Force Master Mode 
su - zimbra -c "zmlocalconfig -f -e ldap_replication_type=master"
su - zimbra -c "zmlocalconfig -f -e ldap_is_master=true"
su - zimbra -c "zmlocalconfig -f -e zimbra_ldap_password='$ADMIN_PASSWORD'"
su - zimbra -c "zmlocalconfig -f -e ldap_root_password='$ADMIN_PASSWORD'"
su - zimbra -c "zmlocalconfig -f -e ldap_url='ldap://localhost:389'"
su - zimbra -c "zmlocalconfig -f -e ldap_master_url='ldap://localhost:389'"

# Start Pure LDAP
su - zimbra -c "/opt/zimbra/bin/ldap start"

# 4. SSL CERTIFICATE GENERATION
log "Step 4: Generating Internal CA and SSL..."
su - zimbra -c "/opt/zimbra/bin/zmcertmgr createca -new"
su - zimbra -c "/opt/zimbra/bin/zmcertmgr createcrt -new -days 3650"
su - zimbra -c "/opt/zimbra/bin/zmcertmgr deployca"
su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt self"

# 5. FINAL CONFIGURATION (The "House" Setup)
log "Step 5: Running Final Configuration..."
cat > /tmp/effortless-answers <<EOF
AVDOMAIN=$ZIMBRA_DOMAIN
AVUSER=admin@$ZIMBRA_DOMAIN
CREATEADMIN=admin@$ZIMBRA_DOMAIN
CREATEADMINPASS=$ADMIN_PASSWORD
CREATEDOMAIN=$ZIMBRA_DOMAIN
DOCREATEADMIN=yes
DOCREATEDOMAIN=yes
HOSTNAME=$ZIMBRA_HOSTNAME
HTTPPORT=8080
HTTPPROXY=TRUE
HTTPSPORT=8443
INSTALL_WEBAPPS=service zimlet zimbra zimbraAdmin
LDAPHOST=localhost
LDAPPORT=389
LDAPREPLICATIONTYPE=master
LDAPROOTPASS=$ADMIN_PASSWORD
MAILBOXDMEMORY=1024
MAILPROXY=TRUE
MODE=https
MYSQLMEMORYPERCENT=30
RUNAV=yes
RUNDKIM=yes
RUNSA=yes
STARTSERVERS=yes
SYSTEMMEMORY=3.8
zimbraIPMode=ipv4
zimbraMtaMyNetworks=127.0.0.0/8 $SERVER_IP/32
zimbra_server_hostname=$ZIMBRA_HOSTNAME
EOF

/opt/zimbra/libexec/zmsetup.pl -c /tmp/effortless-answers 2>&1 | tee -a "$LOG_FILE"

# 6. START ALL SERVICES
log "Step 6: Starting all services..."
su - zimbra -c "zmcontrol restart"

log "===================================================="
log "ZIMBRA INSTALLATION EFFORTLESSLY COMPLETED"
log "===================================================="
log "Admin: https://$ZIMBRA_HOSTNAME:7071"
log "Webmail: https://$ZIMBRA_HOSTNAME"
log "User: admin@$ZIMBRA_DOMAIN"
log "Pass: $ADMIN_PASSWORD"
log "===================================================="
