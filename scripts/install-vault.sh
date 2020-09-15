#!/usr/bin/env bash
set -euo pipefail

: ${VAULT_VERSION:=1.5.0}

printf '>>>  Downloading Vault v%s...\n' "$VAULT_VERSION"
curl -SsLo ./vault_SHA256SUMS https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS
curl -SsLo ./vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip

if [ -e ./vault_SHA256SUMS ]; then
  printf '>>>  Verifying Vault download...\n'
  awk '/_linux_amd64/ { print $1 " vault.zip" }' ./vault_SHA256SUMS | sha256sum --check -
  rm ./vault_SHA256SUMS
fi

printf '>>>  Extracting Vault from archive\n'
unzip ./vault.zip
rm ./vault.zip

printf '>>>  Installing Vault binary to /usr/local/bin\n'
mkdir -p /usr/local/bin
chmod +x ./vault
chown root:root ./vault
mv ./vault /usr/local/bin/vault
setcap cap_ipc_lock=+ep /usr/local/bin/vault

/usr/local/bin/vault -autocomplete-install
complete -C /usr/local/bin/vault vault

printf '>>>  Creating Vault system user\n'
useradd --system --home /etc/vault.d --shell /bin/false vault

printf '>>>  Creating Vault data directory\n'
mkdir -p /etc/vault.d
chown -R vault:vault /etc/vault.d
chmod 700 /etc/vault.d

if command -v firewall-cmd 1>/dev/null 2>&1; then
  for service in 'vault-http' 'vault-cluster'; do
    if [ -e "/tmp/firewalld/${service}.xml" ]; then
      printf '>>>  Installing firewall definition for "%s" service\n' "$service"
      firewall-cmd --permanent --new-service-from-file="/tmp/firewalld/${service}.xml" --name="${service}"
    fi
  done

  # This should be enabled for Vault Server nodes only, or else we risk
  # exposing the built-in VAULT_TOKEN that the agent sinks to the
  # filesystem.

  #firewall-cmd --permanent --zone='trusted' --add-service='vault'
fi

# systemctl enable vault
