#!/usr/bin/env bash
set -euo pipefail

cat >/etc/vault.d/vault.hcl <<EOH
# TODO
EOH

cat >/etc/vault.d/agent.hcl <<EOH
# TODO
EOH

mkdir -p /etc/systemd/system/vault.service.d
cp /tmp/systemd/vault.service.d/agent.conf.example /etc/systemd/system/vault.service.d/agent.conf
systemctl daemon-reload

systemctl enable vault
systemctl start vault
