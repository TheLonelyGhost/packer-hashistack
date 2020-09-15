# HashiStack (CentOS 8.x)

This Packer template builds a base image with Consul, Nomad, and Vault installed.

## Features

- Consul (v1.8.0) with Consul Connect configured
- Consul Template (v0.25.1)
- Nomad (v0.12.1)
- CNI plugins (v0.8.6)
- Vault (v1.5.0)

## Rehydration

Rehydrating Consul, Nomad, or Vault in an Agent/Client role is generally mutually exclusive to rehydrating it in a Server role. You must choose one or the other for each piece of software, not both.

Here's an example of rehydrating for...

- Linode
- Consul Agent
- Nomad Client
- Vault Agent

```
#!/usr/bin/env bash
set -euo pipefail

export API_TOKEN='<your-readonly-api-token>'
export REGION='us-east'

/opt/post-hoc/cluster-join-linode.sh
/opt/post-hoc/setup-consul-agent.sh
/opt/post-hoc/setup-vault-agent.sh
/opt/post-hoc/setup-nomad-client.sh
```

And here's one for the following:

- Digital Ocean
- Consul Server
- Nomad Server
- Vault Server

```
#!/usr/bin/env bash
set -euo pipefail

export API_TOKEN='<your-readonly-api-token>'
export REGION='nyc3'

/opt/post-hoc/cluster-join-digitalocean.sh
/opt/post-hoc/setup-consul-server.sh
/opt/post-hoc/setup-vault-server.sh
/opt/post-hoc/setup-nomad-server.sh
```

For only a minimal Nomad setup, perhaps you want it to act in both server and client capacity:

- Linode
- Nomad Server
- Nomad Client

```
#!/usr/bin/env bash
set -euo pipefail

export API_TOKEN='<your-readonly-api-token>'
export REGION='us-east'

/opt/post-hoc/cluster-join-linode.sh
/opt/post-hoc/setup-nomad-client.sh
/opt/post-hoc/setup-nomad-server.sh
```

## Building

- Requires read/write API keys for
  - Linode
  - Digital Ocean
- Requires environment variables for
  - SSH port
  - Desired username for bot account
  - Public key for bot account
