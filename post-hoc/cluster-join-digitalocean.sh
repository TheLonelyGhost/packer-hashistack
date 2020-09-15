#!/usr/bin/env bash
set -euo pipefail

NODE_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

: ${CONSUL_TAG:-consul-server}
: ${NOMAD_TAG:-nomad-server}
: ${REGION:-nyc1}

cat >/etc/consul.d/join.hcl <<EOH
retry_join = ["provider=digitalocean tag_name=${TAG} region=${REGION} api_token=${API_TOKEN}"]
EOH

cat >/etc/consul.d/node.hcl <<EOH
# This defaults to the system hostname
#node_name = "${NODE_ID}"
EOH

cat >/etc/nomad.d/node.hcl <<EOH
# This defaults to the system hostname
#name = "${NODE_ID}"
EOH

cat >/etc/nomad.d/join.hcl <<EOH
client {
  server_join {
    retry_join = ["provider=digitalocean tag_name=${NOMAD_TAG} region=${REGION} api_token=${API_TOKEN}"]
  }
}

server {
  server_join {
    retry_join = ["provider=digitalocean tag_name=${NOMAD_TAG} region=${REGION} api_token=${API_TOKEN}"]
  }
}
EOH
