#!/usr/bin/env bash
set -euo pipefail

dnf clean all
systemctl daemon-reload
systemctl restart sshd

if command -v firewall-cmd 1>/dev/null 2>&1; then
  printf '>>>  Reloading firewall\n'
  firewall-cmd --reload
fi
