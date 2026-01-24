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
- Hostname (e.g., mail.example.com)
- Domain (e.g., example.com)
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
URL: https://your-hostname:7071
Username: admin@your-domain
Password: [the password you set]
```

**Webmail:**
```
URL: https://your-hostname
Username: admin@your-domain
Password: [the password you set]
```

## 📋 Complete Installation Workflow

```bash
# 1. Download or clone the scripts
git clone <your-repo-url>
cd zimbra

# 2. Make all scripts executable
chmod +x *.sh

# 3. Run pre-installation check
sudo ./pre-install-check.sh

# 4. Fix any issues identified in step 3

# 5. Run installation
sudo ./install-zimbra.sh

# 6. Wait for installation to complete (15-30 minutes)

# 7. Apply security hardening
sudo ./post-install-hardening.sh

# 8. Access admin console and configure
# https://your-hostname:7071

# 9. Configure DNS records (see DNS Configuration below)

# 10. Install SSL certificate (see SSL Configuration below)
```

## 🔧 Common Configuration Tasks

### DNS Configuration

Add these DNS records at your domain registrar:

```dns
# A Record
mail.example.com.       IN  A       192.168.1.100

# MX Record
example.com.            IN  MX  10  mail.example.com.

# TXT Record for SPF
example.com.            IN  TXT     "v=spf1 mx ~all"

# DKIM Record (get from Zimbra after installation)
default._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=YOUR_PUBLIC_KEY"

# DMARC Record
_dmarc.example.com.     IN  TXT     "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"

# PTR Record (configure at your hosting provider)
100.1.168.192.in-addr.arpa. IN PTR  mail.example.com.
```

### Get DKIM Public Key

```bash
su - zimbra -c "zmprov gd example.com zimbraDomainDKIMSelector"
su - zimbra -c "zmprov gd example.com zimbraDKIMPublicKey"
```

### SSL Certificate Installation

#### Using Let's Encrypt (Free)

```bash
# Install certbot
apt-get install -y certbot

# Stop Zimbra proxy temporarily
su - zimbra -c "zmproxyctl stop"

# Get certificate
certbot certonly --standalone -d mail.example.com

# Deploy certificate
su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm /etc/letsencrypt/live/mail.example.com/cert.pem /etc/letsencrypt/live/mail.example.com/chain.pem"

# Restart Zimbra
su - zimbra -c "zmcontrol restart"

# Auto-renewal
echo "0 3 * * * certbot renew --quiet && su - zimbra -c 'zmcertmgr deploycrt comm /etc/letsencrypt/live/mail.example.com/cert.pem /etc/letsencrypt/live/mail.example.com/chain.pem' && su - zimbra -c 'zmcontrol restart'" | crontab -
```

#### Using Commercial Certificate

```bash
# 1. Generate CSR
su - zimbra -c "/opt/zimbra/bin/zmcertmgr createcsr comm -new -subject '/C=US/ST=State/L=City/O=Organization/CN=mail.example.com'"

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
su - zimbra -c "zmprov ca user@example.com 'password' displayName 'User Name'"

# Delete user
su - zimbra -c "zmprov da user@example.com"

# Change password
su - zimbra -c "zmprov sp user@example.com 'newpassword'"

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
su - zimbra -c "/opt/zimbra/bin/zmrestore -a user@example.com -pre restore"
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
su - zimbra -c "zmprov sp admin@example.com 'NewPassword123!'"

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
