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

# Create Zimbra configuration file for zmsetup
log "Creating Zimbra configuration answers file..."

cat > /tmp/zcs-answers <<ANSWERS_EOF
AVDOMAIN=$ZIMBRA_DOMAIN
AVUSER=admin@$ZIMBRA_DOMAIN
CREATEADMIN=admin@$ZIMBRA_DOMAIN
CREATEADMINPASS=$ADMIN_PASSWORD
CREATEDOMAIN=$ZIMBRA_DOMAIN
DOCREATEADMIN=yes
DOCREATEDOMAIN=yes
DOTRAINSA=yes
EXPANDMENU=no
HOSTNAME=$ZIMBRA_HOSTNAME
HTTPPORT=8080
HTTPPROXY=TRUE
HTTPPROXYPORT=80
HTTPSPORT=8443
HTTPSPROXYPORT=443
IMAPPORT=7143
IMAPPROXYPORT=143
IMAPSSLPORT=7993
IMAPSSLPROXYPORT=993
INSTALL_WEBAPPS=service zimlet zimbra zimbraAdmin
JAVAHOME=/opt/zimbra/common/lib/jvm/java
LDAPHOST=$ZIMBRA_HOSTNAME
LDAPPORT=389
LDAPREPLICATIONTYPE=master
LDAPSERVERID=1
LDAPROOTPASS=$ADMIN_PASSWORD
LDAPADMINPASS=$ADMIN_PASSWORD
LDAPREPPASS=$ADMIN_PASSWORD
LDAPPOSTPASS=$ADMIN_PASSWORD
LDAPAMAVISPASS=$ADMIN_PASSWORD
MAILBOXDMEMORY=1024
MAILPROXY=TRUE
MODE=https
MYSQLMEMORYPERCENT=30
REMOVE=no
RUNARCHIVING=no
RUNAV=yes
RUNCBPOLICYD=no
RUNDKIM=yes
RUNSA=yes
RUNVMHA=no
SERVICEWEBAPP=yes
SMTPDEST=admin@$ZIMBRA_DOMAIN
SMTPHOST=$ZIMBRA_HOSTNAME
SMTPNOTIFY=yes
SMTPSOURCE=admin@$ZIMBRA_DOMAIN
SNMPNOTIFY=yes
SNMPTRAPHOST=$ZIMBRA_HOSTNAME
SPELLURL=http://$ZIMBRA_HOSTNAME:7780/aspell.php
STARTSERVERS=yes
SYSTEMMEMORY=3.8
TRAINSAHAM=ham.xxxxxx@$ZIMBRA_DOMAIN
TRAINSASPAM=spam.xxxxxx@$ZIMBRA_DOMAIN
UIWEBAPPS=yes
UPGRADE=yes
USEKBSHORTCUTS=TRUE
USESPELL=yes
VERSIONUPDATECHECKS=TRUE
VIRUSQUARANTINE=virus-quarantine.xxxxxx@$ZIMBRA_DOMAIN
ZIMBRA_REQ_SECURITY=yes
ldap_bes_searcher_password=$ADMIN_PASSWORD
ldap_dit_base_dn_config=cn=zimbra
ldap_nginx_password=$ADMIN_PASSWORD
mailboxd_directory=/opt/zimbra/mailboxd
mailboxd_keystore=/opt/zimbra/mailboxd/etc/keystore
mailboxd_keystore_password=$ADMIN_PASSWORD
mailboxd_server=jetty
mailboxd_truststore=/opt/zimbra/common/etc/java/cacerts
mailboxd_truststore_password=changeit
postfix_mail_owner=postfix
postfix_setgid_group=postdrop
ssl_default_digest=sha256
zimbraDefaultDomainName=$ZIMBRA_DOMAIN
zimbraFeatureBriefcasesEnabled=Enabled
zimbraFeatureTasksEnabled=Enabled
zimbraIPMode=ipv4
zimbraMailProxy=TRUE
zimbraMtaMyNetworks=127.0.0.0/8 $SERVER_IP/32
zimbraPrefTimeZoneId=Europe/Berlin
zimbraReverseProxyLookupTarget=TRUE
zimbraVersionCheckInterval=1d
zimbraVersionCheckNotificationEmail=admin@$ZIMBRA_DOMAIN
zimbraVersionCheckNotificationEmailFrom=admin@$ZIMBRA_DOMAIN
zimbraVersionCheckSendNotifications=TRUE
zimbraWebProxy=TRUE
zimbra_ldap_userdn=uid=zimbra,cn=admins,cn=zimbra
zimbra_require_interprocess_security=1
zimbra_server_hostname=$ZIMBRA_HOSTNAME
INSTALL_PACKAGES=zimbra-core zimbra-ldap zimbra-logger zimbra-mta zimbra-snmp zimbra-store zimbra-apache zimbra-spell zimbra-memcached zimbra-proxy
ANSWERS_EOF

# Run zmsetup with the configuration file
log "Running Zimbra configuration with zmsetup..."
log "This will initialize LDAP, create domain, and configure all services..."

/opt/zimbra/libexec/zmsetup.pl -c /tmp/zcs-answers 2>&1 | tee -a "$LOG_FILE"

SETUP_EXIT_CODE=${PIPESTATUS[0]}

if [ $SETUP_EXIT_CODE -ne 0 ]; then
    log_error "Zimbra configuration failed with exit code: $SETUP_EXIT_CODE"
    log_error "Check the logs:"
    log_error "  - $LOG_FILE"
    log_error "  - /opt/zimbra/log/zmsetup.log"
    
    if [ -f /opt/zimbra/log/slapd.log ]; then
        log_error "LDAP log:"
        tail -n 50 /opt/zimbra/log/slapd.log
    fi
    
    exit 1
fi

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
