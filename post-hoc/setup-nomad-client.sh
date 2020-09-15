#!/usr/bin/env bash
set -euo pipefail

cat >/etc/nomad.d/nomad.hcl <<EOH
# Full configuration options can be found at https://www.nomadproject.io/docs/configuration

data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"
EOH

cat >/etc/nomad.d/client.hcl <<EOH
client {
  enabled = true
}
EOH

chown -R nomad:nomad /etc/nomad.d

systemctl enable nomad
systemctl restart nomad
