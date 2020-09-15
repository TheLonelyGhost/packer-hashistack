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

# NOTE: Firewalld implicitly allows all communication over local loopback
#       (127.0.0.1, ::1) to all ports.

# Most of what Nomad is likely to do involves http (80) and https (443) workloads, so...
firewall-cmd --permanent --zone='public' --add-service='http'
firewall-cmd --permanent --zone='public' --add-service='https'

# Client -> Client/Server communication
firewall-cmd --permanent --zone='trusted' --add-service='nomad-grpc'

firewall-cmd --reload

chown -R nomad:nomad /etc/nomad.d

systemctl enable nomad
systemctl start nomad
