#!/usr/bin/env bash
set -euo pipefail

mkdir -p /opt/consul

cat >/etc/nomad.d/consul.hcl <<EOH
consul {
  address        = "127.0.0.1:8500"
  auto_advertise = true
}
EOH

# Override previous, cloud-specific join directives in favor
# of Consul service discovery mechanisms
cat >/etc/nomad.d/join.hcl <<EOH
consul {
  server_auto_join = true
  client_auto_join = true
}
EOH

cat >/etc/vault.d/consul.hcl <<EOH
service_registration "consul" {
  address = "127.0.0.1:8500"
}
EOH

cat >/etc/consul.d/consul.hcl <<EOH
data_dir    = "/opt/consul"
client_addr = "0.0.0.0"

datacenter = "dc1"
EOH

cat >/etc/consul.d/connect.hcl <<EOH
connect {
  enabled     = true
}
EOH

cat >/etc/consul.d/encrypt.hcl <<EOH
encrypt = "${CONSUL_SERF_ENCRYPTION_KEY}"
encrypt_verify_incoming = true
encrypt_verify_outgoing = true
EOH

# NOTE: Firewalld implicitly allows all communication over local loopback
#       (127.0.0.1, ::1) to all ports.

# LAN-based, peer-to-peer gossip for Consul data
firewall-cmd --permanent --zone='internal' --add-service='consul-serf-lan'

# WAN-based, peer-to-peer gossip for Consul data
firewall-cmd --permanent --zone='public' --add-service='consul-serf-wan'

# Endpoint communication over the VXLAN (Envoy), but may travel through
# anywhere on the WAN
firewall-cmd --permanent --zone='public' --add-service='consul-grpc'

# Consul external service checkers (Not needed for our specific purposes)
#firewall-cmd --permanent --zone='public' --add-service='consul-expose'

# Consul connect proxies (not needed since expose ports to local loopback only)
#firewall-cmd --permanent --zone='trusted' --add-service='consul-sidecar'

firewall-cmd --reload


systemctl start consul
systemctl enable consul
systemctl start consul-template
systemctl enable consul-template
