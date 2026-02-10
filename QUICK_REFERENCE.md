# Quick Reference Card - maybax.de Zimbra Setup

## 📋 Your Server Details

```
Domain:           maybax.de
Mail Server:      mail.maybax.de
IP Address:       173.249.1.171
Registrar:        Spaceship.com
Admin Email:      admin@maybax.de
```

---

## 🚀 Installation Steps (Quick Version)

### 1. DNS Configuration (Do First!)
Login to Spaceship.com → DNS Settings → Add these records:

| Type | Host | Value | Priority |
|------|------|-------|----------|
| A | mail | 173.249.1.171 | - |
| MX | @ | mail.maybax.de | 10 |
| TXT | @ | v=spf1 mx ip4:173.249.1.171 ~all | - |
| TXT | _dmarc | v=DMARC1; p=quarantine; rua=mailto:dmarc@maybax.de | - |

**CRITICAL**: Contact your server host to set PTR record: `173.249.1.171 → mail.maybax.de`

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
# Enter: mail.maybax.de
# Enter: maybax.de
# Enter: strong password

# Get DKIM key and add to DNS
su - zimbra -c "zmprov gd maybax.de zimbraDKIMPublicKey"
# Copy key, add TXT record at default._domainkey

# Security hardening
sudo ./post-install-hardening.sh

# SSL certificate
sudo apt-get install -y certbot
su - zimbra -c "zmproxyctl stop"
sudo certbot certonly --standalone -d mail.maybax.de
su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm /etc/letsencrypt/live/mail.maybax.de/cert.pem /etc/letsencrypt/live/mail.maybax.de/chain.pem"
su - zimbra -c "zmcontrol restart"
```

---

## 🔗 Access URLs

**Admin Console**: https://mail.maybax.de:7071  
**Webmail**: https://mail.maybax.de  
**Username**: admin@maybax.de  
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
su - zimbra -c "zmprov ca user@maybax.de 'password' displayName 'User Name'"

# Reset password
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
su - zimbra -c "/opt/zimbra/bin/zmrestore -a user@maybax.de"
```

---

## 🔍 Verification Tests

### DNS Verification
```bash
# A record
nslookup mail.maybax.de
# Should return: 173.249.1.171

# MX record
nslookup -query=mx maybax.de
# Should return: mail.maybax.de

# PTR record
nslookup 173.249.1.171
# Should return: mail.maybax.de

# SPF record
dig txt maybax.de
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
# Enter: maybax.de
```

### Service Test
```bash
# SMTP test
telnet mail.maybax.de 25

# IMAP test
telnet mail.maybax.de 143

# HTTPS test
curl -I https://mail.maybax.de
```

---

## 📧 Email Client Settings

### IMAP Settings
```
Server:     mail.maybax.de
Port:       993
Security:   SSL/TLS
Username:   user@maybax.de
Password:   [user password]
```

### SMTP Settings
```
Server:     mail.maybax.de
Port:       587
Security:   STARTTLS
Auth:       Required
Username:   user@maybax.de
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
su - zimbra -c "zmprov sp admin@maybax.de 'NewPassword123!'"

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
**Server**: mail.maybax.de  
**Domain**: maybax.de  
**Username**: user@maybax.de  
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
SSL Certs:     /etc/letsencrypt/live/mail.maybax.de/
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
