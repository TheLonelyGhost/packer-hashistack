#!/usr/bin/env bash
set -euo pipefail

: ${CONSUL_VERSION:=1.8.0}

printf '>>>  Downloading Consul v%s...\n' "$CONSUL_VERSION"
curl -SsLo ./consul_SHA256SUMS https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS
curl -SsLo ./consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip

if [ -e ./consul_SHA256SUMS ]; then
  printf '>>>  Verifying Consul download...\n'
  awk '/_linux_amd64/ { print $1 " consul.zip" }' ./consul_SHA256SUMS | sha256sum --check -
  rm ./consul_SHA256SUMS
fi

printf '>>>  Extracting Consul from archive\n'
unzip ./consul.zip
rm ./consul.zip

printf '>>>  Installing Consul binary to /usr/local/bin\n'
mkdir -p /usr/local/bin
chmod +x ./consul
chown root:root ./consul
mv ./consul /usr/local/bin/consul

/usr/local/bin/consul -autocomplete-install
complete -C /usr/local/bin/consul consul

printf '>>>  Creating Consul system user\n'
useradd --system --home /etc/consul.d --shell /bin/false consul

printf '>>>  Creating Consul data directory\n'
mkdir -p /etc/consul.d
chmod 600 -R /etc/consul.d
chmod 700 /etc/consul.d
chown -R consul:consul /etc/consul.d

# Consul has a VXLAN solution built-in, but HashiCorp recommends using Envoy instead
printf '>>>  Installing Envoy\n'
pushd /etc/yum.repos.d/ 1>/dev/null 2>&1
curl -SLO https://getenvoy.io/linux/centos/tetrate-getenvoy.repo
dnf makecache -y
popd 1>/dev/null 2>&1
dnf install -y getenvoy-envoy

# Make Consul DNS lookups work by using dnsmasq
dnf -y install dnsmasq
if [ -e /etc/systemd/resolved.conf ]; then
  printf '>>>  Workaround: Disabling systemd-resolved as a DNS resolver\n'
  perl -i -pe's/^(#+)?\s*DNSStubListener=.+$/DNSStubListener=no/g' /etc/systemd/resolved.conf
  systemctl restart systemd-resolved.service
fi

systemctl enable dnsmasq

if command -v firewall-cmd 1>/dev/null 2>&1; then
  # We're registering these as Firewalld services so we can choose to come back
  # later, when configuring Consul, to modify the ports associated with the each
  # service. Until then we can apply sane rules for who is allowed to communicate
  # to what service by assigning these to zones.
  for service in 'consul-dns' 'consul-grpc' 'consul-http' 'consul-https' 'consul-serf-lan' 'consul-serf-wan' 'consul-server' 'consul-sidecar' 'consul-expose'; do
    if [ -e "/tmp/firewalld/${service}.xml" ]; then
      printf '>>>  Installing firewall definition for %s\n' "$service"
      firewall-cmd --permanent --new-service-from-file="/tmp/firewalld/${service}.xml" --name="${service}"
    fi
  done

  printf '>>>  Allowing consul services in their proper zones\n'
  firewall-cmd --permanent --zone='public' --add-service='consul-expose'
  firewall-cmd --permanent --zone='public' --add-service='consul-grpc'
  firewall-cmd --permanent --zone='public' --add-service='consul-server'
  firewall-cmd --permanent --zone='public' --add-service='consul-serf-wan'
  firewall-cmd --permanent --zone='trusted' --add-service='consul-dns'
  firewall-cmd --permanent --zone='trusted' --add-service='consul-expose'
  firewall-cmd --permanent --zone='trusted' --add-service='consul-grpc'
  firewall-cmd --permanent --zone='trusted' --add-service='consul-http'
  firewall-cmd --permanent --zone='trusted' --add-service='consul-https'
  firewall-cmd --permanent --zone='trusted' --add-service='consul-serf-lan'
  firewall-cmd --permanent --zone='trusted' --add-service='consul-serf-wan'
  firewall-cmd --permanent --zone='trusted' --add-service='consul-server'
  firewall-cmd --permanent --zone='trusted' --add-service='consul-sidecar'
fi

systemctl daemon-reload
systemctl enable consul
