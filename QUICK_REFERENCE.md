# Quick Reference Card - oregonstate.de Zimbra Setup

## 📋 Your Server Details

```
Domain:           oregonstate.de
Mail Server:      mail.oregonstate.de
IP Address:       173.249.1.171
Registrar:        Spaceship.com
Admin Email:      admin@oregonstate.de
```

---

## 🚀 Installation Steps (Quick Version)

### 1. DNS Configuration (Do First!)
Login to Spaceship.com → DNS Settings → Add these records:

| Type | Host | Value | Priority |
|------|------|-------|----------|
| A | mail | 173.249.1.171 | - |
| MX | @ | mail.oregonstate.de | 10 |
| TXT | @ | v=spf1 mx ip4:173.249.1.171 ~all | - |
| TXT | _dmarc | v=DMARC1; p=quarantine; rua=mailto:dmarc@oregonstate.de | - |

**CRITICAL**: Contact your server host to set PTR record: `173.249.1.171 → mail.oregonstate.de`

### 2. Server Commands (Run in Order)

```bash
# SSH to server
ssh root@173.249.1.171

# Clone repository
git clone https://github.com/EmekaIwuagwu/zimbra-setup.git
cd zimbra-setup
chmod +x *.sh

# Setup server hostname
sudo ./setup-server.sh

# Verify DNS (wait 1-4 hours after DNS changes)
./verify-dns.sh

# System check
sudo ./pre-install-check.sh

# Install Zimbra (15-30 min)
sudo ./install-zimbra.sh
# Enter: mail.oregonstate.de
# Enter: oregonstate.de
# Enter: strong password

# Get DKIM key and add to DNS
su - zimbra -c "zmprov gd oregonstate.de zimbraDKIMPublicKey"
# Copy key, add TXT record at default._domainkey

# Security hardening
sudo ./post-install-hardening.sh

# SSL certificate
sudo apt-get install -y certbot
su - zimbra -c "zmproxyctl stop"
sudo certbot certonly --standalone -d mail.oregonstate.de
su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm /etc/letsencrypt/live/mail.oregonstate.de/cert.pem /etc/letsencrypt/live/mail.oregonstate.de/chain.pem"
su - zimbra -c "zmcontrol restart"
```

---

## 🔗 Access URLs

**Admin Console**: https://mail.oregonstate.de:7071  
**Webmail**: https://mail.oregonstate.de  
**Username**: admin@oregonstate.de  
**Password**: [what you set during installation]

---

## ⚡ Essential Commands

### Service Management
```bash
# Check status
su - zimbra -c "zmcontrol status"

# Restart all
su - zimbra -c "zmcontrol restart"

# Restart mailbox only
su - zimbra -c "zmmailboxdctl restart"
```

### User Management
```bash
# Create user
su - zimbra -c "zmprov ca user@oregonstate.de 'password' displayName 'User Name'"

# Reset password
su - zimbra -c "zmprov sp user@oregonstate.de 'newpassword'"

# List all users
su - zimbra -c "zmprov -l gaa"
```

### Mail Queue
```bash
# View queue
mailq

# Flush queue
postqueue -f

# Delete all queued mail
postsuper -d ALL
```

### Logs
```bash
# Watch mailbox log
tail -f /opt/zimbra/log/mailbox.log

# Check for errors
grep -i error /opt/zimbra/log/mailbox.log | tail -20

# Authentication failures
grep "authentication failed" /opt/zimbra/log/mailbox.log
```

### Backup
```bash
# Manual backup
/opt/zimbra/bin/zimbra-backup.sh

# Check backups
ls -lh /opt/zimbra/backup/

# Restore account
su - zimbra -c "/opt/zimbra/bin/zmrestore -a user@oregonstate.de"
```

---

## 🔍 Verification Tests

### DNS Verification
```bash
# A record
nslookup mail.oregonstate.de
# Should return: 173.249.1.171

# MX record
nslookup -query=mx oregonstate.de
# Should return: mail.oregonstate.de

# PTR record
nslookup 173.249.1.171
# Should return: mail.oregonstate.de

# SPF record
dig txt oregonstate.de
# Should show: v=spf1 mx ip4:173.249.1.171 ~all

# Run verification script
./verify-dns.sh
```

### Email Deliverability Test
```bash
# Send test to Port25 verifier
echo "Test" | mail -s "Test" check-auth@verifier.port25.com

# Check MXToolbox
# Visit: https://mxtoolbox.com/emailhealth/
# Enter: oregonstate.de
```

### Service Test
```bash
# SMTP test
telnet mail.oregonstate.de 25

# IMAP test
telnet mail.oregonstate.de 143

# HTTPS test
curl -I https://mail.oregonstate.de
```

---

## 📧 Email Client Settings

### IMAP Settings
```
Server:     mail.oregonstate.de
Port:       993
Security:   SSL/TLS
Username:   user@oregonstate.de
Password:   [user password]
```

### SMTP Settings
```
Server:     mail.oregonstate.de
Port:       587
Security:   STARTTLS
Auth:       Required
Username:   user@oregonstate.de
Password:   [user password]
```

---

## 🛡️ Security Features Enabled

✅ Fail2ban (blocks after 5 failed attempts)  
✅ Password policy (min 10 chars, mixed case, numbers, special)  
✅ DKIM signing  
✅ SPF protection  
✅ DMARC policy  
✅ Automated daily backups (2 AM)  
✅ SSL/TLS encryption  
✅ Firewall rules  
✅ SSH hardening  
✅ Auto security updates  

---

## 📞 Quick Troubleshooting

### Can't login to admin console
```bash
# Reset admin password
su - zimbra -c "zmprov sp admin@oregonstate.de 'NewPassword123!'"

# Restart proxy
su - zimbra -c "zmproxyctl restart"
```

### Emails not sending
```bash
# Check MTA
su - zimbra -c "zmcontrol status mta"

# View queue
mailq

# Check logs
tail -50 /var/log/mail.log
```

### Services won't start
```bash
# Check logs
tail -100 /opt/zimbra/log/mailbox.log

# Restart all
su - zimbra -c "zmcontrol restart"

# If still failing
sudo reboot
```

### Low disk space
```bash
# Check space
df -h

# Clean old logs
find /opt/zimbra/log -name "*.log.*" -mtime +30 -delete

# Check backup size
du -sh /opt/zimbra/backup/*
```

---

## 📱 Mobile Device Setup (iOS/Android)

**Account Type**: Exchange  
**Server**: mail.oregonstate.de  
**Domain**: oregonstate.de  
**Username**: user@oregonstate.de  
**Password**: [user password]  
**Use SSL**: Yes  

---

## 🔄 Regular Maintenance

### Daily
- [ ] Check service status: `su - zimbra -c "zmcontrol status"`
- [ ] Check mail queue: `mailq`
- [ ] Review disk space: `df -h`

### Weekly
- [ ] Review logs for errors: `grep -i error /opt/zimbra/log/mailbox.log`
- [ ] Check Fail2ban banned IPs: `sudo fail2ban-client status zimbra`
- [ ] Verify backups exist: `ls -lh /opt/zimbra/backup/`

### Monthly
- [ ] Update system: `sudo apt update && sudo apt upgrade`
- [ ] Test backup restore procedure
- [ ] Review user accounts
- [ ] Check SSL certificate expiry
- [ ] Review security logs

---

## 📁 Important File Locations

```
Configuration:  /opt/zimbra/
Logs:          /opt/zimbra/log/
Backups:          /opt/zimbra/backup/
SSL Certs:     /etc/letsencrypt/live/mail.oregonstate.de/
Install Logs:  /var/log/zimbra-install.log
```

---

## 🆘 Emergency Contacts

**Spaceship.com Support**: https://www.spaceship.com/support  
**Server Host**: [Your hosting provider]  
**Zimbra Forums**: https://forums.zimbra.org/  
**Zimbra Docs**: https://wiki.zimbra.com/  

---

## 📖 Documentation Files

- `README.md` - Complete documentation
- `QUICK_START.md` - Quick start guide
- `DNS_SETUP_GUIDE.md` - Detailed DNS setup for Spaceship.com
- `INSTALLATION_CHECKLIST.md` - Step-by-step checklist
- `TROUBLESHOOTING.md` - Common issues and solutions
- `zimbra-config.conf` - Your configuration file

---

## ⚡ One-Liner Commands

```bash
# Complete status check
su - zimbra -c "zmcontrol status" && df -h && free -h && mailq

# View all recent errors
grep -i error /opt/zimbra/log/mailbox.log | grep "$(date +%Y-%m-%d)"

# Backup NOW
/opt/zimbra/bin/zimbra-backup.sh

# Full service restart
su - zimbra -c "zmcontrol restart" && sleep 30 && su - zimbra -c "zmcontrol status"
```

---

**Setup Date**: _______________  
**Admin Password**: [stored in password manager]  
**Backup Location**: /opt/zimbra/backup/  
**Last Updated**: _______________

---

**Keep this reference card handy!** 📌
