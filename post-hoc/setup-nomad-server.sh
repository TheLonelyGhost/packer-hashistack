#!/usr/bin/env bash
set -euo pipefail

cat >/etc/nomad.d/nomad.hcl <<EOH
# Full configuration options can be found at https://www.nomadproject.io/docs/configuration

data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"
EOH

cat >/etc/nomad.d/server.hcl <<EOH
server {
  enabled = true
  encrypt = "${NOMAD_SERF_ENCRYPTION_KEY}"
}
EOH

# NOTE: Firewalld implicitly allows all communication over local loopback
#       (127.0.0.1, ::1) to all ports.

# Inter-node communication (allowed to be `public`, but Consul keeps `trusted` zone up-to-date with our network)
firewall-cmd --permanent --zone='trusted' --add-service='nomad-serf'

# CLI -> Client and UI -> Server communication
firewall-cmd --permanent --zone='trusted' --add-service='nomad-http'

# Client -> Client/Server communication
firewall-cmd --permanent --zone='trusted' --add-service='nomad-grpc'

firewall-cmd --reload

chown -R nomad:nomad /etc/nomad.d

systemctl enable nomad
systemctl start nomad
