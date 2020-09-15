#!/usr/bin/env bash
set -euo pipefail

: ${TAG:-consul-server}
: ${REGION:-us-east}

cat >/etc/consul.d/join.hcl <<EOH
retry_join = ["provider=linode tag_name=${TAG} region=${REGION} api_token=${API_TOKEN}"]
EOH
