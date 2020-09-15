#!/usr/bin/env bash
set -euo pipefail

NODE_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

: ${CONSUL_TAG:-consul-server}
: ${NOMAD_TAG:-nomad-server}
: ${REGION:-us-east}

cat >/etc/consul.d/join.hcl <<EOH
retry_join = ["provider=linode tag_name=${CONSUL_TAG} region=${REGION} api_token=${API_TOKEN}"]
EOH

cat >/etc/nomad.d/join.hcl <<EOH
client {
  server_join {
    retry_join = ["provider=linode tag_name=${NOMAD_TAG} region=${REGION} api_token=${API_TOKEN}"]
  }
}

server {
  server_join {
    retry_join = ["provider=linode tag_name=${NOMAD_TAG} region=${REGION} api_token=${API_TOKEN}"]
  }
}
EOH
