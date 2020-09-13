#!/usr/bin/env bash
set -euo pipefail

mkdir -p /opt/consul

cat >/etc/consul.d/consul.hcl <<EOH
data_dir = "/opt/consul"
client_addr = "0.0.0.0"

ui = true
EOH

cat >/etc/consul.d/agent.hcl <<EOH
# TODO
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

###### <CONSUL-SERVER-ONLY> ########
# Consul server-to-server communication (Consul Server only)
firewall-cmd --permanent --zone='public' --add-service='consul-server'

# HTTP API (without TLS) for Consul functionality (Consul Server only)
firewall-cmd --permanent --zone='trusted' --add-service='consul-http'

# HTTP API (with TLS) for Consul functionality (Consul Server only)
firewall-cmd --permanent --zone='trusted' --add-service='consul-https'

# Consul DNS-based APIs (Consul Server only)
firewall-cmd --permanent --zone='trusted' --add-service='consul-dns'
###### </CONSUL-SERVER-ONLY> ########

firewall-cmd --reload


systemctl start consul
systemctl enable consul
systemctl start consul-template
systemctl enable consul-template
