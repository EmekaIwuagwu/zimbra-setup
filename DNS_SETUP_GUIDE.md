# DNS Configuration Guide for maybax.de on Spaceship.com

## 🌐 DNS Setup for Zimbra Mail Server

**Domain**: maybax.de
**Mail Server IP**: 5.189.184.167
**Registrar**: Spaceship.com
**Mail Hostname**: mail.maybax.de  

---

## 📋 Step-by-Step DNS Configuration on Spaceship.com

### Step 1: Login to Spaceship.com

1. Go to https://www.spaceship.com/
2. Click **Sign In**
3. Login with your credentials
4. Navigate to **Domains** in your dashboard
5. Click on **maybax.de**

### Step 2: Access DNS Settings

1. In your domain dashboard, find **DNS Settings** or **DNS Management**
2. Click on **DNS Records** or **Manage DNS**

---

## 🔧 DNS Records to Add

### 1. A Record (Mail Server)

**Purpose**: Points mail.maybax.de to your server IP

```
Type:     A
Host:     mail
Value:    5.189.184.167
TTL:      3600 (or 1 hour)
```

**In Spaceship.com interface:**
- Record Type: `A`
- Name/Host: `mail`
- Points to/Value: `5.189.184.167`
- TTL: `3600` or `Auto`

### 2. A Record (Root Domain - Optional)

**Purpose**: Points maybax.de to your server (if you want webmail at maybax.de)

```
Type:     A
Host:     @  (or leave blank for root)
Value:    5.189.184.167
TTL:      3600
```

**In Spaceship.com interface:**
- Record Type: `A`
- Name/Host: `@` or leave empty
- Points to/Value: `5.189.184.167`
- TTL: `3600` or `Auto`

### 3. MX Record (Mail Exchange)

**Purpose**: Tells other mail servers where to send email for @maybax.de

```
Type:     MX
Host:     @  (or leave blank for root)
Value:    mail.maybax.de
Priority: 10
TTL:      3600
```

**In Spaceship.com interface:**
- Record Type: `MX`
- Name/Host: `@` or leave empty
- Mail Server: `mail.maybax.de`
- Priority: `10`
- TTL: `3600` or `Auto`

**Important**: Make sure to include the trailing dot if required: `mail.maybax.de.`

### 4. SPF Record (Spam Protection)

**Purpose**: Prevents other servers from spoofing your domain

```
Type:     TXT
Host:     @  (or leave blank for root)
Value:    v=spf1 mx ip4:5.189.184.167 ~all
TTL:      3600
```

**In Spaceship.com interface:**
- Record Type: `TXT`
- Name/Host: `@` or leave empty
- Text Value: `v=spf1 mx ip4:5.189.184.167 ~all`
- TTL: `3600` or `Auto`

### 5. DKIM Record (Email Authentication)

**Purpose**: Cryptographic email authentication

⚠️ **IMPORTANT**: Add this AFTER Zimbra installation

First, get your DKIM public key after installing Zimbra:

```bash
su - zimbra -c "zmprov gd maybax.de zimbraDKIMSelector"
su - zimbra -c "zmprov gd maybax.de zimbraDKIMPublicKey"
```

Then add this DNS record:

```
Type:     TXT
Host:     default._domainkey
Value:    v=DKIM1; k=rsa; p=YOUR_PUBLIC_KEY_HERE
TTL:      3600
```

**In Spaceship.com interface:**
- Record Type: `TXT`
- Name/Host: `default._domainkey`
- Text Value: `v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBA...` (your actual key)
- TTL: `3600` or `Auto`

### 6. DMARC Record (Email Policy)

**Purpose**: Email authentication policy and reporting

```
Type:     TXT
Host:     _dmarc
Value:    v=DMARC1; p=quarantine; rua=mailto:dmarc@maybax.de; pct=100; fo=1
TTL:      3600
```

**In Spaceship.com interface:**
- Record Type: `TXT`
- Name/Host: `_dmarc`
- Text Value: `v=DMARC1; p=quarantine; rua=mailto:dmarc@maybax.de; pct=100; fo=1`
- TTL: `3600` or `Auto`

### 7. PTR Record (Reverse DNS) - CRITICAL!

⚠️ **IMPORTANT**: PTR records cannot be set at Spaceship.com!

You MUST contact your **server hosting provider** to set this up.

**What to request from your hosting provider:**

```
PTR Record:
5.189.184.167 → mail.maybax.de
```

Or in reverse DNS format:
```
134.106.91.144.in-addr.arpa → mail.maybax.de
```

**Why this is critical**: Without proper reverse DNS (PTR), many mail servers (especially Gmail, Outlook) will reject your emails as spam.

**How to verify after setup:**
```bash
nslookup 5.189.184.167
# Should return: mail.maybax.de

# Or use:
dig -x 5.189.184.167
```

---

## 📸 Spaceship.com DNS Configuration Summary

After adding all records, your DNS zone should look like this:

| Type | Name/Host | Value/Points To | Priority | TTL |
|------|-----------|-----------------|----------|-----|
| A | mail | 5.189.184.167 | - | 3600 |
| A | @ | 5.189.184.167 | - | 3600 |
| MX | @ | mail.maybax.de | 10 | 3600 |
| TXT | @ | v=spf1 mx ip4:5.189.184.167 ~all | - | 3600 |
| TXT | default._domainkey | v=DKIM1; k=rsa; p=YOUR_KEY... | - | 3600 |
| TXT | _dmarc | v=DMARC1; p=quarantine; rua=mailto:dmarc@maybax.de | - | 3600 |

---

## ✅ Verification Steps

### Before Installing Zimbra

1. **Wait for DNS Propagation** (can take 1-24 hours)
   ```bash
   # Test A record
   nslookup mail.maybax.de
   # Should return: 5.189.184.167
   
   # Test MX record
   nslookup -query=mx maybax.de
   # Should return: mail.maybax.de
   ```

2. **Verify from multiple locations**
   - Use: https://dnschecker.org/
   - Enter: `mail.maybax.de`
   - Check that it resolves to `5.189.184.167` globally

3. **Check MX record**
   - Use: https://mxtoolbox.com/SuperTool.aspx
   - Enter: `maybax.de`
   - Verify MX record points to `mail.maybax.de`

### After Installing Zimbra

1. **Verify PTR record**
   ```bash
   dig -x 5.189.184.167
   # Should return: mail.maybax.de
   ```

2. **Test SPF record**
   ```bash
   dig txt maybax.de
   # Should show: "v=spf1 mx ip4:5.189.184.167 ~all"
   ```

3. **Test DKIM**
   ```bash
   dig txt default._domainkey.maybax.de
   # Should show your public key
   ```

4. **Test DMARC**
   ```bash
   dig txt _dmarc.maybax.de
   # Should show your DMARC policy
   ```

5. **Complete mail server test**
   - Visit: https://mxtoolbox.com/emailhealth/
   - Enter: `maybax.de`
   - Review all checks (should be mostly green)

---

## 🚀 Installation Sequence

### Phase 1: DNS Setup (Do This FIRST - Before Installing Zimbra)

1. ✅ Add A record for `mail.maybax.de`
2. ✅ Add A record for `@` (root domain)
3. ✅ Add MX record
4. ✅ Add SPF TXT record
5. ✅ Wait 1-4 hours for DNS propagation
6. ✅ Verify DNS with `nslookup` and online tools
7. ✅ **Contact hosting provider for PTR record**

### Phase 2: Server Preparation

1. ✅ SSH into your server at `5.189.184.167`
2. ✅ Update Ubuntu: `sudo apt update && sudo apt upgrade -y`
3. ✅ Reboot if needed: `sudo reboot`
4. ✅ Clone the repository:
   ```bash
   git clone https://github.com/EmekaIwuagwu/zimbra-setup.git
   cd zimbra-setup
   chmod +x *.sh
   ```

### Phase 3: Pre-Installation Check

```bash
sudo ./pre-install-check.sh
```

Fix any issues identified before proceeding.

### Phase 4: Zimbra Installation

```bash
sudo ./install-zimbra.sh
```

When prompted:
- **Hostname**: `mail.maybax.de`
- **Domain**: `maybax.de`
- **Admin Password**: (choose a strong password)

### Phase 5: Post-Installation (Add DKIM to DNS)

1. Get DKIM public key:
   ```bash
   su - zimbra -c "zmprov gd maybax.de zimbraDKIMPublicKey"
   ```

2. Go back to Spaceship.com DNS settings
3. Add the DKIM TXT record (see step 5 above)
4. Wait 1 hour for propagation

### Phase 6: Security Hardening

```bash
sudo ./post-install-hardening.sh
```

### Phase 7: SSL Certificate (Let's Encrypt)

```bash
# Install certbot
sudo apt-get install -y certbot

# Stop Zimbra proxy
su - zimbra -c "zmproxyctl stop"

# Get certificate
sudo certbot certonly --standalone -d mail.maybax.de

# Deploy certificate
su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm /etc/letsencrypt/live/mail.maybax.de/cert.pem /etc/letsencrypt/live/mail.maybax.de/chain.pem"

# Restart Zimbra
su - zimbra -c "zmcontrol restart"
```

---

## 🔍 Common Spaceship.com DNS Issues

### Issue 1: DNS Changes Not Showing

**Solution**: 
- DNS propagation can take 1-24 hours
- Check TTL value (lower = faster updates)
- Clear local DNS cache:
  ```bash
  # Windows
  ipconfig /flushdns
  
  # Linux/Mac
  sudo systemd-resolve --flush-caches
  ```

### Issue 2: MX Record Format

**Spaceship.com may require:**
- Ending dot: `mail.maybax.de.` (note the dot at the end)
- Or without dot: `mail.maybax.de`

Try the format that works in their interface.

### Issue 3: Cannot Add TXT Records

**Solution**:
- Some registrars require quotes around TXT values
- Try both: `v=spf1 mx ~all` and `"v=spf1 mx ~all"`

### Issue 4: PTR Record

**Remember**: 
- PTR records are NOT managed at Spaceship.com
- Contact your SERVER hosting provider (where 5.189.184.167 is hosted)
- This is absolutely critical for email delivery

---

## 📞 Support Contacts

### Spaceship.com Support
- Website: https://www.spaceship.com/support
- Email: support@spaceship.com
- Live Chat: Available in dashboard

### For PTR Record
- Contact your server/VPS hosting provider
- Provide: IP (5.189.184.167) → Hostname (mail.maybax.de)

---

## ✅ Pre-Installation Checklist

Before running `./install-zimbra.sh`, verify:

- [ ] A record for mail.maybax.de points to 5.189.184.167
- [ ] MX record for maybax.de points to mail.maybax.de
- [ ] SPF TXT record is added
- [ ] DNS propagation complete (test with nslookup)
- [ ] PTR record requested from hosting provider
- [ ] Server at 5.189.184.167 is accessible via SSH
- [ ] Server is running Ubuntu 20.04 or 22.04
- [ ] You have root/sudo access

---

## 🎯 Quick Access URLs (After Installation)

**Admin Console**: https://mail.maybax.de:7071  
**Webmail**: https://mail.maybax.de  
**Also accessible at**: https://maybax.de (if you added root A record)

**Default Admin Account**:
- Username: `admin@maybax.de`
- Password: (what you set during installation)

---

**DNS Configuration Complete!** 🎉

Once DNS is propagated and verified, proceed with Zimbra installation using the `zimbra-config.conf` file provided.
