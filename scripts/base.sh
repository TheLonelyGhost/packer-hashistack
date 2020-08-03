#!/usr/bin/env bash
set -euo pipefail

dnf update -y
dnf install -y unzip curl policycoreutils-python-utils perl tar firewalld epel-release
dnf install -y fail2ban

systemctl daemon-reload
systemctl enable fail2ban

if command -v firewall-cmd 1>/dev/null 2>&1; then
  if ! firewall-cmd --zone='public' --list-services | grep -e ssh 1>/dev/null; then
    printf '>>>  Allow SSH communications over WAN\n'
    firewall-cmd --permanent --zone='public' --add-service='ssh'
  fi
fi

printf '>>>  Setting timezone to UTC\n'
timedatectl set-timezone UTC && sleep 2

printf '>>>  Disabling root login over SSH\n'
perl -i -pe's/^(#+)?\s*PermitRootLogin (yes|no)(.*)/PermitRootLogin no\3/g' /etc/ssh/sshd_config

printf '>>>  Disabling password login over SSH\n'
perl -i -pe's/^(#+)?\s*PasswordAuthentication (yes|no)(.*)/PasswordAuthentication no\3/g' /etc/ssh/sshd_config

if [ "${SSH_PORT:-22}" != '22' ]; then
  printf '>>>  Changing SSH port\n'
  perl -i -pe's/^(#+)?\s*Port 22\s*$/Port '"${SSH_PORT}"'\n/g' /etc/ssh/sshd_config
  semanage port -a -t ssh_port_t -p tcp "${SSH_PORT}"
  if command -v firewall-cmd 1>/dev/null 2>&1; then
    firewall-cmd --permanent --service='ssh' --add-port="${SSH_PORT}/tcp"
    firewall-cmd --reload
  fi
fi

printf '>>>  Deduping SSH config settings (where lines are exactly the same)\n'
perl -i -lne '$seen{$_}++ and next or print;' /etc/ssh/sshd_config

# Setup another SSH user for machine access, since we've disabled root and password auth
if [ -n "${ENTRY_USER:-}" -a -n "${ENTRY_USER_PUBKEY:-}" ]; then
  printf '>>>  Creating automation-access user account %s\n' "${ENTRY_USER}"
  useradd "${ENTRY_USER}"
  printf '%s:%s\n' "${ENTRY_USER}" 'U6aMy0wojraho' | chpasswd -e 1>/dev/null
  printf '%s ALL = (ALL) NOPASSWD: ALL\n' "${ENTRY_USER}" >> /etc/sudoers
  mkdir -p /home/"${ENTRY_USER}"/.ssh
  printf '%s\n' "${ENTRY_USER_PUBKEY}" >> /home/"${ENTRY_USER}"/.ssh/authorized_keys
  chown -R "${ENTRY_USER}:${ENTRY_USER}" /home/"${ENTRY_USER}"
  chmod 700 /home/"${ENTRY_USER}"/.ssh
  chmod 600 /home/"${ENTRY_USER}"/.ssh/authorized_keys
fi

# LINODE: Add private IPv4 range to internal network zone
if command -v firewall-cmd 1>/dev/null 2>&1; then
  firewall-cmd --permanent --zone='internal' --add-source='192.168.128.0/17'
fi
