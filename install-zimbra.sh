#!/bin/bash

################################################################################
# Zimbra Collaboration Suite - Automated Installation Script for Ubuntu
# Author: Senior IT Administrator
# Version: 1.0.0
# Description: Automated setup and installation of Zimbra on Ubuntu Linux
# Tested on: Ubuntu 20.04 LTS, Ubuntu 22.04 LTS
################################################################################

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration Variables
ZIMBRA_VERSION="10.0.9"
ZIMBRA_DOWNLOAD_URL="https://files.zimbra.com/downloads/${ZIMBRA_VERSION}_GA/zcs-${ZIMBRA_VERSION}_GA_4955.UBUNTU20_64.20240228075928.tgz"
INSTALL_DIR="/tmp/zimbra-install"
LOG_FILE="/var/log/zimbra-install.log"
ZIMBRA_HOSTNAME=""
ZIMBRA_DOMAIN=""
ADMIN_PASSWORD=""

################################################################################
# Logging Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "${LOG_FILE}"
}

################################################################################
# Utility Functions
################################################################################

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Check Ubuntu version
check_ubuntu_version() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine OS version"
        exit 1
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        log_error "This script is designed for Ubuntu Linux only"
        exit 1
    fi
    
    log "Detected Ubuntu version: $VERSION"
    
    # Check if version is supported
    VERSION_ID_NUM=$(echo "$VERSION_ID" | cut -d. -f1)
    if [[ "$VERSION_ID_NUM" -lt 20 ]]; then
        log_warning "Ubuntu version $VERSION_ID may not be fully supported. Recommended: 20.04 or 22.04"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Gather installation parameters
gather_parameters() {
    log_info "Gathering installation parameters..."
    
    # Get hostname
    if [[ -z "$ZIMBRA_HOSTNAME" ]]; then
        read -p "Enter Zimbra server hostname (e.g., mail.example.com): " ZIMBRA_HOSTNAME
        if [[ -z "$ZIMBRA_HOSTNAME" ]]; then
            log_error "Hostname cannot be empty"
            exit 1
        fi
    fi
    
    # Extract domain from hostname
    if [[ -z "$ZIMBRA_DOMAIN" ]]; then
        ZIMBRA_DOMAIN=$(echo "$ZIMBRA_HOSTNAME" | cut -d. -f2-)
        read -p "Detected domain: $ZIMBRA_DOMAIN. Is this correct? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            read -p "Enter domain name: " ZIMBRA_DOMAIN
        fi
    fi
    
    # Get admin password
    if [[ -z "$ADMIN_PASSWORD" ]]; then
        while true; do
            read -s -p "Enter Zimbra admin password (min 8 characters): " ADMIN_PASSWORD
            echo
            read -s -p "Confirm password: " ADMIN_PASSWORD_CONFIRM
            echo
            
            if [[ "$ADMIN_PASSWORD" == "$ADMIN_PASSWORD_CONFIRM" ]]; then
                if [[ ${#ADMIN_PASSWORD} -lt 8 ]]; then
                    log_error "Password must be at least 8 characters"
                    continue
                fi
                break
            else
                log_error "Passwords do not match"
            fi
        done
    fi
    
    log "Configuration:"
    log "  Hostname: $ZIMBRA_HOSTNAME"
    log "  Domain: $ZIMBRA_DOMAIN"
}

# Check system requirements
check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check RAM (minimum 4GB recommended)
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    if [[ "$TOTAL_RAM" -lt 4 ]]; then
        log_warning "System has ${TOTAL_RAM}GB RAM. Minimum recommended is 4GB"
    else
        log "RAM: ${TOTAL_RAM}GB - OK"
    fi
    
    # Check disk space (minimum 10GB free)
    FREE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ "$FREE_SPACE" -lt 10 ]]; then
        log_error "Insufficient disk space. Need at least 10GB free, found ${FREE_SPACE}GB"
        exit 1
    else
        log "Disk space: ${FREE_SPACE}GB free - OK"
    fi
}

# Configure hostname
configure_hostname() {
    log_info "Configuring hostname..."
    
    # Set hostname
    hostnamectl set-hostname "$ZIMBRA_HOSTNAME"
    
    # Update /etc/hosts
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    # Backup original hosts file
    cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d%H%M%S)
    
    # Remove old entries and add new ones
    sed -i "/$ZIMBRA_HOSTNAME/d" /etc/hosts
    echo "$SERVER_IP $ZIMBRA_HOSTNAME $(hostname -s)" >> /etc/hosts
    
    log "Hostname configured: $ZIMBRA_HOSTNAME ($SERVER_IP)"
}

# Disable conflicting services
disable_conflicting_services() {
    log_info "Checking for conflicting services..."
    
    # Services that conflict with Zimbra
    CONFLICTING_SERVICES=("postfix" "sendmail" "apache2" "bind9")
    
    for service in "${CONFLICTING_SERVICES[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log_warning "Stopping and disabling $service"
            systemctl stop "$service"
            systemctl disable "$service"
        fi
    done
}

# Install dependencies
install_dependencies() {
    log_info "Installing required dependencies..."
    
    # Update package lists
    apt-get update -qq
    
    # Detect Ubuntu version for package compatibility
    source /etc/os-release
    VERSION_NUM=$(echo "$VERSION_ID" | cut -d. -f1)
    
    # Set package names based on Ubuntu version
    if [[ "$VERSION_NUM" -ge 24 ]]; then
        # Ubuntu 24.04+ uses different package names
        IDN_PKG="libidn12"
        AIO_PKG="libaio1t64"
        NCURSES_PKG="libncurses6"
        NETCAT_PKG="netcat-openbsd"
        log "Using Ubuntu 24.04+ package names"
    else
        # Ubuntu 20.04/22.04 package names
        IDN_PKG="libidn11"
        AIO_PKG="libaio1"
        NCURSES_PKG="libncurses5"
        NETCAT_PKG="netcat"
        log "Using Ubuntu 20.04/22.04 package names"
    fi
    
    # Install prerequisites
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libgmp10 \
        libpopt0 \
        sqlite3 \
        ${IDN_PKG} \
        libpcre3 \
        libexpat1 \
        libgcc-s1 \
        libstdc++6 \
        wget \
        curl \
        ${NETCAT_PKG} \
        sudo \
        ${AIO_PKG} \
        ${NCURSES_PKG} \
        perl \
        perl-modules-5.* \
        dnsutils \
        sysstat \
        unzip \
        rsyslog \
        net-tools 2>&1 | tee -a "${LOG_FILE}"
    
    log "Dependencies installed successfully"
}

# Configure firewall
configure_firewall() {
    log_info "Configuring firewall rules..."
    
    if command -v ufw &> /dev/null; then
        # Allow Zimbra ports
        ufw allow 25/tcp    # SMTP
        ufw allow 80/tcp    # HTTP
        ufw allow 110/tcp   # POP3
        ufw allow 143/tcp   # IMAP
        ufw allow 443/tcp   # HTTPS
        ufw allow 465/tcp   # SMTPS
        ufw allow 587/tcp   # Submission
        ufw allow 993/tcp   # IMAPS
        ufw allow 995/tcp   # POP3S
        ufw allow 7071/tcp  # Admin Console
        ufw allow 8443/tcp  # Admin Console SSL
        
        log "Firewall rules configured"
    else
        log_warning "UFW not found. Please configure firewall manually"
    fi
}

# Download Zimbra
download_zimbra() {
    log_info "Downloading Zimbra Collaboration Suite..."
    
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Download with progress
    if [[ ! -f "zimbra-installer.tgz" ]]; then
        wget -O zimbra-installer.tgz "$ZIMBRA_DOWNLOAD_URL" 2>&1 | tee -a "${LOG_FILE}"
        
        if [[ $? -ne 0 ]]; then
            log_error "Failed to download Zimbra. Please check the download URL"
            exit 1
        fi
    else
        log "Zimbra installer already downloaded"
    fi
    
    log "Extracting Zimbra installer..."
    tar xzf zimbra-installer.tgz
    
    # Find extracted directory
    ZIMBRA_EXTRACT_DIR=$(find . -maxdepth 1 -type d -name "zcs-*" | head -n 1)
    
    if [[ -z "$ZIMBRA_EXTRACT_DIR" ]]; then
        log_error "Failed to extract Zimbra installer"
        exit 1
    fi
    
    log "Zimbra extracted to: $ZIMBRA_EXTRACT_DIR"
}

# Create installation config file
create_install_config() {
    log_info "Creating installation configuration..."
    
    cat > /tmp/zimbra-install-config <<EOF
AVDOMAIN="$ZIMBRA_DOMAIN"
AVUSER="admin@$ZIMBRA_DOMAIN"
CREATEADMIN="admin@$ZIMBRA_DOMAIN"
CREATEADMINPASS="$ADMIN_PASSWORD"
CREATEDOMAIN="$ZIMBRA_DOMAIN"
DOCREATEADMIN="yes"
DOCREATEDOMAIN="yes"
DOTRAINSA="yes"
EXPANDMENU="no"
HOSTNAME="$ZIMBRA_HOSTNAME"
HTTPPORT="8080"
HTTPPROXY="TRUE"
HTTPPROXYPORT="80"
HTTPSPORT="8443"
HTTPSPROXYPORT="443"
IMAPPORT="7143"
IMAPPROXYPORT="143"
IMAPSSLPORT="7993"
IMAPSSLPROXYPORT="993"
INSTALL_WEBAPPS="service zimlet zimbra zimbraAdmin"
JAVAHOME="/opt/zimbra/common/lib/jvm/java"
LDAPAMAVISPASS="$ADMIN_PASSWORD"
LDAPPOSTPASS="$ADMIN_PASSWORD"
LDAPROOTPASS="$ADMIN_PASSWORD"
LDAPADMINPASS="$ADMIN_PASSWORD"
LDAPREPPASS="$ADMIN_PASSWORD"
LDAPBESSEARCHSET="set"
LDAPHOST="$ZIMBRA_HOSTNAME"
LDAPPORT="389"
LDAPREPLICATIONTYPE="master"
LDAPSERVERID="2"
MAILBOXDMEMORY="512"
MAILPROXY="TRUE"
MODE="https"
MYSQLMEMORYPERCENT="30"
POPPORT="7110"
POPPROXYPORT="110"
POPSSLPORT="7995"
POPSSLPROXYPORT="995"
PROXYMODE="https"
REMOVE="no"
RUNARCHIVING="no"
RUNAV="yes"
RUNCBPOLICYD="no"
RUNDKIM="yes"
RUNSA="yes"
RUNVMHA="no"
SERVICEWEBAPP="yes"
SMTPDEST="admin@$ZIMBRA_DOMAIN"
SMTPHOST="$ZIMBRA_HOSTNAME"
SMTPNOTIFY="yes"
SMTPSOURCE="admin@$ZIMBRA_DOMAIN"
SNMPNOTIFY="yes"
SNMPTRAPHOST="$ZIMBRA_HOSTNAME"
SPELLURL="http://$ZIMBRA_HOSTNAME:7780/aspell.php"
STARTSERVERS="yes"
SYSTEMMEMORY="3.8"
TRAINSAHAM="ham.xxxxxx@$ZIMBRA_DOMAIN"
TRAINSASPAM="spam.xxxxxx@$ZIMBRA_DOMAIN"
UIWEBAPPS="yes"
UPGRADE="yes"
USEKBSHORTCUTS="TRUE"
USESPELL="yes"
VERSIONUPDATECHECKS="TRUE"
VIRUSQUARANTINE="virus-quarantine.xxxxxx@$ZIMBRA_DOMAIN"
ZIMBRA_REQ_SECURITY="yes"
ldap_bes_searcher_password="$ADMIN_PASSWORD"
ldap_dit_base_dn_config="cn=zimbra"
ldap_nginx_password="$ADMIN_PASSWORD"
mailboxd_directory="/opt/zimbra/mailboxd"
mailboxd_keystore="/opt/zimbra/mailboxd/etc/keystore"
mailboxd_keystore_password="$ADMIN_PASSWORD"
mailboxd_server="jetty"
mailboxd_truststore="/opt/zimbra/common/etc/java/cacerts"
mailboxd_truststore_password="changeit"
postfix_mail_owner="postfix"
postfix_setgid_group="postdrop"
ssl_default_digest="sha256"
zimbraDNSMasterIP=""
zimbraDNSTCPUpstream="no"
zimbraDNSUseTCP="yes"
zimbraDNSUseUDP="yes"
zimbraDefaultDomainName="$ZIMBRA_DOMAIN"
zimbraFeatureBriefcasesEnabled="Enabled"
zimbraFeatureTasksEnabled="Enabled"
zimbraIPMode="ipv4"
zimbraMailProxy="FALSE"
zimbraMtaMyNetworks="127.0.0.0/8 $SERVER_IP/32 [::1]/128 [fe80::]/64"
zimbraPrefTimeZoneId="America/New_York"
zimbraReverseProxyLookupTarget="TRUE"
zimbraVersionCheckInterval="1d"
zimbraVersionCheckNotificationEmail="admin@$ZIMBRA_DOMAIN"
zimbraVersionCheckNotificationEmailFrom="admin@$ZIMBRA_DOMAIN"
zimbraVersionCheckSendNotifications="TRUE"
zimbraWebProxy="FALSE"
zimbra_ldap_userdn="uid=zimbra,cn=admins,cn=zimbra"
zimbra_require_interprocess_security="1"
zimbra_server_hostname="$ZIMBRA_HOSTNAME"
INSTALL_PACKAGES="zimbra-core zimbra-ldap zimbra-logger zimbra-mta zimbra-snmp zimbra-store zimbra-apache zimbra-spell zimbra-memcached zimbra-proxy"
EOF

    log "Installation configuration created"
}

# Install Zimbra
install_zimbra() {
    log_info "Installing Zimbra Collaboration Suite..."
    
    cd "$ZIMBRA_EXTRACT_DIR"
    
    # Run installer with automated config
    ./install.sh -s < /tmp/zimbra-install-config 2>&1 | tee -a "${LOG_FILE}"
    
    if [[ $? -ne 0 ]]; then
        log_error "Zimbra installation failed. Check log file: $LOG_FILE"
        exit 1
    fi
    
    log "Zimbra installation completed successfully"
}

# Post-installation configuration
post_install_configuration() {
    log_info "Performing post-installation configuration..."
    
    # Set admin password
    su - zimbra -c "/opt/zimbra/bin/zmprov sp admin@$ZIMBRA_DOMAIN '$ADMIN_PASSWORD'"
    
    # Enable services
    su - zimbra -c "/opt/zimbra/bin/zmcontrol start" 2>&1 | tee -a "${LOG_FILE}"
    
    log "Post-installation configuration completed"
}

# Verify installation
verify_installation() {
    log_info "Verifying Zimbra installation..."
    
    sleep 10  # Wait for services to start
    
    # Check Zimbra services
    if su - zimbra -c "/opt/zimbra/bin/zmcontrol status" | grep -q "Running"; then
        log "Zimbra services are running"
    else
        log_warning "Some Zimbra services may not be running. Check with: su - zimbra -c '/opt/zimbra/bin/zmcontrol status'"
    fi
    
    # Display access information
    log ""
    log "================================================"
    log "Zimbra Installation Complete!"
    log "================================================"
    log "Admin Console: https://$ZIMBRA_HOSTNAME:7071"
    log "Webmail: https://$ZIMBRA_HOSTNAME"
    log "Username: admin@$ZIMBRA_DOMAIN"
    log "Password: [as configured]"
    log ""
    log "Important Notes:"
    log "- Make sure DNS records are configured for $ZIMBRA_HOSTNAME"
    log "- Configure SSL certificates for production use"
    log "- Review firewall settings"
    log "- Set up regular backups"
    log "================================================"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    
    rm -f /tmp/zimbra-install-config
    
    # Optionally remove installer
    read -p "Remove installation files to save space? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        log "Installation files removed"
    fi
}

# Main installation flow
main() {
    log "========================================"
    log "Zimbra Automated Installation Script"
    log "========================================"
    log ""
    
    check_root
    check_ubuntu_version
    gather_parameters
    check_system_requirements
    configure_hostname
    disable_conflicting_services
    install_dependencies
    configure_firewall
    download_zimbra
    create_install_config
    install_zimbra
    post_install_configuration
    verify_installation
    cleanup
    
    log ""
    log "Installation completed at: $(date)"
    log "Log file: $LOG_FILE"
}

# Error handler
trap 'log_error "Installation failed at line $LINENO. Check log: $LOG_FILE"; exit 1' ERR

# Run main function
main "$@"
