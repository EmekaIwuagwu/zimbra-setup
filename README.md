# Zimbra Collaboration Suite - Automated Installation

This repository contains a comprehensive shell script for automating the installation and configuration of Zimbra Collaboration Suite on Ubuntu Linux.

## 📋 Table of Contents

- [Overview](#overview)
- [System Requirements](#system-requirements)
- [Pre-Installation Checklist](#pre-installation-checklist)
- [Installation](#installation)
- [Post-Installation](#post-installation)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

## 🎯 Overview

The `install-zimbra.sh` script automates the complete setup process for Zimbra Collaboration Suite, including:

- ✅ System requirements validation
- ✅ Dependency installation
- ✅ Hostname and DNS configuration
- ✅ Firewall configuration
- ✅ Zimbra download and installation
- ✅ Post-installation configuration
- ✅ Service verification

## 💻 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04 LTS or Ubuntu 22.04 LTS
- **RAM**: 4GB (8GB+ recommended for production)
- **Disk Space**: 10GB free minimum (50GB+ recommended)
- **CPU**: 2 cores minimum (4+ recommended)
- **Network**: Static IP address
- **Access**: Root/sudo privileges

### Supported Ubuntu Versions
- Ubuntu 20.04 LTS ✅
- Ubuntu 22.04 LTS ✅
- Ubuntu 18.04 LTS ⚠️ (may work but not officially supported)

## 📝 Pre-Installation Checklist

Before running the installation script, ensure:

### 1. DNS Configuration
Ensure proper DNS records are configured:

```bash
# A Record
mail.example.com    IN  A   192.168.1.100

# MX Record
example.com         IN  MX  10 mail.example.com

# PTR Record (Reverse DNS)
100.1.168.192.in-addr.arpa  IN  PTR  mail.example.com
```

Verify DNS resolution:
```bash
# Check forward lookup
nslookup mail.example.com

# Check reverse lookup
nslookup 192.168.1.100

# Check MX record
nslookup -query=mx example.com
```

### 2. Network Configuration
- Configure a static IP address
- Ensure the server can access the internet
- Open required ports (see [Firewall Rules](#firewall-rules))

### 3. System Updates
```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo reboot  # Reboot if kernel was updated
```

## 🚀 Installation

### Step 1: Download the Script

```bash
# Clone this repository or download the script
git clone <repository-url>
cd zimbra

# OR download directly
wget https://raw.githubusercontent.com/<your-repo>/install-zimbra.sh
```

### Step 2: Make the Script Executable

```bash
chmod +x install-zimbra.sh
```

### Step 3: Run the Installation

```bash
sudo ./install-zimbra.sh
```

### Step 4: Follow the Prompts

The script will ask for:
1. **Zimbra server hostname** (e.g., mail.example.com)
2. **Domain name** (e.g., example.com)
3. **Admin password** (minimum 8 characters)

### Installation Time
- Typical installation: 15-30 minutes
- Download time varies based on internet speed

## 🔧 Post-Installation

### Access Zimbra Admin Console

```
URL: https://mail.example.com:7071
Username: admin@example.com
Password: [password you set during installation]
```

### Access Webmail

```
URL: https://mail.example.com
Username: admin@example.com
Password: [password you set during installation]
```

### Essential Post-Installation Tasks

#### 1. Configure SSL Certificates

For production environments, install a commercial SSL certificate:

```bash
# Switch to zimbra user
su - zimbra

# Generate CSR
/opt/zimbra/bin/zmcertmgr createcsr comm -new -subject "/C=US/ST=State/L=City/O=Organization/CN=mail.example.com"

# After obtaining certificate from CA
/opt/zimbra/bin/zmcertmgr deploycrt comm /path/to/commercial.crt /path/to/commercial_ca.crt

# Restart services
zmcontrol restart
```

#### 2. Configure Spam and Antivirus

```bash
su - zimbra

# Update spam rules
/opt/zimbra/bin/zmprov mcf zimbraSpamKillPercent 75

# Enable ClamAV updates
/opt/zimbra/libexec/zmclamdctl restart
```

#### 3. Set Up Backup

Create a backup script:

```bash
#!/bin/bash
# /opt/zimbra/backup.sh

BACKUP_DIR="/opt/zimbra/backup"
DATE=$(date +%Y%m%d)

mkdir -p $BACKUP_DIR

# Full backup
/opt/zimbra/bin/zmbackup -f -a all -t full -z

# Move backup to archive location
mv /opt/zimbra/backup/sessions/* $BACKUP_DIR/$DATE/
```

Add to crontab:
```bash
# Daily backup at 2 AM
0 2 * * * /opt/zimbra/backup.sh
```

#### 4. Monitor Zimbra Services

```bash
# Check all services
su - zimbra -c 'zmcontrol status'

# Check specific service
su - zimbra -c 'zmcontrol status mailbox'

# Restart all services
su - zimbra -c 'zmcontrol restart'

# View logs
tail -f /opt/zimbra/log/mailbox.log
```

## 🛡️ Firewall Rules

The script automatically configures UFW firewall (if installed). Required ports:

| Port | Protocol | Service | Description |
|------|----------|---------|-------------|
| 25 | TCP | SMTP | Mail Transfer |
| 80 | TCP | HTTP | Web Access (redirects to HTTPS) |
| 110 | TCP | POP3 | Mail Retrieval |
| 143 | TCP | IMAP | Mail Access |
| 443 | TCP | HTTPS | Secure Web Access |
| 465 | TCP | SMTPS | Secure SMTP |
| 587 | TCP | Submission | Mail Submission |
| 993 | TCP | IMAPS | Secure IMAP |
| 995 | TCP | POP3S | Secure POP3 |
| 7071 | TCP | Admin Console | Zimbra Admin (HTTP) |
| 8443 | TCP | Admin Console | Zimbra Admin (HTTPS) |

Manual firewall configuration (if needed):
```bash
# For UFW
sudo ufw allow 25/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 587/tcp
sudo ufw allow 993/tcp
sudo ufw allow 7071/tcp
sudo ufw allow 8443/tcp

# For iptables
sudo iptables -A INPUT -p tcp --dport 25 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
# ... add other ports
```

## 🔍 Troubleshooting

### Installation Fails

**Check the log file:**
```bash
tail -f /var/log/zimbra-install.log
```

**Common issues:**

1. **Insufficient Memory**
   ```bash
   # Check memory
   free -h
   
   # Add swap if needed
   sudo fallocate -l 4G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

2. **Hostname Issues**
   ```bash
   # Verify hostname
   hostname -f
   
   # Should return FQDN (e.g., mail.example.com)
   
   # If not, manually set:
   sudo hostnamectl set-hostname mail.example.com
   
   # Update /etc/hosts
   sudo nano /etc/hosts
   # Add: 192.168.1.100 mail.example.com mail
   ```

3. **DNS Resolution Problems**
   ```bash
   # Test DNS
   nslookup mail.example.com
   
   # Temporarily use Google DNS
   echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
   ```

### Services Won't Start

```bash
# Check service status
su - zimbra -c 'zmcontrol status'

# Check specific service logs
tail -f /opt/zimbra/log/mailbox.log

# Restart services
su - zimbra -c 'zmcontrol restart'

# Check for port conflicts
sudo netstat -tulpn | grep -E ':(25|80|443|993)'
```

### Can't Access Admin Console

1. **Verify services are running:**
   ```bash
   su - zimbra -c 'zmcontrol status'
   ```

2. **Check firewall:**
   ```bash
   sudo ufw status
   ```

3. **Verify proxy settings:**
   ```bash
   su - zimbra -c 'zmprov gs `zmhostname` zimbraReverseProxyHttpEnabled'
   ```

### Email Not Sending/Receiving

1. **Check MTA status:**
   ```bash
   su - zimbra -c 'zmcontrol status mta'
   ```

2. **Check mail queue:**
   ```bash
   su - zimbra -c 'zmcontrol -v'
   postqueue -p
   ```

3. **Test email locally:**
   ```bash
   echo "Test email" | mail -s "Test" admin@example.com
   ```

## 🔐 Security Considerations

### Essential Security Steps

1. **Change Default Passwords**
   ```bash
   su - zimbra
   zmprov sp admin@example.com 'NewStrongPassword123!'
   ```

2. **Enable Fail2ban**
   ```bash
   sudo apt-get install fail2ban
   
   # Create Zimbra jail
   sudo nano /etc/fail2ban/jail.local
   ```
   
   Add:
   ```ini
   [zimbra]
   enabled = true
   port = smtp,ssmtp,imap,imaps,pop3,pop3s
   filter = zimbra
   logpath = /opt/zimbra/log/mailbox.log
   maxretry = 5
   bantime = 3600
   ```

3. **Regular Updates**
   ```bash
   # System updates
   sudo apt-get update && sudo apt-get upgrade
   
   # Check Zimbra updates
   su - zimbra -c '/opt/zimbra/bin/zmcontrol -v'
   ```

4. **Enable Two-Factor Authentication**
   - Configure via Admin Console
   - Settings → Domains → [Your Domain] → General → Two-Factor Authentication

5. **Restrict Admin Console Access**
   ```bash
   # Allow only specific IPs
   sudo ufw allow from 192.168.1.0/24 to any port 7071
   sudo ufw allow from 192.168.1.0/24 to any port 8443
   ```

6. **Regular Backups**
   - Implement automated daily backups
   - Test restore procedures regularly
   - Store backups offsite

## 📊 Maintenance Commands

### Daily Checks
```bash
# Service status
su - zimbra -c 'zmcontrol status'

# Disk usage
df -h

# Mail queue
postqueue -p

# Recent errors
grep ERROR /opt/zimbra/log/mailbox.log | tail -20
```

### Performance Tuning
```bash
# Adjust Java heap size (for 8GB+ RAM)
su - zimbra
zmlocalconfig -e mailboxd_java_heap_size=2048

# Restart mailbox
zmmailboxdctl restart
```

## 📞 Support Resources

- **Official Documentation**: https://wiki.zimbra.com/
- **Community Forums**: https://forums.zimbra.org/
- **Bug Tracker**: https://bugzilla.zimbra.com/
- **Professional Support**: https://www.zimbra.com/support/

## 📄 License

This installation script is provided as-is for educational and production use.

## ⚠️ Disclaimer

Always test in a development environment before deploying to production. Make sure you have proper backups before making any changes to a production Zimbra server.

---

**Script Version**: 1.0.0  
**Last Updated**: 2026-01-24  
**Maintained By**: Senior IT Administrator Team
