# Zimbra Setup Checklist for spiffbox.xyz

## Server Information
- **Domain**: spiffbox.xyz
- **Mail Server**: mail.spiffbox.xyz
- **IP Address**: 194.163.142.4
- **Registrar**: Spaceship.com
- **Admin Email**: admin@spiffbox.xyz

---

## 📋 PHASE 1: DNS Configuration (Do This FIRST!)

### At Spaceship.com Dashboard

Login to: https://www.spaceship.com/ → Domains → spiffbox.xyz → DNS Settings

#### Add These DNS Records:

- [ ] **A Record #1**
  - Type: `A`
  - Host: `mail`
  - Value: `194.163.142.4`
  - TTL: `3600`

- [ ] **A Record #2** (Optional - for webmail at root domain)
  - Type: `A`
  - Host: `@` or leave blank
  - Value: `194.163.142.4`
  - TTL: `3600`

- [ ] **MX Record**
  - Type: `MX`
  - Host: `@` or leave blank
  - Value: `mail.spiffbox.xyz`
  - Priority: `10`
  - TTL: `3600`

- [ ] **SPF TXT Record**
  - Type: `TXT`
  - Host: `@` or leave blank
  - Value: `v=spf1 mx ip4:194.163.142.4 ~all`
  - TTL: `3600`

- [ ] **DMARC TXT Record**
  - Type: `TXT`
  - Host: `_dmarc`
  - Value: `v=DMARC1; p=quarantine; rua=mailto:dmarc@spiffbox.xyz`
  - TTL: `3600`

### Contact Your Server Hosting Provider

- [ ] **Request PTR (Reverse DNS) Record**
  - Tell them: "Please set up reverse DNS"
  - IP: `194.163.142.4`
  - Should point to: `mail.spiffbox.xyz`
  - Critical for email deliverability!

### Verify DNS Propagation

- [ ] Wait 1-4 hours after adding records
- [ ] Test A record:
  ```bash
  nslookup mail.spiffbox.xyz
  # Should show: 194.163.142.4
  ```
- [ ] Test MX record:
  ```bash
  nslookup -query=mx spiffbox.xyz
  # Should show: mail.spiffbox.xyz
  ```
- [ ] Use online tool: https://dnschecker.org/ (enter `mail.spiffbox.xyz`)
- [ ] All locations should show `194.163.142.4`

---

## 📋 PHASE 2: Server Access & Preparation

### SSH into Your Server

- [ ] Connect to server:
  ```bash
  ssh root@194.163.142.4
  # Or: ssh youruser@194.163.142.4
  ```

### Update Operating System

- [ ] Update package lists:
  ```bash
  sudo apt update
  ```
- [ ] Upgrade packages:
  ```bash
  sudo apt upgrade -y
  ```
- [ ] Reboot if kernel updated:
  ```bash
  sudo reboot
  ```
- [ ] Reconnect after reboot

### Download Zimbra Setup Scripts

- [ ] Clone repository:
  ```bash
  cd ~
  git clone https://github.com/EmekaIwuagwu/zimbra-setup.git
  ```
- [ ] Enter directory:
  ```bash
  cd zimbra-setup
  ```
- [ ] Make scripts executable:
  ```bash
  chmod +x *.sh
  ```
- [ ] List files to verify:
  ```bash
  ls -lah
  ```

---

## 📋 PHASE 3: Pre-Installation System Check

### Run Pre-Installation Check

- [ ] Execute pre-check script:
  ```bash
  sudo ./pre-install-check.sh
  ```

### Review Results

- [ ] All checks marked as `[PASS]` ✓
- [ ] Address any `[FAIL]` items before proceeding
- [ ] Review `[WARN]` warnings (may be okay)

### Common Issues to Fix

If you see failures, fix them:

- [ ] **Hostname not set**: 
  ```bash
  sudo hostnamectl set-hostname mail.spiffbox.xyz
  ```
- [ ] **Update /etc/hosts**:
  ```bash
  sudo nano /etc/hosts
  # Add line: 194.163.142.4 mail.spiffbox.xyz mail
  ```
- [ ] **Low memory**: Add swap space
  ```bash
  sudo fallocate -l 4G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  ```

---

## 📋 PHASE 4: Zimbra Installation

### Prepare Configuration File (Optional)

- [ ] Edit config file with your password:
  ```bash
  nano zimbra-config.conf
  ```
- [ ] Change line: `ADMIN_PASSWORD="ChangeThisPassword123!"`
- [ ] Set a strong password (at least 12 characters)
- [ ] Save and exit (Ctrl+X, Y, Enter)

### Run Installation

- [ ] Start installation:
  ```bash
  sudo ./install-zimbra.sh
  ```

### Answer Installation Prompts

When prompted, enter:

- [ ] **Hostname**: `mail.spiffbox.xyz`
- [ ] **Domain**: `spiffbox.xyz`
- [ ] **Admin Password**: (choose strong password - write it down!)
- [ ] Confirm password
- [ ] Wait 15-30 minutes for installation

### Installation Complete

- [ ] Installation finished without errors
- [ ] Note the access URLs shown
- [ ] Write down admin password if not already saved

---

## 📋 PHASE 5: Post-Installation - DKIM Setup

### Get DKIM Public Key

- [ ] Switch to zimbra user and get DKIM key:
  ```bash
  su - zimbra -c "zmprov gd spiffbox.xyz zimbraDKIMPublicKey"
  ```
- [ ] Copy the public key (long string starting with `MIGfMA0G...`)

### Add DKIM to Spaceship.com DNS

- [ ] Go back to Spaceship.com DNS settings
- [ ] Add new TXT record:
  - Type: `TXT`
  - Host: `default._domainkey`
  - Value: `v=DKIM1; k=rsa; p=YOUR_COPIED_PUBLIC_KEY`
  - TTL: `3600`
- [ ] Save the record
- [ ] Wait 1 hour for DNS propagation

### Verify DKIM

- [ ] Test DKIM record:
  ```bash
  dig txt default._domainkey.spiffbox.xyz
  ```
- [ ] Should show your DKIM public key

---

## 📋 PHASE 6: Security Hardening

### Run Security Hardening Script

- [ ] Execute hardening script:
  ```bash
  sudo ./post-install-hardening.sh
  ```
- [ ] Wait 5-10 minutes for completion
- [ ] Review security measures applied

### Verify Security Features

- [ ] Check Fail2ban status:
  ```bash
  sudo fail2ban-client status zimbra
  ```
- [ ] Check firewall:
  ```bash
  sudo ufw status
  ```
- [ ] Verify automated backup script exists:
  ```bash
  ls -la /opt/zimbra/bin/zimbra-backup.sh
  ```

---

## 📋 PHASE 7: SSL Certificate (Let's Encrypt)

### Install Certbot

- [ ] Install certbot:
  ```bash
  sudo apt-get install -y certbot
  ```

### Stop Zimbra Proxy

- [ ] Stop proxy service:
  ```bash
  su - zimbra -c "zmproxyctl stop"
  ```

### Obtain SSL Certificate

- [ ] Get Let's Encrypt certificate:
  ```bash
  sudo certbot certonly --standalone -d mail.spiffbox.xyz
  ```
- [ ] Enter email address when prompted
- [ ] Agree to terms
- [ ] Certificate obtained successfully

### Deploy Certificate to Zimbra

- [ ] Deploy SSL certificate:
  ```bash
  su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm /etc/letsencrypt/live/mail.spiffbox.xyz/cert.pem /etc/letsencrypt/live/mail.spiffbox.xyz/chain.pem"
  ```

### Restart Zimbra

- [ ] Restart all services:
  ```bash
  su - zimbra -c "zmcontrol restart"
  ```
- [ ] Wait for services to start
- [ ] Verify all services running:
  ```bash
  su - zimbra -c "zmcontrol status"
  ```

### Setup Auto-Renewal

- [ ] Create renewal cron job:
  ```bash
  sudo crontab -e
  ```
- [ ] Add this line:
  ```
  0 3 * * * certbot renew --quiet && su - zimbra -c '/opt/zimbra/bin/zmcertmgr deploycrt comm /etc/letsencrypt/live/mail.spiffbox.xyz/cert.pem /etc/letsencrypt/live/mail.spiffbox.xyz/chain.pem' && su - zimbra -c 'zmcontrol restart'
  ```
- [ ] Save and exit

---

## 📋 PHASE 8: Final Testing & Verification

### Access Admin Console

- [ ] Open browser to: `https://mail.spiffbox.xyz:7071`
- [ ] Accept security warning (if using self-signed initially)
- [ ] Login with:
  - Username: `admin@spiffbox.xyz`
  - Password: (your admin password)
- [ ] Admin console loads successfully

### Access Webmail

- [ ] Open browser to: `https://mail.spiffbox.xyz`
- [ ] Login with admin credentials
- [ ] Webmail interface loads

### Create Test User

- [ ] In admin console, go to: Manage → Accounts
- [ ] Click "New"
- [ ] Create test user:
  - Email: `test@spiffbox.xyz`
  - Password: (set test password)
- [ ] Save user

### Test Email Sending

- [ ] Login to webmail as test user
- [ ] Compose new email to external address (Gmail/Outlook)
- [ ] Send email
- [ ] Check if email arrives (check spam folder)

### Test Email Receiving

- [ ] Send email FROM external account TO `test@spiffbox.xyz`
- [ ] Check if email arrives in Zimbra webmail
- [ ] Verify email appears in inbox

### Verify DNS Records

- [ ] Test all DNS records with MXToolbox:
  - Go to: https://mxtoolbox.com/SuperTool.aspx
  - Enter: `spiffbox.xyz`
  - Check MX record ✓
  - Check SPF record ✓
  - Check DMARC record ✓

- [ ] Test DKIM:
  - Go to: https://mxtoolbox.com/dkim.aspx
  - Enter: `spiffbox.xyz`
  - Selector: `default`
  - Should show valid DKIM ✓

- [ ] Test reverse DNS:
  ```bash
  dig -x 194.163.142.4
  # Should return: mail.spiffbox.xyz
  ```

### Email Health Check

- [ ] Complete email health test:
  - Go to: https://mxtoolbox.com/emailhealth/
  - Enter: `spiffbox.xyz`
  - Review all results (should be mostly green)

### Test Email Deliverability

- [ ] Send test email to: check-auth@verifier.port25.com
- [ ] Check response email for SPF, DKIM, DMARC results
- [ ] All three should PASS ✓

---

## 📋 PHASE 9: Production Setup

### Create Real User Accounts

- [ ] Create accounts for actual users
- [ ] Set strong passwords
- [ ] Provide credentials to users

### Configure Email Clients (Optional)

Provide users with these settings:

**IMAP Settings:**
- Server: `mail.spiffbox.xyz`
- Port: `993`
- Security: `SSL/TLS`
- Username: `user@spiffbox.xyz`

**SMTP Settings:**
- Server: `mail.spiffbox.xyz`
- Port: `587`
- Security: `STARTTLS`
- Authentication: `Required`

### Setup Backup Monitoring

- [ ] Verify backup script runs:
  ```bash
  sudo /opt/zimbra/bin/zimbra-backup.sh
  ```
- [ ] Check backup files created:
  ```bash
  ls -lh /opt/zimbra/backup/
  ```
- [ ] Backups configured to run daily at 2 AM

### Monitor System Health

- [ ] Check Zimbra services:
  ```bash
  su - zimbra -c "zmcontrol status"
  ```
- [ ] Check disk space:
  ```bash
  df -h
  ```
- [ ] Check memory:
  ```bash
  free -h
  ```
- [ ] Check logs for errors:
  ```bash
  tail -50 /opt/zimbra/log/mailbox.log
  ```

---

## 📋 PHASE 10: Documentation & Handoff

### Document Your Setup

- [ ] Record admin password in password manager
- [ ] Document server IP: `194.163.142.4`
- [ ] Note all DNS records configured
- [ ] Save SSL certificate renewal process
- [ ] Document backup procedures

### User Training

- [ ] Prepare user guide for webmail access
- [ ] Document email client settings
- [ ] Create password reset procedure
- [ ] Share admin console URL with IT staff

### Ongoing Maintenance

- [ ] Setup monitoring alerts
- [ ] Schedule monthly security updates
- [ ] Review backup logs weekly
- [ ] Check Fail2ban logs for security issues
- [ ] Monitor disk space usage

---

## ✅ Installation Complete!

### Access Points

**Admin Console**: https://mail.spiffbox.xyz:7071  
**Webmail**: https://mail.spiffbox.xyz  
**Admin Email**: admin@spiffbox.xyz

### Important Files

- Configuration: `/opt/zimbra/`
- Logs: `/opt/zimbra/log/`
- Backups: `/opt/zimbra/backup/`
- SSL Certs: `/etc/letsencrypt/live/mail.spiffbox.xyz/`

### Support Resources

- Documentation: `~/zimbra-setup/README.md`
- Troubleshooting: `~/zimbra-setup/TROUBLESHOOTING.md`
- DNS Guide: `~/zimbra-setup/DNS_SETUP_GUIDE.md`

---

## 🎉 Congratulations!

Your Zimbra mail server for **spiffbox.xyz** is now:

✅ Fully installed and configured  
✅ DNS properly set up  
✅ Security hardened  
✅ SSL certificate installed  
✅ Automated backups enabled  
✅ Production ready!

**Next Steps:**
1. Create user accounts
2. Train users on webmail
3. Monitor system regularly
4. Keep backups current
5. Update system monthly

---

**Setup Date**: ________________  
**Completed By**: ________________  
**Admin Password Stored**: ________________  
**Backup Verified**: ________________
