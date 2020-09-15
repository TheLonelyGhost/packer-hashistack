#!/usr/bin/env bash
set -euo pipefail

: ${CONSUL_TAG:-consul-server}
: ${NOMAD_TAG:-nomad-server}
: ${REGION:-nyc1}

cat >/etc/consul.d/join.hcl <<EOH
retry_join = ["provider=digitalocean tag_name=${TAG} region=${REGION} api_token=${API_TOKEN}"]
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
