#!/usr/bin/env bash
set -euo pipefail

mkdir -p /usr/local/bin

curl -SLo ./hashicorp.repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
mv ./hashicorp.repo /etc/yum.repos.d/hashicorp.repo
curl -SLo ./docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
mv ./docker-ce.repo /etc/yum.repos.d/docker-ce.repo
curl -SLo ./tetrate-getenvoy.repo https://getenvoy.io/linux/centos/tetrate-getenvoy.repo
mv ./tetrate-getenvoy.repo /etc/yum.repos.d/tetrate-getenvoy.repo

dnf makecache

printf '>>>  Docker install workaround for CentOS 8.x\n'
dnf module enable container-tools && \
  dnf install container-selinux && \
  dnf module disable container-tools

dnf install -y nomad consul vault getenvoy-envoy docker-ce

printf '>>>  Enabling bridge networking (Nomad task groups, Consul Connect)\n'
modprobe br_netfilter
echo 'br_netfilter' > /etc/modules-load.d/nomad-br_netfilter.conf

cat >/etc/sysctl.d/70-nomad.conf <<EOH
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOH

if grep -qFe docker /etc/group 1>/dev/null 2>&1; then
  printf '>>>  Allowing Nomad to communicate with Docker\n'
  usermod -aG docker nomad
fi

printf '>>>  Installing CNI plugins (v%s)\n' "${CNI_PLUGINS_VERSION}"
mkdir -p /opt/cni/bin

curl -SsLo ./cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz"
curl -SsLo ./cni-plugins_SHA256SUMS "https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz.sha256"

if [ -e ./cni-plugins_SHA256SUMS ]; then
  awk '/-linux-amd64/ { print $1 " cni-plugins.tgz" }' ./cni-plugins_SHA256SUMS | sha256sum --check -
  rm ./cni-plugins_SHA256SUMS
fi
tar xzf ./cni-plugins.tgz -C /opt/cni/bin/


printf '>>>  Installing envconsul (v%s)...\n' "$ENVCONSUL_VERSION"
curl -SsLo ./envconsul_SHA256SUMS https://releases.hashicorp.com/envconsul/${ENVCONSUL_VERSION}/envconsul_${ENVCONSUL_VERSION}_SHA256SUMS
curl -SsLo ./envconsul.zip https://releases.hashicorp.com/envconsul/${ENVCONSUL_VERSION}/envconsul_${ENVCONSUL_VERSION}_linux_amd64.zip

if [ -e ./envconsul_SHA256SUMS ]; then
  awk '/_linux_amd64.zip/ { print $1 " envconsul.zip" }' ./envconsul_SHA256SUMS | sha256sum --check -
  rm ./envconsul_SHA256SUMS
fi
unzip ./envconsul.zip
rm ./envconsul.zip
chmod +x ./envconsul
chown root:root ./envconsul
mv ./envconsul /usr/local/bin/envconsul

printf '>>>  Installing consul-template (v%s)...\n' "$CONSUL_TEMPLATE_VERSION"
curl -SsLo ./consul-template_SHA256SUMS https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_SHA256SUMS
curl -SsLo ./consul-template.zip https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip

if [ -e ./consul-template_SHA256SUMS ]; then
  awk '/_linux_amd64.zip/ { print $1 " consul-template.zip" }' ./consul-template_SHA256SUMS | sha256sum --check -
  rm ./consul-template_SHA256SUMS
fi
unzip ./consul-template.zip
rm ./consul-template.zip
chmod +x ./consul-template
chown root:root ./consul-template
mv ./consul-template /usr/local/bin/consul-template

printf '>>>  Registering Consul firewall services for later activation\n'
for service in 'consul-dns' 'consul-grpc' 'consul-http' 'consul-https' 'consul-serf-lan' 'consul-serf-wan' 'consul-server' 'consul-sidecar' 'consul-expose'; do
  if [ -e "/tmp/firewalld/${service}.xml" ]; then
    printf '>>>  Installing firewall definition for "%s" service... ' "$service"
    firewall-cmd --permanent --new-service-from-file="/tmp/firewalld/${service}.xml" --name="${service}"
  fi
done

printf '>>>  Creating ipset to more easily translate Consul cluster membership to firewall rules\n'
firewall-cmd --permanent --new-ipset='consul' --type='hash:net'
firewall-cmd --permanent --zone='trusted' --add-source='ipset:consul'

printf '>>>  Registering Nomad firewall services for later activation\n'
for service in 'nomad-http' 'nomad-serf' 'nomad-grpc'; do
  if [ -e "/tmp/firewalld/${service}.xml" ]; then
    printf '>>>  Installing firewall definition for "%s" service... ' "$service"
    firewall-cmd --permanent --new-service-from-file="/tmp/firewalld/${service}.xml" --name="${service}"
  fi
done

printf '>>>  Registering Vault firewall services for later activation\n'
for service in 'vault-http' 'vault-cluster'; do
  if [ -e "/tmp/firewalld/${service}.xml" ]; then
    printf '>>>  Installing firewall definition for "%s" service\n' "$service"
    firewall-cmd --permanent --new-service-from-file="/tmp/firewalld/${service}.xml" --name="${service}"
  fi
done
