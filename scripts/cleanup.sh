#!/usr/bin/env bash
set -euo pipefail

chmod +x /opt/first-run/*.sh

dnf clean all
systemctl daemon-reload
systemctl restart sshd

# Remove traces of MAC address and UUID from network configuration
sed -E -i '/^(HWADDR|UUID)/d' /etc/sysconfig/network-scripts/ifcfg-e*

# Disable root login through ssh with a key
sed -i 's/nullok//g' /etc/pam.d/system-auth /etc/pam.d/password-auth-ac /etc/pam.d/password-auth /etc/pam.d/system-auth-ac

# Lock root account
passwd -d root
passwd -l root

# Remove ssh host keys
rm -rf /etc/ssh/ssh_host*_key*

# Clean up /root
rm -f /root/anaconda-ks.cfg
rm -f /root/install.log
rm -f /root/install.log.syslog
rm -rf /root/.pki

# Clean up /var/log
>/var/log/cron
>/var/log/dmesg
>/var/log/lastlog
>/var/log/maillog
>/var/log/messages
>/var/log/secure
>/var/log/wtmp
>/var/log/audit/audit.log
>/var/log/rhsm/rhsm.log
>/var/log/rhsm/rhsmcertd.log
rm -f /var/log/*.old
rm -f /var/log/*.log
rm -f /var/log/*.syslog

# Clean /tmp
rm -rf /tmp/*
rm -rf /tmp/*.*

# Zero out the free space to save space in the final image
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Clear history
history -c

if command -v firewall-cmd 1>/dev/null 2>&1; then
  printf '>>>  Reloading firewall\n'
  firewall-cmd --reload
fi
