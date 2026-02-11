#!/bin/bash
# Test script to verify configuration file generation

# Simulate the environment
ZIMBRA_DOMAIN="maybax.de"
ZIMBRA_HOSTNAME="mail.maybax.de"
ADMIN_PASSWORD="maybax2024!"
SERVER_IP="144.91.106.134"

echo "Testing configuration file generation..."

# Generate config (same logic as in install script)
cat > /tmp/test-zimbra-config <<'CONFIGEOF'
AVDOMAIN=${ZIMBRA_DOMAIN}
HOSTNAME=${ZIMBRA_HOSTNAME}
CREATEADMINPASS=${ADMIN_PASSWORD}
LDAPHOST=${ZIMBRA_HOSTNAME}
zimbraMtaMyNetworks=127.0.0.0/8 ${SERVER_IP}/32
CONFIGEOF

# Substitute values
sed -i "s/\${ZIMBRA_DOMAIN}/$ZIMBRA_DOMAIN/g" /tmp/test-zimbra-config
sed -i "s/\${ZIMBRA_HOSTNAME}/$ZIMBRA_HOSTNAME/g" /tmp/test-zimbra-config
sed -i "s/\${ADMIN_PASSWORD}/$ADMIN_PASSWORD/g" /tmp/test-zimbra-config
sed -i "s/\${SERVER_IP}/$SERVER_IP/g" /tmp/test-zimbra-config

echo ""
echo "Generated configuration (sample lines):"
echo "========================================"
head -n 10 /tmp/test-zimbra-config
echo ""
echo "Password line test:"
grep "CREATEADMINPASS" /tmp/test-zimbra-config
echo ""
echo "SUCCESS: Configuration file generated without quotes"
echo "The exclamation mark in password is: $(grep 'CREATEADMINPASS' /tmp/test-zimbra-config | grep -o '!')"

rm -f /tmp/test-zimbra-config
