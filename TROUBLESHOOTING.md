# Zimbra Troubleshooting Guide

## 🔧 Common Issues and Solutions

### Installation Issues

#### Issue: Installation fails with "Insufficient memory"

**Solution:**
```bash
# Add swap space
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify
free -h
```

#### Issue: "Hostname not properly configured"

**Solution:**
```bash
# Set FQDN
sudo hostnamectl set-hostname mail.example.com

# Update /etc/hosts
sudo nano /etc/hosts
# Add line: 192.168.1.100 mail.example.com mail

# Verify
hostname -f  # Should return mail.example.com
```

#### Issue: DNS resolution fails

**Solution:**
```bash
# Test DNS
nslookup mail.example.com

# If fails, add to /etc/hosts temporarily
echo "192.168.1.100 mail.example.com mail" | sudo tee -a /etc/hosts

# Or use Google DNS temporarily
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

#### Issue: Port conflicts (Port already in use)

**Solution:**
```bash
# Find what's using the port
sudo netstat -tulpn | grep :25
sudo netstat -tulpn | grep :80

# Stop conflicting services
sudo systemctl stop postfix
sudo systemctl stop apache2
sudo systemctl disable postfix
sudo systemctl disable apache2
```

---

### Service Issues

#### Issue: Zimbra services won't start

**Solution:**
```bash
# Check service status
su - zimbra -c "zmcontrol status"

# Check for errors
tail -100 /opt/zimbra/log/mailbox.log

# Try starting individual services
su - zimbra -c "zmldapctl start"
su - zimbra -c "zmmailboxdctl start"
su - zimbra -c "zmmtactl start"

# If all else fails
su - zimbra -c "zmcontrol restart"
```

#### Issue: Mailbox service crashes frequently

**Solution:**
```bash
# Check Java heap size
su - zimbra -c "zmlocalconfig mailboxd_java_heap_size"

# Increase if needed (for systems with 8GB+ RAM)
su - zimbra -c "zmlocalconfig -e mailboxd_java_heap_size=2048"

# Restart mailbox
su - zimbra -c "zmmailboxdctl restart"

# Monitor memory
free -h
```

#### Issue: MTA (Mail Transfer Agent) not running

**Solution:**
```bash
# Check MTA status
su - zimbra -c "zmmtactl status"

# Check for config errors
su - zimbra -c "postfix check"

# View MTA logs
tail -50 /var/log/mail.log

# Restart MTA
su - zimbra -c "zmmtactl restart"
```

---

### Email Problems

#### Issue: Emails not being received

**Checklist:**
```bash
# 1. Check MTA is running
su - zimbra -c "zmcontrol status mta"

# 2. Test port 25 is open
telnet mail.example.com 25

# 3. Check firewall
sudo ufw status | grep 25

# 4. Check DNS MX record
nslookup -query=mx example.com

# 5. Check mail queue
mailq

# 6. Test local delivery
echo "Test" | mail -s "Test" admin@example.com

# 7. Check logs
tail -f /var/log/mail.log
grep "example.com" /var/log/mail.log
```

#### Issue: Emails not being sent

**Solution:**
```bash
# Check mail queue
mailq

# View specific message
postcat -q QUEUE_ID

# Flush queue
postqueue -f

# Check relay restrictions
su - zimbra -c "postconf | grep relay"

# Check for blacklisting
# Visit: https://mxtoolbox.com/blacklists.aspx
```

#### Issue: Emails going to spam

**Solution:**
```bash
# 1. Configure SPF record in DNS
# example.com. IN TXT "v=spf1 mx ~all"

# 2. Enable and configure DKIM
su - zimbra -c "zmprov md example.com zimbraDKIMSelector default"
su - zimbra -c "/opt/zimbra/libexec/zmdkimkeyutil -a -d example.com"

# 3. Get DKIM public key for DNS
su - zimbra -c "zmprov gd example.com zimbraDKIMPublicKey"

# 4. Add DKIM TXT record to DNS
# default._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=YOUR_PUBLIC_KEY"

# 5. Configure DMARC
# _dmarc.example.com. IN TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"

# 6. Configure reverse DNS (PTR record)
# Contact your hosting provider
```

#### Issue: Large mail queue (hundreds of messages stuck)

**Solution:**
```bash
# View queue
mailq

# Count messages
mailq | tail -1

# Delete all messages (use with caution!)
sudo postsuper -d ALL

# Delete deferred messages only
sudo postsuper -d ALL deferred

# Delete specific message
sudo postsuper -d QUEUE_ID

# Force retry
postqueue -f
```

---

### Login Issues

#### Issue: Can't login to Admin Console

**Solution:**
```bash
# 1. Reset admin password
su - zimbra -c "zmprov sp admin@example.com 'NewPassword123!'"

# 2. Check proxy service
su - zimbra -c "zmproxyctl status"

# 3. Restart proxy
su - zimbra -c "zmproxyctl restart"

# 4. Check firewall
sudo ufw status | grep 7071

# 5. Try accessing via IP
# https://192.168.1.100:7071
```

#### Issue: "Too many login attempts" error

**Solution:**
```bash
# Check lockout settings
su - zimbra -c "zmprov gd example.com | grep -i lockout"

# Unlock specific account
su - zimbra -c "zmprov ma user@example.com zimbraPasswordLockoutEnabled FALSE"

# Or wait for lockout duration to expire
# Default is 1 hour
```

#### Issue: Users can't login to webmail

**Solution:**
```bash
# 1. Check webmail service
su - zimbra -c "zmcontrol status mailbox"

# 2. Check LDAP
su - zimbra -c "zmcontrol status ldap"

# 3. Check user exists
su - zimbra -c "zmprov ga user@example.com"

# 4. Reset user password
su - zimbra -c "zmprov sp user@example.com 'newpassword'"

# 5. Check logs
tail -f /opt/zimbra/log/mailbox.log | grep authentication
```

---

### Performance Issues

#### Issue: Zimbra is slow/unresponsive

**Diagnosis:**
```bash
# Check CPU usage
top
htop  # if installed

# Check memory
free -h
su - zimbra -c "zmlocalconfig -s | grep memory"

# Check disk I/O
iostat -x 1 5

# Check disk space
df -h
du -sh /opt/zimbra/*

# Check number of connections
netstat -an | grep ESTABLISHED | wc -l

# Check database
su - zimbra -c "mysql -e 'SHOW PROCESSLIST;'"
```

**Solutions:**
```bash
# Increase Java heap (if you have RAM)
su - zimbra -c "zmlocalconfig -e mailboxd_java_heap_size=2048"

# Increase MySQL memory
su - zimbra -c "zmlocalconfig -e zimbra_mysql_memory_percent=40"

# Clear old logs
find /opt/zimbra/log -name "*.log.*" -mtime +30 -delete

# Vacuum database
su - zimbra -c "mysql -e 'OPTIMIZE TABLE zimbra.mail_item;'"

# Restart services
su - zimbra -c "zmcontrol restart"
```

#### Issue: Disk space running out

**Solution:**
```bash
# Find large files
du -sh /opt/zimbra/* | sort -h
find /opt/zimbra -type f -size +100M

# Clean old logs
find /opt/zimbra/log -name "*.log.*" -mtime +30 -delete
find /opt/zimbra/log -name "*.gz" -mtime +30 -delete

# Clean backup files (if not needed)
du -sh /opt/zimbra/backup/*
# Carefully review before deleting

# Clean Amavis quarantine
find /opt/zimbra/data/amavisd/quarantine -mtime +30 -delete

# Expand disk or add new volume
```

---

### SSL Certificate Issues

#### Issue: SSL certificate expired

**Solution:**
```bash
# For Let's Encrypt
certbot renew
su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm /etc/letsencrypt/live/mail.example.com/cert.pem /etc/letsencrypt/live/mail.example.com/chain.pem"
su - zimbra -c "zmcontrol restart"

# Check certificate expiry
su - zimbra -c "/opt/zimbra/bin/zmcertmgr viewdeployedcrt"
```

#### Issue: Certificate mismatch warning

**Solution:**
```bash
# Verify certificate details
su - zimbra -c "/opt/zimbra/bin/zmcertmgr viewdeployedcrt"

# Ensure certificate CN matches hostname
# Redeploy correct certificate if needed
```

---

### Database Issues

#### Issue: MySQL won't start

**Solution:**
```bash
# Check MySQL status
su - zimbra -c "zmcontrol status mysql"

# Check MySQL error log
tail -100 /opt/zimbra/log/mysql.err

# Try manual start
su - zimbra -c "mysql.server start"

# Check for corrupt tables
su - zimbra -c "mysqlcheck -r zimbra"

# If InnoDB corruption
# Backup first, then:
su - zimbra -c "mysql -e 'SET GLOBAL innodb_force_recovery=1;'"
```

#### Issue: LDAP won't start

**Solution:**
```bash
# Check LDAP status
su - zimbra -c "zmcontrol status ldap"

# Check LDAP log
tail -100 /opt/zimbra/log/zimbra.log

# Verify LDAP database
su - zimbra -c "ldapsearch -x -H ldapi:/// -D 'uid=zimbra,cn=admins,cn=zimbra' -w \$(zmlocalconfig -s -m nokey zimbra_ldap_password | awk '{print $3}')"

# Restart LDAP
su - zimbra -c "ldap stop"
su - zimbra -c "ldap start"
```

---

### Backup & Restore Issues

#### Issue: Backup fails

**Solution:**
```bash
# Check disk space
df -h /opt/zimbra/backup

# Check backup directory permissions
ls -la /opt/zimbra/backup
su - zimbra -c "ls -la /opt/zimbra/backup"

# Try manual backup
su - zimbra -c "/opt/zimbra/bin/zmbackup -f -a all -t full"

# Check logs
tail -f /opt/zimbra/log/zmbackup.log
```

#### Issue: Restore fails

**Solution:**
```bash
# List available backups
su - zimbra -c "/opt/zimbra/bin/zmbackup query"

# Restore to different account first (test)
su - zimbra -c "/opt/zimbra/bin/zmrestore -a user@example.com -pre test_"

# Check restore logs
tail -f /opt/zimbra/log/zmrestore.log
```

---

### Security Issues

#### Issue: Account keeps getting locked out

**Solution:**
```bash
# Check fail2ban
sudo fail2ban-client status zimbra

# View banned IPs
sudo fail2ban-client get zimbra banned

# Unban IP
sudo fail2ban-client set zimbra unbanip 192.168.1.100

# Adjust lockout settings
su - zimbra -c "zmprov md example.com zimbraPasswordLockoutMaxFailures 10"
```

#### Issue: Spam not being filtered

**Solution:**
```bash
# Update SpamAssassin rules
su - zimbra -c "sa-update"
su - zimbra -c "zmmtactl restart"

# Check spam settings
su - zimbra -c "zmprov gcf | grep -i spam"

# Train spam filter
su - zimbra -c "sa-learn --spam /path/to/spam/folder"
su - zimbra -c "sa-learn --ham /path/to/ham/folder"

# Adjust spam threshold
su - zimbra -c "zmprov mcf zimbraSpamKillPercent 75"
```

#### Issue: Virus scanning not working

**Solution:**
```bash
# Check ClamAV status
su - zimbra -c "/opt/zimbra/libexec/zmclamavcctl status"

# Update virus definitions
su - zimbra -c "/opt/zimbra/libexec/zmfreshclamctl restart"

# Manual database update
su - zimbra -c "freshclam"

# Restart antivirus
su - zimbra -c "/opt/zimbra/libexec/zmclamavcctl restart"
```

---

### Upgrade Issues

#### Issue: Upgrade fails

**Solution:**
```bash
# 1. Always backup first!
su - zimbra -c "/opt/zimbra/bin/zmbackup -f -a all -t full"

# 2. Check current version
su - zimbra -c "/opt/zimbra/bin/zmcontrol -v"

# 3. Review upgrade logs
tail -100 /tmp/install.log*

# 4. If upgrade partially completed
cd /tmp/zcs-*
./install.sh --skip-activation-check

# 5. If upgrade completely failed
# Restore from backup or reinstall previous version
```

---

## 🔍 General Debugging Commands

### View all service statuses
```bash
su - zimbra -c "zmcontrol status"
```

### Check system resources
```bash
# CPU and Memory
top
htop

# Disk
df -h
iostat

# Network
netstat -tulpn
ss -tulpn
```

### Search logs for errors
```bash
# Mailbox errors
grep -i error /opt/zimbra/log/mailbox.log | tail -50

# Authentication failures
grep "authentication failed" /opt/zimbra/log/mailbox.log | tail -20

# Today's errors
grep -i error /opt/zimbra/log/mailbox.log | grep "$(date +%Y-%m-%d)"
```

### Test email flow
```bash
# SMTP test
telnet localhost 25
# Then type:
EHLO localhost
MAIL FROM: test@example.com
RCPT TO: admin@example.com
DATA
Subject: Test
Test message
.
QUIT
```

---

## 📞 When All Else Fails

1. **Restart Zimbra**
   ```bash
   su - zimbra -c "zmcontrol restart"
   ```

2. **Reboot server**
   ```bash
   sudo reboot
   ```

3. **Check official documentation**
   - https://wiki.zimbra.com/

4. **Search forums**
   - https://forums.zimbra.org/

5. **Review logs**
   ```bash
   /opt/zimbra/log/mailbox.log
   /var/log/mail.log
   /var/log/zimbra.log
   ```

6. **Contact support**
   - Professional support: https://www.zimbra.com/support/

---

**Pro Tip**: Before making any major changes, always:
1. Take a backup
2. Document current state
3. Test in development first
4. Have a rollback plan
