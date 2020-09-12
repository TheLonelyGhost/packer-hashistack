#!/usr/bin/env bash
set -euo pipefail

# : ${LINODE_API_TOKEN:=}
: ${LINODE_TAG_NOMAD:=nomad-server}
: ${LINODE_REGION:=us-east}

# TODO: Setup config files for nomad

cat >/etc/nomad.d/nomad.hcl <<EOH
# Full configuration options can be found at https://www.nomadproject.io/docs/configuration

data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"
EOH

cat >/etc/nomad.d/server.hcl <<EOH
server {
  enabled = true
  server_join {
    retry_join = ["provider=linode tag_name=${LINODE_TAG_NOMAD} region=${LINODE_REGION} address_type=private_v4 api_token=${LINODE_API_TOKEN}"]
  }
}
EOH

chown -R nomad:nomad /etc/nomad.d

systemctl enable nomad
systemctl restart nomad
