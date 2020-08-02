#!/usr/bin/env bash
set -euo pipefail

dnf clean all
systemctl daemon-reload
systemctl restart sshd

printf '>>>  Reloading firewall\n'

# if [ "${SSH_PORT}" -ne 22 ]; then
#   firewall-cmd --permanent --service='ssh' --remove-port='22/tcp'
# fi
firewall-cmd --reload
