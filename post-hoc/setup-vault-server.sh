#!/usr/bin/env bash
set -euo pipefail

cat >/etc/vault.d/vault.hcl <<EOH
# TODO
EOH

cat >/etc/vault.d/server.hcl <<EOH
server = true
ui     = true
EOH

firewall-cmd --permanent --zone='trusted' --add-service='vault-http'
firewall-cmd --reload

systemctl enable vault
systemctl start vault
