# VPN-DNS-Playbook

Ansible playbook to set up a home server with VPN access, two-factor authentication, and secure remote access via a VPS reverse SSH relay (works behind CGNAT — no open ports required).

## What it sets up

| Service | Purpose |
|---|---|
| [Headscale](https://github.com/juanfont/headscale) | Self-hosted Tailscale coordination server (VPN control plane) |
| [Headscale UI](https://github.com/gurucomputing/headscale-ui) | Web interface for managing headscale nodes and keys |
| [Authelia](https://github.com/authelia/authelia) | Two-factor authentication (protects headscale-ui and other services) |
| [SWAG](https://github.com/linuxserver/docker-swag) | Reverse proxy + Let's Encrypt wildcard certs |
| [Portainer](https://github.com/portainer/portainer) | Remote Docker container management |
| [wetty](https://github.com/butlerx/wetty) | Web-accessible oops shell — break-glass SSH via browser (Authelia-gated) |
| [Homer Dashboard](https://github.com/bastienwirtz/homer) | Service index dashboard |

## How remote access works

Public HTTPS traffic reaches the server via a **VPS reverse SSH relay**:

```
Browser → Cloudflare DNS → VPS :443
       → socat → autossh reverse tunnel → SWAG :443 → services
```

1. A cheap VPS (e.g. Google Cloud free tier e2-micro) runs `socat`, listening on `:443`
2. The home server maintains a persistent `autossh` reverse SSH tunnel, forwarding `127.0.0.1:8443` on the VPS to SWAG on the LAN
3. Cloudflare DNS points `*.your.domain` and `your.domain` to the VPS IP (unproxied A records)

This bypasses CGNAT and works without any open ports on the home server. Crucially, it passes raw TCP — which is required for the Tailscale TS2021 protocol (Cloudflare's HTTP/2 proxy is incompatible with it).

## How the VPN works

This playbook uses [Tailscale](https://tailscale.com/) (the client app) pointed at a self-hosted [Headscale](https://github.com/juanfont/headscale) server instead of Tailscale's cloud.

- **Headscale** runs on your server as the coordination server (replaces tailscale.com)
- **Tailscale** client app is installed on every device (phone, laptop, etc.)
- The **server itself** runs Tailscale as a subnet router, advertising your LAN (`192.168.0.0/16`) to all connected devices
- Once connected, you can reach any device on your home network from anywhere

## Requirements

- A machine running **Ubuntu Server** (PC or Raspberry Pi 4+)
- A domain managed on **Cloudflare DNS** (free account) with a Cloudflare API token (`Zone:DNS:Edit`)
- A **VPS** with a public IP and SSH access (Google Cloud free tier e2-micro works well)
- Your **local DNS server** (router, Pi-hole, etc.) resolving `*.your.domain` → server's local IP

## Setup

### 1. Cloudflare account

1. Create a free account at [cloudflare.com](https://cloudflare.com) and add your domain
2. In your domain registrar, point the nameservers to the ones Cloudflare assigns
3. In **My Profile → API Tokens → Create Token**, create a custom token with:
   - **Zone → DNS → Edit** (scoped to your domain)

   Save the token as `cloudflare_api_token` in `secret.yml`.

The `vps.yml` playbook automatically manages the DNS records (`*.your.domain` and `your.domain` → VPS IP).

### 2. VPS (Google Cloud)

A single **e2-micro** instance on Google Cloud's free tier works well (free in `us-central1`, `us-east1`, or `us-west1`).

#### Create the VM

1. Go to **Compute Engine → VM instances → Create instance**
2. Set a name (e.g. `vps-relay`)
3. Region: pick a free-tier region (`us-central1` recommended)
4. Machine type: **e2-micro**
5. Boot disk: **Ubuntu 24.04 LTS**, 30 GB standard persistent disk
6. Under **Advanced → Security**, add your SSH public key (`~/.ssh/id_ed25519.pub`):
   - Set the username to whatever you want (e.g. `ubuntu`) — this becomes `vps_user` in `secret.yml`
7. Click **Create**

#### Reserve a static external IP

By default GCP assigns an ephemeral IP that changes on stop/start. Make it static:

1. Go to **VPC Network → IP addresses**
2. Find the ephemeral IP attached to your VM → click **Reserve**

Save this IP as `vps_host` in `secret.yml`.

#### Open port 443

GCP's default firewall blocks all inbound ports except SSH. Add a rule for port 443:

1. Go to **VPC Network → Firewall → Create firewall rule**
2. Name: `allow-https-relay`
3. Direction: **Ingress**
4. Targets: **All instances in the network** (or add a network tag to the VM and target that)
5. Source filter: `0.0.0.0/0`
6. Protocols and ports: **TCP 443**
7. Click **Create**

The `vps.yml` playbook installs socat and configures the relay automatically.

### 3. Ansible setup

1. Install Ansible: `pip install ansible` (or `brew install ansible` on macOS)
2. Install role dependencies: `ansible-galaxy install -r requirements.yml`
3. Ensure SSH access to your Ubuntu server
4. Copy `secret_example.yml` to `secret.yml` and fill in your values

## Running the playbooks

Provision the VPS relay first:
```bash
ansible-playbook vps.yml
```

Then provision the home server:
```bash
ansible-playbook server.yml
```

Run a specific part using tags (see `server.yml` for available tags):
```bash
ansible-playbook server.yml -t <tag>
```

## Post-installation

### 1. Set up headscale

Create a user in headscale (used to group your devices):
```bash
docker exec headscale headscale users create USERNAME
```

Note the user ID from the output, then generate a reusable pre-auth key for your devices:
```bash
docker exec headscale headscale preauthkeys create -u USER_ID --reusable --expiration 24h
```

Save this key as `tailscale_preauth_key` in `secret.yml` and re-run the playbook — it connects the server's Tailscale client as a subnet router for your LAN.

### 2. Connect your devices

Install the [Tailscale app](https://tailscale.com/download) on each device. In the app:

1. Go to **Settings → Account → Use custom coordination server**
2. Enter `https://<headscale_subdomain>.your.domain` (the obscure control-plane subdomain set in `secret.yml`, with the `https://` prefix)
3. Tap **Log in**

Device registration works from anywhere — the VPS relay passes raw TCP so the Tailscale TS2021 protocol reaches Headscale without issue.

To register and name the device, SSH into the server and run the helper **before** tapping Log in:
```bash
register_device <device-name> <headscale-user>
```
It watches the headscale logs, captures the registration key automatically, registers the device, and renames the node (devices otherwise all register as `localhost`).

Or use the Headscale UI at `https://headscale.your.domain` to manage nodes and pre-auth keys.

### 3. Approve the server as a subnet router

After the server's Tailscale connects, approve the advertised subnet in headscale:
```bash
docker exec headscale headscale routes list
docker exec headscale headscale routes enable -r ROUTE_ID
```

## Service Management

### Add or remove a service

```bash
./service.sh
```

New services are internal by default — accessible from your local network, through Tailscale, or via Authelia 2FA if exposed publicly. DNS is handled automatically by the `*.your.domain` wildcard record.

### Configure the Homer dashboard

Homer files live at `~/homer` on the server. Edit them there directly via SSH.

See the [Homer documentation](https://github.com/bastienwirtz/homer/blob/main/docs/configuration.md) for configuration options.

## Local DNS override

Configure your local DNS server (e.g. Pi-hole, router) to resolve your domain directly to the server's local IP so LAN devices don't round-trip through the VPS:

```
your.domain     → <server-local-ip>
*.your.domain   → <server-local-ip>
```

## Oops shell

A web-accessible SSH shell (`wetty`) is available at `https://oops.your.domain` (or whatever `webssh_subdomain` you set) for recovering the server when normal SSH is unavailable (lost key, ISP blocking port 22, sshd/firewall lockout). It is intentionally reachable over the internet through the VPS relay and is protected by two independent factors:

1. **Authelia two-factor** in front (the `*.your.domain` access-control rule)
2. The **system SSH user + password**, prompted by wetty itself (it holds no stored credentials and connects back to the host's sshd)

> **Scope:** this rescues cases where the OS/SSH is wedged but Docker is still running. It cannot help if Docker itself is down or the kernel has panicked — for that you need your cloud provider's serial console or IPMI.

## Two-factor authentication

Authelia uses **TOTP** (authenticator-app codes) as the second factor. SMTP is configured (`smtp_*` in `secret.yml`) so Authelia emails the TOTP enrollment link and security notifications.

> The per-login second factor is the **TOTP code** from your authenticator app — email/SMS-delivered login OTP is not an Authelia feature in this configuration. Email is the delivery channel for enrollment and notifications, not for the login code itself.

> For Gmail, use an [App Password](https://support.google.com/accounts/answer/185833) as `smtp_password`.

## Debugging

### Logs

All services run as Docker containers. To tail logs for a container:
```bash
sudo docker logs -f <container-name>
```

Container names:

| Service | Container name |
|---|---|
| SWAG | `swag` |
| Authelia | `authelia` |
| Headscale | `headscale` |
| Headscale UI | `headscale-ui` |
| Portainer | `portainer` |
| Oops shell (wetty) | `webssh` |
| Homer Dashboard | `homer` |

### Reverse tunnel

The autossh tunnel runs as a systemd service on the home server:
```bash
systemctl status headscale-tunnel
journalctl -u headscale-tunnel -f
```

The socat relay runs as a systemd service on the VPS:
```bash
systemctl status headscale-relay
journalctl -u headscale-relay -f
```

## Credits

Thanks to Wolfgang for his [ansible-easy-vpn](https://github.com/notthebee/ansible-easy-vpn) playbook, which this is largely based on.
