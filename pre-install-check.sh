#!/bin/bash

################################################################################
# Zimbra Pre-Installation System Check Script
# Author: Senior IT Administrator
# Version: 1.0.0
# Description: Validates system readiness for Zimbra installation
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Print functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++))
}

# Check functions
check_root() {
    print_check "Checking root privileges..."
    if [[ $EUID -eq 0 ]]; then
        print_pass "Running as root"
    else
        print_fail "Must run as root. Use: sudo $0"
    fi
}

check_os() {
    print_check "Checking operating system..."
    
    if [[ ! -f /etc/os-release ]]; then
        print_fail "Cannot determine OS version"
        return
    fi
    
    source /etc/os-release
    
    if [[ "$ID" == "ubuntu" ]]; then
        VERSION_NUM=$(echo "$VERSION_ID" | cut -d. -f1)
        
        if [[ "$VERSION_NUM" -ge 20 ]]; then
            print_pass "Ubuntu $VERSION_ID detected (supported)"
        elif [[ "$VERSION_NUM" -ge 18 ]]; then
            print_warn "Ubuntu $VERSION_ID detected (may work, but 20.04+ recommended)"
        else
            print_fail "Ubuntu $VERSION_ID is too old (20.04+ required)"
        fi
    else
        print_fail "Not running Ubuntu Linux (found: $ID)"
    fi
}

check_architecture() {
    print_check "Checking system architecture..."
    
    ARCH=$(uname -m)
    
    if [[ "$ARCH" == "x86_64" ]]; then
        print_pass "64-bit architecture detected"
    else
        print_fail "64-bit architecture required (found: $ARCH)"
    fi
}

check_memory() {
    print_check "Checking system memory..."
    
    TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
    TOTAL_RAM_GB=$((TOTAL_RAM_MB / 1024))
    
    if [[ $TOTAL_RAM_GB -ge 8 ]]; then
        print_pass "${TOTAL_RAM_GB}GB RAM available (excellent)"
    elif [[ $TOTAL_RAM_GB -ge 4 ]]; then
        print_warn "${TOTAL_RAM_GB}GB RAM available (minimum met, 8GB+ recommended for production)"
    else
        print_fail "${TOTAL_RAM_GB}GB RAM available (4GB minimum required)"
    fi
}

check_disk_space() {
    print_check "Checking disk space..."
    
    FREE_SPACE_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    TOTAL_SPACE_GB=$(df -BG / | awk 'NR==2 {print $2}' | sed 's/G//')
    
    if [[ $FREE_SPACE_GB -ge 50 ]]; then
        print_pass "${FREE_SPACE_GB}GB free space available (excellent)"
    elif [[ $FREE_SPACE_GB -ge 10 ]]; then
        print_warn "${FREE_SPACE_GB}GB free space available (minimum met, 50GB+ recommended)"
    else
        print_fail "${FREE_SPACE_GB}GB free space available (10GB minimum required)"
    fi
}

check_cpu() {
    print_check "Checking CPU cores..."
    
    CPU_CORES=$(nproc)
    
    if [[ $CPU_CORES -ge 4 ]]; then
        print_pass "$CPU_CORES CPU cores available (excellent)"
    elif [[ $CPU_CORES -ge 2 ]]; then
        print_warn "$CPU_CORES CPU cores available (minimum met, 4+ recommended)"
    else
        print_fail "$CPU_CORES CPU core(s) available (2 cores minimum required)"
    fi
}

check_hostname() {
    print_check "Checking hostname configuration..."
    
    SHORT_HOSTNAME=$(hostname -s 2>/dev/null)
    FQDN=$(hostname -f 2>/dev/null)
    
    if [[ -z "$FQDN" ]]; then
        print_fail "FQDN not properly configured (current: $SHORT_HOSTNAME)"
        echo -e "       ${YELLOW}Set FQDN with: hostnamectl set-hostname mail.maybax.de${NC}"
    elif [[ "$FQDN" == "$SHORT_HOSTNAME" ]] || [[ ! "$FQDN" =~ \. ]]; then
        print_fail "FQDN is same as short hostname (current: $FQDN)"
        echo -e "       ${YELLOW}Set FQDN with: hostnamectl set-hostname mail.maybax.de${NC}"
    elif [[ "$FQDN" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        print_pass "FQDN configured: $FQDN"
    else
        print_warn "FQDN format may be invalid: $FQDN"
    fi
}

check_hosts_file() {
    print_check "Checking /etc/hosts configuration..."
    
    FQDN=$(hostname -f 2>/dev/null)
    HOSTNAME=$(hostname -s)
    
    if grep -q "$FQDN" /etc/hosts; then
        print_pass "/etc/hosts contains FQDN entry"
    else
        print_warn "FQDN not found in /etc/hosts"
        echo -e "       ${YELLOW}Add entry: <IP> $FQDN $HOSTNAME${NC}"
    fi
}

check_dns_resolution() {
    print_check "Checking DNS resolution..."
    
    FQDN=$(hostname -f 2>/dev/null)
    
    if command -v nslookup &> /dev/null; then
        if nslookup "$FQDN" &> /dev/null; then
            print_pass "DNS resolution working for $FQDN"
        else
            print_warn "DNS resolution failed for $FQDN (may work with local /etc/hosts)"
        fi
    else
        print_warn "nslookup not available, install dnsutils to check DNS"
    fi
}

check_internet() {
    print_check "Checking internet connectivity..."
    
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_pass "Internet connectivity available"
    else
        print_fail "No internet connectivity (required for installation)"
    fi
}

check_ports() {
    print_check "Checking for port conflicts..."
    
    REQUIRED_PORTS=(25 80 443 587 993 7071 8443)
    CONFLICTS=0
    
    for port in "${REQUIRED_PORTS[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            print_warn "Port $port is already in use"
            PROCESS=$(netstat -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}')
            echo -e "       ${YELLOW}Process: $PROCESS${NC}"
            ((CONFLICTS++))
        fi
    done
    
    if [[ $CONFLICTS -eq 0 ]]; then
        print_pass "No port conflicts detected"
    fi
}

check_services() {
    print_check "Checking for conflicting services..."
    
    CONFLICTING=("postfix" "sendmail" "apache2" "nginx" "bind9")
    CONFLICTS=0
    
    for service in "${CONFLICTING[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            print_warn "Service $service is running (will be stopped during installation)"
            ((CONFLICTS++))
        fi
    done
    
    if [[ $CONFLICTS -eq 0 ]]; then
        print_pass "No conflicting services running"
    fi
}

check_selinux() {
    print_check "Checking SELinux status..."
    
    if command -v getenforce &> /dev/null; then
        SELINUX_STATUS=$(getenforce)
        if [[ "$SELINUX_STATUS" == "Disabled" || "$SELINUX_STATUS" == "Permissive" ]]; then
            print_pass "SELinux is $SELINUX_STATUS"
        else
            print_warn "SELinux is Enforcing (may cause issues)"
        fi
    else
        print_pass "SELinux not installed"
    fi
}

check_apparmor() {
    print_check "Checking AppArmor status..."
    
    if command -v aa-status &> /dev/null; then
        if systemctl is-active --quiet apparmor; then
            print_warn "AppArmor is active (may need Zimbra profile)"
        else
            print_pass "AppArmor is inactive"
        fi
    else
        print_pass "AppArmor not installed"
    fi
}

check_swap() {
    print_check "Checking swap space..."
    
    SWAP_MB=$(free -m | awk '/^Swap:/{print $2}')
    
    if [[ $SWAP_MB -ge 2048 ]]; then
        print_pass "${SWAP_MB}MB swap available (good)"
    elif [[ $SWAP_MB -ge 512 ]]; then
        print_warn "${SWAP_MB}MB swap available (works, but 2GB+ recommended)"
    else
        print_warn "Only ${SWAP_MB}MB swap available (consider adding more)"
    fi
}

check_network_config() {
    print_check "Checking network configuration..."
    
    # Get primary IP
    PRIMARY_IP=$(hostname -I | awk '{print $1}')
    
    if [[ -n "$PRIMARY_IP" ]]; then
        print_pass "Primary IP address: $PRIMARY_IP"
        
        # Check if IP is in private range (warning for production)
        if [[ "$PRIMARY_IP" =~ ^10\. ]] || \
           [[ "$PRIMARY_IP" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] || \
           [[ "$PRIMARY_IP" =~ ^192\.168\. ]]; then
            print_warn "Using private IP address (ensure NAT/firewall properly configured)"
        fi
    else
        print_fail "Cannot determine primary IP address"
    fi
}

check_time_sync() {
    print_check "Checking time synchronization..."
    
    if command -v timedatectl &> /dev/null; then
        if timedatectl status | grep -q "synchronized: yes"; then
            print_pass "System time is synchronized"
        else
            print_warn "System time not synchronized (recommended for mail server)"
            echo -e "       ${YELLOW}Install NTP: apt-get install systemd-timesyncd${NC}"
        fi
    else
        print_warn "Cannot check time synchronization"
    fi
}

check_firewall() {
    print_check "Checking firewall status..."
    
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            print_pass "UFW firewall is active"
        else
            print_warn "UFW firewall is inactive (will be configured during installation)"
        fi
    else
        print_warn "UFW not installed (recommended for security)"
    fi
}

# Main execution
main() {
    print_header "Zimbra Pre-Installation System Check"
    
    echo -e "${BLUE}Starting system readiness validation...${NC}\n"
    
    # Run all checks
    check_root
    check_os
    check_architecture
    check_memory
    check_disk_space
    check_cpu
    check_hostname
    check_hosts_file
    check_dns_resolution
    check_internet
    check_network_config
    check_ports
    check_services
    check_selinux
    check_apparmor
    check_swap
    check_time_sync
    check_firewall
    
    # Summary
    print_header "Check Summary"
    
    echo -e "${GREEN}Passed:${NC}   $PASSED"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo -e "${RED}Failed:${NC}   $FAILED"
    echo ""
    
    # Recommendation
    if [[ $FAILED -eq 0 ]]; then
        if [[ $WARNINGS -eq 0 ]]; then
            echo -e "${GREEN}✓ System is ready for Zimbra installation!${NC}"
            echo -e "Run: ${BLUE}sudo ./install-zimbra.sh${NC}"
        else
            echo -e "${YELLOW}⚠ System can proceed with installation, but review warnings above${NC}"
            echo -e "Run: ${BLUE}sudo ./install-zimbra.sh${NC}"
        fi
    else
        echo -e "${RED}✗ System is NOT ready for installation${NC}"
        echo -e "Please fix the failed checks before proceeding."
    fi
    
    echo ""
}

# Run main function
main "$@"
