#!/usr/bin/env bash
set -euo pipefail

dnf clean all
systemctl daemon-reload
systemctl restart sshd

printf '>>>  Reloading firewall\n'
firewall-cmd --reload
