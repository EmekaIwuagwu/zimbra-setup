# Zimbra Installation Quick Start Guide

## 🚀 Quick Installation Steps

### Prerequisites
- Ubuntu 20.04 or 22.04 LTS
- 4GB+ RAM (8GB recommended)
- 10GB+ free disk space
- Root/sudo access
- Internet connectivity

### Step 1: Pre-Installation Check

```bash
# Make the script executable
chmod +x pre-install-check.sh

# Run the system check
sudo ./pre-install-check.sh
```

This will validate your system meets all requirements.

### Step 2: Run Installation

```bash
# Make the installer executable
chmod +x install-zimbra.sh

# Run the installation
sudo ./install-zimbra.sh
```

The installer will prompt you for:
- Hostname (e.g., mail.maybax.de)
- Domain (e.g., maybax.de)
- Admin password

Installation takes approximately 15-30 minutes.

### Step 3: Security Hardening (Recommended)

```bash
# Make the hardening script executable
chmod +x post-install-hardening.sh

# Run security hardening
sudo ./post-install-hardening.sh
```

This applies security best practices including:
- Fail2ban for brute-force protection
- Advanced firewall rules
- Password policies
- Automated backups
- Security headers
- Monitoring alerts

### Step 4: Access Zimbra

**Admin Console:**
```
URL: https://mail.maybax.de:7071
Username: admin@maybax.de
Password: [the password you set]
```

**Webmail:**
```
URL: https://mail.maybax.de
Username: admin@maybax.de
Password: [the password you set]
```

## 📋 Complete Installation Workflow

```bash
# 1. Download or clone the scripts
git clone https://github.com/EmekaIwuagwu/zimbra-setup.git
cd zimbra-setup

# 2. Make all scripts executable
chmod +x *.sh

# 3. Run server setup (Sets hostname and /etc/hosts)
sudo ./setup-server.sh

# 4. Run pre-installation check
sudo ./pre-install-check.sh

# 5. Fix any issues identified in step 4

# 6. Run installation
sudo ./install-zimbra.sh

# 7. Wait for installation to complete (15-30 minutes)

# 8. Apply security hardening
sudo ./post-install-hardening.sh

# 9. Access admin console and configure
# https://mail.maybax.de:7071

# 10. Configure DNS records (see DNS Configuration below)

# 11. Install SSL certificate (see SSL Configuration below)
```

## 🔧 Common Configuration Tasks

### DNS Configuration

Add these DNS records at your domain registrar:

```dns
# A Record
mail.maybax.de.       IN  A       173.249.1.171

# MX Record
maybax.de.            IN  MX  10  mail.maybax.de.

# TXT Record for SPF
maybax.de.            IN  TXT     "v=spf1 mx ip4:173.249.1.171 ~all"

# DKIM Record (get from Zimbra after installation)
default._domainkey.maybax.de. IN TXT "v=DKIM1; k=rsa; p=YOUR_PUBLIC_KEY"

# DMARC Record
_dmarc.maybax.de.     IN  TXT     "v=DMARC1; p=quarantine; rua=mailto:dmarc@maybax.de"

# PTR Record (configure at your hosting provider)
171.1.249.173.in-addr.arpa. IN PTR  mail.maybax.de.
```

### Get DKIM Public Key

```bash
su - zimbra -c "zmprov gd maybax.de zimbraDomainDKIMSelector"
su - zimbra -c "zmprov gd maybax.de zimbraDKIMPublicKey"
```

### SSL Certificate Installation

#### Using Let's Encrypt (Free)

```bash
# Install certbot
apt-get install -y certbot

# Stop Zimbra proxy temporarily
su - zimbra -c "zmproxyctl stop"

# Get certificate
certbot certonly --standalone -d mail.maybax.de

# Deploy certificate
su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm /etc/letsencrypt/live/mail.maybax.de/cert.pem /etc/letsencrypt/live/mail.maybax.de/chain.pem"

# Restart Zimbra
su - zimbra -c "zmcontrol restart"

# Auto-renewal
echo "0 3 * * * certbot renew --quiet && su - zimbra -c 'zmcertmgr deploycrt comm /etc/letsencrypt/live/mail.maybax.de/cert.pem /etc/letsencrypt/live/mail.maybax.de/chain.pem' && su - zimbra -c 'zmcontrol restart'" | crontab -
```

#### Using Commercial Certificate

```bash
# 1. Generate CSR
su - zimbra -c "/opt/zimbra/bin/zmcertmgr createcsr comm -new -subject '/C=US/ST=State/L=City/O=Organization/CN=mail.maybax.de'"

# 2. CSR will be in: /opt/zimbra/ssl/zimbra/commercial/commercial.csr
# Submit this to your certificate authority

# 3. After receiving certificate, deploy it
su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm /path/to/cert.crt /path/to/ca_bundle.crt"

# 4. Restart Zimbra
su - zimbra -c "zmcontrol restart"
```

## 🛠️ Useful Commands

### Service Management

```bash
# Check all services
su - zimbra -c "zmcontrol status"

# Start all services
su - zimbra -c "zmcontrol start"

# Stop all services
su - zimbra -c "zmcontrol stop"

# Restart all services
su - zimbra -c "zmcontrol restart"

# Restart specific service
su - zimbra -c "zmmailboxdctl restart"
```

### User Management

```bash
# Create user
su - zimbra -c "zmprov ca user@maybax.de 'password' displayName 'User Name'"

# Delete user
su - zimbra -c "zmprov da user@maybax.de"

# Change password
su - zimbra -c "zmprov sp user@maybax.de 'newpassword'"

# List all users
su - zimbra -c "zmprov -l gaa"
```

### Mail Queue

```bash
# View queue
mailq

# Flush queue
postqueue -f

# Delete specific message
postsuper -d QUEUE_ID
```

### Logs

```bash
# Mailbox log
tail -f /opt/zimbra/log/mailbox.log

# MTA log
tail -f /var/log/zimbra.log

# Authentication failures
grep "authentication failed" /opt/zimbra/log/mailbox.log
```

### Backup & Restore

```bash
# Manual full backup
su - zimbra -c "/opt/zimbra/bin/zmbackup -f -a all -t full"

# List backups
su - zimbra -c "/opt/zimbra/bin/zmbackup query"

# Restore account
su - zimbra -c "/opt/zimbra/bin/zmrestore -a user@maybax.de -pre restore"
```

## 📊 Monitoring

### Check Disk Usage
```bash
df -h
du -sh /opt/zimbra/*
```

### Check Memory Usage
```bash
free -h
su - zimbra -c "zmlocalconfig -s | grep memory"
```

### Check Active Connections
```bash
netstat -an | grep ESTABLISHED | wc -l
```

### Performance Stats
```bash
su - zimbra -c "zmstats"
```

## 🔍 Troubleshooting Quick Fixes

### Services Won't Start
```bash
# Check for port conflicts
netstat -tulpn | grep -E ':(25|80|443|993|7071)'

# Check logs
tail -100 /opt/zimbra/log/mailbox.log

# Restart with verbose output
su - zimbra -c "zmcontrol start -v"
```

### Can't Login to Admin Console
```bash
# Reset admin password
su - zimbra -c "zmprov sp admin@maybax.de 'NewPassword123!'"

# Check proxy is running
su - zimbra -c "zmproxyctl status"
```

### Emails Not Sending
```bash
# Check MTA status
su - zimbra -c "zmcontrol status mta"

# Check mail queue
mailq

# Test SMTP locally
telnet localhost 25
```

### High Memory Usage
```bash
# Reduce mailbox memory
su - zimbra -c "zmlocalconfig -e mailboxd_java_heap_size=1024"
su - zimbra -c "zmmailboxdctl restart"
```

## 📞 Getting Help

- **Documentation**: https://wiki.zimbra.com/
- **Forums**: https://forums.zimbra.org/
- **Logs**: `/var/log/zimbra-install.log` and `/opt/zimbra/log/`

## ⚡ Performance Tuning Tips

For systems with 8GB+ RAM:
```bash
su - zimbra -c "zmlocalconfig -e mailboxd_java_heap_size=2048"
su - zimbra -c "zmlocalconfig -e zimbra_mysql_memory_percent=40"
su - zimbra -c "zmcontrol restart"
```

For high-traffic servers:
```bash
su - zimbra -c "zmprov mcf zimbraHttpNumThreads 250"
su - zimbra -c "zmprov mcf zimbraScheduledTaskNumThreads 100"
```

---

**Remember**: Always test changes in a development environment first!
