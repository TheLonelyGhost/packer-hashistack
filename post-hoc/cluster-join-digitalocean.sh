#!/usr/bin/env bash
set -euo pipefail

: ${TAG:-consul-server}
: ${REGION:-nyc1}

cat >/etc/consul.d/join.hcl <<EOH
retry_join = ["provider=digitalocean tag_name=${TAG} region=${REGION} api_token=${API_TOKEN}"]
EOH
