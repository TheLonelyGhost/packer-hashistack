#!/usr/bin/env bash
set -euo pipefail

# So we can find `modinfo`, `modprobe`, and `sysctl`
PATH="${PATH}:/usr/sbin:/sbin"

if command -v modprobe 1>/dev/null 2>&1; then
  modprobe=$(command -v modprobe)
elif [ -x /usr/sbin/modprobe ]; then
  modprobe=/usr/sbin/modprobe
elif [ -x /sbin/modprobe ]; then
  modprobe=/sbin/modprobe
else
  printf '>>>  FAILURE: Could not find modprobe command\n' 1>&2
  exit 1
fi
if command -v modinfo 1>/dev/null 2>&1; then
  modinfo=$(command -v modinfo)
elif [ -x /usr/sbin/modinfo ]; then
  modinfo=/usr/sbin/modinfo
elif [ -x /sbin/modinfo ]; then
  modinfo=/sbin/modinfo
else
  printf '>>>  FAILURE: Could not find modinfo command\n' 1>&2
  exit 1
fi
if command -v sysctl 1>/dev/null 2>&1; then
  sysctl=$(command -v sysctl)
elif [ -x /usr/sbin/sysctl ]; then
  sysctl=/usr/sbin/sysctl
elif [ -x /sbin/sysctl ]; then
  sysctl=/sbin/sysctl
else
  printf '>>>  FAILURE: Could not find sysctl command\n' 1>&2
  exit 1
fi

: ${NOMAD_VERSION:=0.12.1}
: ${CNI_PLUGINS_VERSION:=0.8.6}

mkdir -p /tmp/nomad

pushd /tmp/nomad 1>/dev/null 2>&1

printf '>>>  Downloading Nomad v%s...\n' "$NOMAD_VERSION"
curl -SsLo ./nomad_SHA256SUMS https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS

curl -SsLo ./nomad.zip https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip

if [ -e ./nomad_SHA256SUMS ]; then
  awk '/_linux_amd64/ { print $1 " nomad.zip" }' ./nomad_SHA256SUMS | sha256sum --check -
  rm ./nomad_SHA256SUMS
fi

unzip ./nomad.zip
rm ./nomad.zip

mkdir -p /usr/local/bin
chmod +x ./nomad
mv ./nomad /usr/local/bin/nomad

/usr/local/bin/nomad -autocomplete-install
complete -C /usr/local/bin/nomad nomad

printf '>>>  Creating Nomad system user\n'
useradd --system --home /etc/nomad.d --shell /bin/false nomad
mkdir -p /etc/nomad.d
chown -R nomad:nomad /etc/nomad.d

printf '>>>  Creating Nomad data directory\n'
mkdir -p /opt/nomad
chown -R nomad:nomad /opt/nomad

{
  printf 'data_dir = "%s"\n' '/opt/nomad'
} > /etc/nomad.d/base.hcl


# This is done for Nomad, Kubernetes, and other container-based orchestration tools
printf '>>>  Enable kernel modules for Nomad to work with Consul Connect (bridge networking)\n'

# Prerequisite for bridge networking stuff
if "$modinfo" br_netfilter 1>/dev/null 2>&1; then
  "$modprobe" br_netfilter

  # Make sure it's loaded on boot in the future
  mkdir -p /etc/modules-load.d
  {
    printf 'br_netfilter\n'
  } > /etc/modules-load.d/nomad-br_netfilter.conf
fi

# Allow bridge network to go through iptables (which is how Nomad works with Consul Connect)
{
  printf 'net.bridge.bridge-nf-call-arptables = 1\n'
  printf 'net.bridge.bridge-nf-call-ip6tables = 1\n'
  printf 'net.bridge.bridge-nf-call-iptables = 1\n'
} > /etc/sysctl.d/70-nomad.conf
"$sysctl" --load /etc/sysctl.d/70-nomad.conf

if command -v firewall-cmd 1>/dev/null 2>&1; then
  for service in 'nomad-http' 'nomad-serf' 'nomad-grpc'; do
    if [ -e "/tmp/firewalld/${service}.xml" ]; then
      printf '>>>  Installing firewall definition for "%s" service\n' "$service"
      firewall-cmd --permanent --new-service-from-file="/tmp/firewalld/${service}.xml" --name="${service}"
    fi
  done

  printf '>>>  Setting up firewall rules Nomad services\n'
  firewall-cmd --permanent --zone='public' --add-service='http'
  firewall-cmd --permanent --zone='public' --add-service='https'

  printf '>>>  Setting up firewall rules for Nomad HTTP API and UI\n'
  firewall-cmd --permanent --zone='public' --add-service='nomad-http'

  printf '>>>  Setting up firewall rules for Nomad inter-node communication\n'
  firewall-cmd --permanent --zone='internal' --add-service='nomad-serf'
  firewall-cmd --permanent --zone='trusted' --add-service='nomad-serf'
  firewall-cmd --permanent --zone='trusted' --add-service='nomad-grpc'
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

systemctl daemon-reload
systemctl enable nomad
