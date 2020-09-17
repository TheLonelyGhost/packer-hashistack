#!/usr/bin/env bash
set -euo pipefail

mkdir -p /opt/nomad/data
chown -R nomad:nomad /opt/nomad/data

cat >/etc/nomad.d/nomad.hcl <<EOH
# Full configuration options can be found at https://www.nomadproject.io/docs/configuration

data_dir             = "/opt/nomad/data"
log_rotate_max_files = 30
bind_addr            = "0.0.0.0"
EOH

cat >/etc/nomad.d/client.hcl <<EOH
client {
  enabled = true

  options {
    "user.blacklist"       = "root,${ENTRY_USER}"
    "user.checked_drivers" = "exec,raw_exec"
  }
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
