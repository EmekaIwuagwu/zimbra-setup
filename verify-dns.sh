#!/bin/bash

################################################################################
# DNS Verification Script for maybax.de
# Tests all DNS records before and after Zimbra installation
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="maybax.de"
MAIL_HOST="mail.maybax.de"
SERVER_IP="173.249.1.171"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DNS Verification for maybax.de${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Test A record for mail subdomain
echo -e "${BLUE}Testing A record for mail.maybax.de...${NC}"
RESULT=$(nslookup mail.maybax.de 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}')
if [[ "$RESULT" == "$SERVER_IP" ]]; then
    echo -e "${GREEN}✓ PASS${NC} - mail.maybax.de → $RESULT"
else
    echo -e "${RED}✗ FAIL${NC} - Expected $SERVER_IP, got $RESULT"
    echo -e "${YELLOW}  Action: Add A record at Spaceship.com${NC}"
fi
echo ""

# Test MX record
echo -e "${BLUE}Testing MX record for maybax.de...${NC}"
MX_RESULT=$(nslookup -query=mx maybax.de 2>/dev/null | grep "mail exchanger" | awk '{print $NF}' | sed 's/\.$//')
if [[ "$MX_RESULT" == "mail.maybax.de" ]]; then
    echo -e "${GREEN}✓ PASS${NC} - MX record points to mail.maybax.de"
else
    echo -e "${RED}✗ FAIL${NC} - MX record points to: $MX_RESULT"
    echo -e "${YELLOW}  Action: Add MX record at Spaceship.com${NC}"
fi
echo ""

# Test SPF record
echo -e "${BLUE}Testing SPF record...${NC}"
SPF_RESULT=$(nslookup -query=txt maybax.de 2>/dev/null | grep "v=spf1")
if [[ -n "$SPF_RESULT" ]]; then
    echo -e "${GREEN}✓ PASS${NC} - SPF record found"
    echo -e "  $SPF_RESULT"
else
    echo -e "${RED}✗ FAIL${NC} - SPF record not found"
    echo -e "${YELLOW}  Action: Add TXT record: v=spf1 mx ip4:173.249.1.171 ~all${NC}"
fi
echo ""

# Test DKIM record
echo -e "${BLUE}Testing DKIM record...${NC}"
DKIM_RESULT=$(nslookup -query=txt default._domainkey.maybax.de 2>/dev/null | grep "v=DKIM1")
if [[ -n "$DKIM_RESULT" ]]; then
    echo -e "${GREEN}✓ PASS${NC} - DKIM record found"
else
    echo -e "${YELLOW}⚠ WARN${NC} - DKIM record not found (add after Zimbra installation)"
fi
echo ""

# Test DMARC record
echo -e "${BLUE}Testing DMARC record...${NC}"
DMARC_RESULT=$(nslookup -query=txt _dmarc.maybax.de 2>/dev/null | grep "v=DMARC1")
if [[ -n "$DMARC_RESULT" ]]; then
    echo -e "${GREEN}✓ PASS${NC} - DMARC record found"
    echo -e "  $DMARC_RESULT"
else
    echo -e "${RED}✗ FAIL${NC} - DMARC record not found"
    echo -e "${YELLOW}  Action: Add TXT record at _dmarc: v=DMARC1; p=quarantine${NC}"
fi
echo ""

# Test reverse DNS (PTR)
echo -e "${BLUE}Testing Reverse DNS (PTR) for 173.249.1.171...${NC}"
PTR_RESULT=$(nslookup 173.249.1.171 2>/dev/null | grep "name =" | awk '{print $NF}' | sed 's/\.$//')
if [[ "$PTR_RESULT" == "mail.maybax.de" ]]; then
    echo -e "${GREEN}✓ PASS${NC} - PTR record: 173.249.1.171 → mail.maybax.de"
else
    echo -e "${RED}✗ FAIL${NC} - PTR record points to: $PTR_RESULT"
    echo -e "${YELLOW}  Action: Contact hosting provider to set PTR record${NC}"
fi
echo ""

# Test if ports are open (if running on the server)
if [[ "$SERVER_IP" == "$(hostname -I | awk '{print $1}')" ]]; then
    echo -e "${BLUE}Testing if server ports are reachable (local test)...${NC}"
    
    # Test port 25 (SMTP)
    if netstat -tuln 2>/dev/null | grep -q ":25 "; then
        echo -e "${GREEN}✓ PASS${NC} - Port 25 (SMTP) is open"
    else
        echo -e "${YELLOW}⚠ WARN${NC} - Port 25 not detected (Zimbra may not be installed yet)"
    fi
    
    # Test port 443 (HTTPS)
    if netstat -tuln 2>/dev/null | grep -q ":443 "; then
        echo -e "${GREEN}✓ PASS${NC} - Port 443 (HTTPS) is open"
    else
        echo -e "${YELLOW}⚠ WARN${NC} - Port 443 not detected"
    fi
    echo ""
fi

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DNS Propagation Check${NC}"
echo -e "${BLUE}========================================${NC}\n"
echo -e "Use online tools for global propagation check:"
echo -e "1. https://dnschecker.org/ (enter: mail.maybax.de)"
echo -e "2. https://mxtoolbox.com/SuperTool.aspx (enter: maybax.de)"
echo -e ""
echo -e "${YELLOW}Note:${NC} DNS changes can take 1-24 hours to propagate globally"
echo -e ""

# Check if dig is available for more detailed tests
if command -v dig &> /dev/null; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Detailed DNS Records (using dig)${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    echo -e "${BLUE}A Record:${NC}"
    dig +short mail.maybax.de A
    echo ""
    
    echo -e "${BLUE}MX Record:${NC}"
    dig +short maybax.de MX
    echo ""
    
    echo -e "${BLUE}TXT Records (SPF/DMARC):${NC}"
    dig +short maybax.de TXT
    echo ""
    
    echo -e "${BLUE}DKIM Record:${NC}"
    dig +short default._domainkey.maybax.de TXT
    echo ""
    
    echo -e "${BLUE}PTR Record:${NC}"
    dig +short -x 173.249.1.171
    echo ""
fi

echo -e "${GREEN}DNS verification complete!${NC}"
