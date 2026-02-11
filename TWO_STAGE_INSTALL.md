# Two-Stage Zimbra Installation Guide

## Why Two Stages?

The automated installer keeps failing during LDAP initialization because we can't see what's happening inside. This two-stage approach gives us **full visibility and control**.

## Stage 1: Install Packages Only

This stage installs all Zimbra packages **without** attempting any configuration.

```bash
cd ~/zimbra-setup
git pull
chmod +x *.sh
sudo ./install-zimbra-stage1.sh
```

**What it does**:
- Disables AppArmor
- Stops conflicting services (postfix, sendmail)
- Downloads Zimbra 10.1 PLUS
- Installs system dependencies
- Installs Zimbra packages with `-s` (skip configuration)

**Expected result**: All packages installed, `/opt/zimbra` created, but no services running yet.

---

## Stage 2: Manual LDAP Setup

This stage configures LDAP manually with full visibility into each step.

```bash
sudo ./install-zimbra-stage2.sh
```

**What it does**:
1. Configures hostname and /etc/hosts
2. Manually runs `zmldapinit` to initialize LDAP
3. **Checks LDAP status** before proceeding
4. Creates domain and admin account
5. Enables all Zimbra services
6. Starts all components

**Key advantage**: If LDAP fails, we see the **exact error** from `/opt/zimbra/log/slapd.log` immediately.

---

## Troubleshooting

If Stage 2 fails at LDAP initialization:

```bash
# Check LDAP logs
sudo cat /opt/zimbra/log/slapd.log

# Check if port 389 is already in use
sudo netstat -tlnp | grep 389

# Try starting LDAP manually
sudo su - zimbra -c "/opt/zimbra/bin/ldap start"
sudo su - zimbra -c "/opt/zimbra/bin/ldap status"
```

---

## Why This Will Work

1. **Package installation separate from configuration** - We know the packages install fine
2. **Full LDAP visibility** - We'll see exactly why slapd won't start
3. **Manual service startup** - We control the sequence
4. **Real-time error checking** - Script stops at first failure with logs

---

## Full Command Sequence

```bash
# Complete cleanup
cd ~/zimbra-setup
git pull
sudo rm -rf /opt/zimbra /etc/zimbra*
sudo userdel zimbra 2>/dev/null
sudo groupdel zimbra 2>/dev/null

# Stage 1: Install packages
chmod +x *.sh
sudo ./install-zimbra-stage1.sh

# Stage 2: Configure LDAP and services
sudo ./install-zimbra-stage2.sh
```

---

## Recovery from Failed Attempts

If you need to restart:

```bash
# Stop all Zimbra services
sudo su - zimbra -c "zmcontrol stop" 2>/dev/null || true

# Remove Zimbra completely
sudo rm -rf /opt/zimbra /etc/zimbra*
sudo userdel zimbra 2>/dev/null
sudo groupdel zimbra 2>/dev/null

# Start fresh with Stage 1
sudo ./install-zimbra-stage1.sh
```
