# Zimbra Automated Installation Suite

## 📦 Package Contents

This comprehensive Zimbra installation suite includes everything you need to deploy, secure, and maintain a production-ready Zimbra Collaboration Suite on Ubuntu Linux.

### Files Included

| File | Description | Size |
|------|-------------|------|
| **install-zimbra.sh** | Main installation script with full automation | ~14 KB |
| **pre-install-check.sh** | System validation and readiness checker | ~10 KB |
| **post-install-hardening.sh** | Security hardening and best practices | ~11 KB |
| **zimbra-config.conf.example** | Configuration template for unattended installs | ~3 KB |
| **README.md** | Complete documentation and guide | ~10 KB |
| **QUICK_START.md** | Quick reference guide | ~7 KB |
| **TROUBLESHOOTING.md** | Common issues and solutions | ~12 KB |

**Total Package Size**: ~68 KB of pure automation power! 🚀

---

## 🎯 What This Suite Does

### 1️⃣ Pre-Installation (pre-install-check.sh)
✅ Validates Ubuntu version (20.04+ recommended)  
✅ Checks system resources (RAM, CPU, disk)  
✅ Verifies hostname and DNS configuration  
✅ Detects port conflicts  
✅ Identifies conflicting services  
✅ Tests internet connectivity  
✅ Reviews network settings  
✅ Provides detailed readiness report  

### 2️⃣ Installation (install-zimbra.sh)
✅ Configures system hostname  
✅ Installs all required dependencies  
✅ Disables conflicting services (Postfix, Apache, etc.)  
✅ Configures firewall rules  
✅ Downloads latest Zimbra release  
✅ Performs automated installation  
✅ Sets up admin credentials  
✅ Configures all Zimbra services  
✅ Verifies installation success  
✅ Provides access information  

### 3️⃣ Security Hardening (post-install-hardening.sh)
✅ Installs & configures Fail2ban  
✅ Applies advanced firewall rules  
✅ Enforces strong password policies  
✅ Enables security headers (HSTS, XSS protection)  
✅ Configures DKIM for email authentication  
✅ Sets up automated daily backups  
✅ Configures ClamAV auto-updates  
✅ Implements system monitoring  
✅ Hardens SSH access  
✅ Enables automatic security updates  

---

## 🚀 Quick Usage

### Basic Installation (3 Steps)
```bash
# Step 1: Validate system
chmod +x pre-install-check.sh
sudo ./pre-install-check.sh

# Step 2: Install Zimbra
chmod +x install-zimbra.sh
sudo ./install-zimbra.sh

# Step 3: Apply security
chmod +x post-install-hardening.sh
sudo ./post-install-hardening.sh
```

**That's it!** You now have a production-ready, secured Zimbra mail server! 🎉

---

## 📋 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04 LTS or 22.04 LTS
- **RAM**: 4GB (8GB+ recommended)
- **Disk**: 10GB free (50GB+ recommended)
- **CPU**: 2 cores minimum (4+ recommended)
- **Network**: Static IP address
- **Access**: Root/sudo privileges

### Supported Versions
| Ubuntu Version | Status |
|----------------|--------|
| 22.04 LTS | ✅ Fully Supported |
| 20.04 LTS | ✅ Fully Supported |
| 18.04 LTS | ⚠️ May work but not recommended |

---

## 🔐 Security Features

The post-installation hardening script implements industry best practices:

### Brute Force Protection
- Fail2ban with Zimbra-specific filters
- Automatic IP blocking after 5 failed attempts
- Enhanced protection for admin console (3 attempts)

### Password Policies
- Minimum 10 characters
- Requires: uppercase, lowercase, number, special character
- Account lockout after failed attempts
- 1-hour lockout duration

### Firewall Hardening
- Rate limiting on all mail ports
- Strict controls on admin ports
- UFW automatic configuration

### Email Authentication
- DKIM signing enabled
- SPF configuration guidance
- DMARC recommendations

### Monitoring & Alerts
- Disk space monitoring
- Service health checks
- Mail queue monitoring
- Email alerts for issues

### Backup & Recovery
- Automated daily backups (2 AM)
- 30-day retention policy
- Compressed backup archives
- Easy restore procedures

---

## 📊 Feature Matrix

| Feature | Pre-Check | Install | Harden |
|---------|-----------|---------|--------|
| System Validation | ✅ | - | - |
| Dependency Installation | - | ✅ | - |
| Hostname Configuration | - | ✅ | - |
| Zimbra Installation | - | ✅ | - |
| Firewall Setup | - | ✅ | ✅ |
| Password Policies | - | - | ✅ |
| Fail2ban | - | - | ✅ |
| DKIM Setup | - | - | ✅ |
| Automated Backups | - | - | ✅ |
| Security Headers | - | - | ✅ |
| Monitoring Alerts | - | - | ✅ |
| SSH Hardening | - | - | ✅ |
| Auto Updates | - | - | ✅ |

---

## 📚 Documentation Structure

### For Quick Setup
**Start here**: `QUICK_START.md`
- Essential steps only
- Common commands
- Basic configuration

### For Complete Information
**Read this**: `README.md`
- Detailed requirements
- Complete installation guide
- Post-installation tasks
- Security considerations

### For Problem Solving
**Refer to**: `TROUBLESHOOTING.md`
- Common issues
- Step-by-step solutions
- Debugging commands
- Performance tuning

### For Advanced Configuration
**Use this**: `zimbra-config.conf.example`
- Unattended installation
- Custom parameters
- Automation options

---

## 🎓 Installation Workflow

```
┌─────────────────────────────────────────────────┐
│  1. Pre-Installation Check                      │
│     └─ pre-install-check.sh                     │
│        ├─ System Requirements ✓                 │
│        ├─ Network Configuration ✓               │
│        ├─ DNS Setup ✓                           │
│        └─ Port Availability ✓                   │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│  2. Main Installation (15-30 minutes)           │
│     └─ install-zimbra.sh                        │
│        ├─ Configure System ✓                    │
│        ├─ Install Dependencies ✓                │
│        ├─ Download Zimbra ✓                     │
│        ├─ Install & Configure ✓                 │
│        └─ Start Services ✓                      │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│  3. Security Hardening (5-10 minutes)           │
│     └─ post-install-hardening.sh                │
│        ├─ Install Fail2ban ✓                    │
│        ├─ Configure Firewall ✓                  │
│        ├─ Apply Security Policies ✓             │
│        ├─ Setup Backups ✓                       │
│        └─ Enable Monitoring ✓                   │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│  4. Manual Steps                                │
│     ├─ Configure DNS Records (SPF, DKIM, DMARC) │
│     ├─ Install SSL Certificate                  │
│     ├─ Create User Accounts                     │
│     └─ Test Email Flow                          │
└─────────────────────────────────────────────────┘
                      ↓
              ✅ PRODUCTION READY! ✅
```

---

## 🌟 Key Features

### ✨ Fully Automated
- Interactive prompts for configuration
- Intelligent error handling
- Progress logging
- Automatic service management

### 🔒 Security First
- Enterprise-grade security policies
- Automated hardening
- Intrusion prevention
- Regular security updates

### 📊 Production Ready
- Comprehensive logging
- Service monitoring
- Automated backups
- Performance optimized

### 🛠️ Easy Maintenance
- Built-in monitoring scripts
- Automated backup system
- Simple update procedures
- Extensive documentation

### 🚨 Error Handling
- Validation at every step
- Clear error messages
- Automatic rollback on failure
- Detailed logging

---

## 💡 Use Cases

### Small Business Email Server
- 10-50 users
- Basic email and calendar
- Cost-effective solution
- Easy management

### Enterprise Mail Infrastructure
- 100+ users
- Advanced collaboration
- High availability
- Security compliance

### Development/Testing Environment
- Quick deployment
- Easy reset/rebuild
- Multiple domains
- Testing scenarios

### Educational Institutions
- Student/faculty email
- Collaboration tools
- Cost-effective
- Self-hosted

---

## 📈 What You Get

After running these scripts, you'll have:

✅ **Fully functional Zimbra server**
- Webmail interface
- Admin console
- Email services (SMTP, IMAP, POP3)

✅ **Security hardened system**
- Brute-force protection
- Strong password policies
- Encrypted connections
- Email authentication (DKIM)

✅ **Automated maintenance**
- Daily backups
- Log rotation
- Virus definition updates
- Security updates

✅ **Monitoring & alerts**
- Disk space monitoring
- Service health checks
- Email notifications
- Queue monitoring

✅ **Complete documentation**
- Installation guides
- Configuration examples
- Troubleshooting help
- Command references

---

## 🔧 Maintenance Commands

### Check System Health
```bash
sudo ./pre-install-check.sh
```

### View Service Status
```bash
su - zimbra -c "zmcontrol status"
```

### Manual Backup
```bash
/opt/zimbra/bin/zimbra-backup.sh
```

### View Security Logs
```bash
sudo tail -f /var/log/fail2ban.log
```

---

## 🎯 Support & Resources

### Documentation
- 📖 README.md - Complete guide
- 🚀 QUICK_START.md - Fast reference
- 🔍 TROUBLESHOOTING.md - Problem solving

### Online Resources
- 🌐 [Zimbra Wiki](https://wiki.zimbra.com/)
- 💬 [Community Forums](https://forums.zimbra.org/)
- 🐛 [Bug Tracker](https://bugzilla.zimbra.com/)

### Log Files
- 📝 /var/log/zimbra-install.log
- 📝 /var/log/zimbra-hardening.log
- 📝 /opt/zimbra/log/mailbox.log

---

## ⚠️ Important Notes

### Before Installation
1. ✅ Ensure DNS records are configured
2. ✅ Have a static IP address
3. ✅ Backup any existing data
4. ✅ Test in development first

### After Installation
1. ✅ Install SSL certificate (Let's Encrypt or commercial)
2. ✅ Configure SPF, DKIM, and DMARC DNS records
3. ✅ Create user accounts
4. ✅ Test email sending and receiving
5. ✅ Setup external backup solution
6. ✅ Configure monitoring alerts

### Production Considerations
1. ⚠️ Use commercial SSL certificates
2. ⚠️ Configure reverse DNS (PTR record)
3. ⚠️ Setup high availability if needed
4. ⚠️ Implement offsite backups
5. ⚠️ Regular security audits
6. ⚠️ Monitor blacklist status

---

## 🏆 Best Practices Implemented

✅ Security-first approach  
✅ Automated backup strategy  
✅ Comprehensive logging  
✅ Error handling at every step  
✅ Service health monitoring  
✅ Firewall protection  
✅ Intrusion prevention  
✅ Strong authentication  
✅ Email authentication (SPF/DKIM/DMARC)  
✅ Regular updates  
✅ Documentation complete  
✅ Easy troubleshooting  

---

## 📜 License & Disclaimer

**License**: These scripts are provided as-is for educational and production use.

**Disclaimer**: Always test in a development environment before deploying to production. Ensure you have proper backups before making any changes to a production Zimbra server.

**Support**: These are community scripts. For official Zimbra support, visit https://www.zimbra.com/support/

---

## 👨‍💼 Created By

**Senior IT Administrator Team**  
Version: 1.0.0  
Last Updated: January 24, 2026  

**Tested On:**
- Ubuntu 22.04 LTS ✅
- Ubuntu 20.04 LTS ✅

---

## 🎉 Ready to Get Started?

```bash
# Clone or download this repository
cd zimbra

# Make scripts executable
chmod +x *.sh

# Start with pre-installation check
sudo ./pre-install-check.sh

# Follow the QUICK_START.md guide
cat QUICK_START.md
```

**Happy Zimbra Installation! 📧🚀**

---

**Need Help?** Refer to TROUBLESHOOTING.md or visit the Zimbra community forums!
