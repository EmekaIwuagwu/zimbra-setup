# 🚀 Getting Started with Zimbra Setup for oregonstate.de

Welcome! This guide will help you get your Zimbra mail server up and running for **oregonstate.de** in the fastest way possible.

---

## 📚 What's in This Repository?

You have **14 files** to help you install and manage Zimbra:

### 🔧 Installation Scripts
1. **setup-server.sh** - Quick server hostname setup ⚡ **START HERE!**
2. **verify-dns.sh** - DNS verification tool
3. **pre-install-check.sh** - System readiness checker
4. **install-zimbra.sh** - Main Zimbra installer
5. **post-install-hardening.sh** - Security hardening

### 📖 Documentation
6. **QUICK_REFERENCE.md** - One-page cheat sheet 📌 **PRINT THIS!**
7. **INSTALLATION_CHECKLIST.md** - Step-by-step checklist
8. **DNS_SETUP_GUIDE.md** - Detailed DNS setup for Spaceship.com
9. **QUICK_START.md** - Fast track installation
10. **README.md** - Complete documentation
11. **TROUBLESHOOTING.md** - Problem solving guide
12. **OVERVIEW.md** - Suite overview

### ⚙️ Configuration
13. **zimbra-config.conf** - Your oregonstate.de configuration
14. **zimbra-config.conf.example** - Template file

---

## ⚡ Quick Start (5 Simple Steps)

### Step 1: Configure DNS at Spaceship.com (FIRST!)

Login to Spaceship.com → Domains → oregonstate.de → DNS Settings

Add these DNS records:

```
A      mail        173.249.1.171
MX     @           mail.oregonstate.de    (priority: 10)
TXT    @           v=spf1 mx ip4:173.249.1.171 ~all
TXT    _dmarc      v=DMARC1; p=quarantine; rua=mailto:dmarc@oregonstate.de
```

**CRITICAL**: Contact your server hosting provider to add:
```
PTR: 173.249.1.171 → mail.oregonstate.de
```

⏰ **Wait 1-4 hours** for DNS propagation before continuing.

---

### Step 2: SSH to Your Server

```bash
ssh root@173.249.1.171
```

---

### Step 3: Clone Repository

```bash
git clone https://github.com/EmekaIwuagwu/zimbra-setup.git
cd zimbra-setup
chmod +x *.sh
```

---

### Step 4: Run Installation Scripts

```bash
# Setup server hostname
sudo ./setup-server.sh

# Verify DNS (make sure it passes!)
./verify-dns.sh

# System check
sudo ./pre-install-check.sh

# Install Zimbra (takes 15-30 minutes)
sudo ./install-zimbra.sh
```

When prompted during installation:
- Hostname: **mail.oregonstate.de**
- Domain: **oregonstate.de**
- Password: **[choose strong password]**

---

### Step 5: Add DKIM & Harden Security

```bash
# Get DKIM public key
su - zimbra -c "zmprov gd oregonstate.de zimbraDKIMPublicKey"

# Copy the key, then add to Spaceship.com DNS:
# TXT record at: default._domainkey
# Value: v=DKIM1; k=rsa; p=[YOUR_KEY_HERE]

# Apply security hardening
sudo ./post-install-hardening.sh
```

---

## ✅ You're Done!

Access your mail server:

**Admin Console**: https://mail.oregonstate.de:7071  
**Webmail**: https://mail.oregonstate.de  
**Username**: admin@oregonstate.de  
**Password**: [what you set in Step 4]

---

## 📖 Detailed Guides (Read These!)

### For First-Time Setup
1. **INSTALLATION_CHECKLIST.md** - Complete step-by-step checklist with boxes to check ✓
2. **DNS_SETUP_GUIDE.md** - Detailed DNS configuration for Spaceship.com

### For Daily Use
3. **QUICK_REFERENCE.md** - Essential commands and info (print this!)
4. **TROUBLESHOOTING.md** - When something goes wrong

### For Understanding
5. **OVERVIEW.md** - What this suite does and why
6. **README.md** - Complete technical documentation

---

## 🎯 Which File to Use When?

| Situation | File to Use |
|-----------|-------------|
| 🆕 Setting up for first time | INSTALLATION_CHECKLIST.md |
| 🌐 Configuring DNS | DNS_SETUP_GUIDE.md |
| ⚡ Need quick commands | QUICK_REFERENCE.md |
| 🔍 Checking DNS is working | Run: `./verify-dns.sh` |
| 🛠️ Something's broken | TROUBLESHOOTING.md |
| 📚 Want to understand everything | OVERVIEW.md + README.md |
| 🚀 Already know what I'm doing | QUICK_START.md |

---

## 💡 Pro Tips

### Before You Start
- ✅ Configure DNS FIRST (wait for propagation!)
- ✅ Get PTR record set up by your hosting provider
- ✅ Have your admin password ready
- ✅ Print QUICK_REFERENCE.md for easy access

### During Installation
- ⏰ Installation takes 15-30 minutes - be patient
- 📝 Write down your admin password
- ☕ Grab coffee during the installation
- 📊 Monitor progress in the logs

### After Installation
- 🔒 Add DKIM DNS record immediately
- 🛡️ Run security hardening script
- 📧 Send test emails to verify
- 📱 Set up SSL certificate (Let's Encrypt)

---

## 🆘 Quick Troubleshooting

### DNS not resolving?
```bash
./verify-dns.sh  # Check what's wrong
```

### Installation fails?
```bash
tail -100 /var/log/zimbra-install.log  # Check errors
```

### Services won't start?
```bash
su - zimbra -c "zmcontrol status"  # Check what's down
tail -50 /opt/zimbra/log/mailbox.log  # Check logs
```

### Need help?
- Check **TROUBLESHOOTING.md**
- Visit: https://forums.zimbra.org/

---

## 📋 Installation Workflow Diagram

```
┌─────────────────────────────────────┐
│ 1. Configure DNS at Spaceship.com  │
│    (A, MX, SPF, DMARC records)     │
│    Request PTR from hosting provider│
└──────────────┬──────────────────────┘
               │ Wait 1-4 hours
               ↓
┌─────────────────────────────────────┐
│ 2. SSH to server (173.249.1.171)   │
│    Clone repository                 │
│    chmod +x *.sh                    │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 3. sudo ./setup-server.sh           │
│    (Sets hostname, updates hosts)   │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 4. ./verify-dns.sh                  │
│    (Verify DNS is working)          │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 5. sudo ./pre-install-check.sh      │
│    (Check system requirements)      │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 6. sudo ./install-zimbra.sh         │
│    (Install Zimbra - 15-30 min)     │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 7. Get DKIM key & add to DNS        │
│    su - zimbra -c "zmprov gd..."    │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 8. sudo ./post-install-hardening.sh │
│    (Apply security measures)        │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 9. Install SSL Certificate          │
│    (Let's Encrypt recommended)      │
└──────────────┬──────────────────────┘
               ↓
         ✅ DONE! ✅
   Access: https://mail.oregonstate.de
```

---

## 🎓 Learning Path

### Beginner? Start Here
1. Read **OVERVIEW.md** (understand what you're installing)
2. Follow **INSTALLATION_CHECKLIST.md** (step-by-step)
3. Keep **QUICK_REFERENCE.md** handy

### Intermediate? Try This
1. Read **QUICK_START.md**
2. Use **DNS_SETUP_GUIDE.md** for DNS
3. Refer to **TROUBLESHOOTING.md** if issues

### Expert? Do This
1. Review **zimbra-config.conf**
2. Run scripts in sequence
3. Check **README.md** for advanced options

---

## 📞 Support & Resources

### Documentation in This Repo
- All guides in this folder
- Check TROUBLESHOOTING.md first

### Official Zimbra Resources
- Wiki: https://wiki.zimbra.com/
- Forums: https://forums.zimbra.org/
- Docs: https://docs.zimbra.com/

### DNS & Email Testing
- DNS Checker: https://dnschecker.org/
- MX Toolbox: https://mxtoolbox.com/
- Email Health: https://mxtoolbox.com/emailhealth/

### Your Support Contacts
- Spaceship.com: https://www.spaceship.com/support
- Server Host: [Your hosting provider]

---

## ✨ What Makes This Special?

✅ **Fully Automated** - Minimal manual intervention  
✅ **Security First** - Enterprise-grade hardening included  
✅ **Well Documented** - 14 files of comprehensive guides  
✅ **Production Ready** - Battle-tested scripts  
✅ **Your Domain** - Pre-configured for oregonstate.de  
✅ **Easy Maintenance** - Built-in backup and monitoring  

---

## 🎯 Success Checklist

After completing installation, verify:

- [ ] Can login to admin console (https://mail.oregonstate.de:7071)
- [ ] Can login to webmail (https://mail.oregonstate.de)
- [ ] Can send email to external address (Gmail/Outlook)
- [ ] External email arrives in Zimbra
- [ ] DNS records verified (run `./verify-dns.sh`)
- [ ] SSL certificate installed
- [ ] DKIM record added to DNS
- [ ] Automated backups working
- [ ] Fail2ban active

---

## 🚀 Ready to Begin?

### Start Installation Now:
1. Open **INSTALLATION_CHECKLIST.md**
2. Follow each checkbox
3. Keep **QUICK_REFERENCE.md** nearby

### Or Quick Install:
1. Configure DNS at Spaceship.com
2. SSH to server: `ssh root@173.249.1.171`
3. Run:
```bash
git clone https://github.com/EmekaIwuagwu/zimbra-setup.git
cd zimbra-setup
chmod +x *.sh
sudo ./setup-server.sh
./verify-dns.sh
sudo ./pre-install-check.sh
sudo ./install-zimbra.sh
sudo ./post-install-hardening.sh
```

---

## 📧 Questions?

Check these files in order:
1. **QUICK_REFERENCE.md** - Quick answers
2. **TROUBLESHOOTING.md** - Common problems
3. **README.md** - Detailed info
4. **Zimbra Forums** - Community help

---

**Good luck with your installation!** 🎉

Your Zimbra mail server for **oregonstate.de** will be running in about 2-3 hours (including DNS propagation time).

Remember: **DNS configuration first, installation second!**
