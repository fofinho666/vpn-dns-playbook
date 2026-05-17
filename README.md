# VPN-DNS-Playbook

Ansible playbook to set up a home server with VPN access, two-factor authentication, and secure remote access via Cloudflare Tunnel (works behind CGNAT — no open ports required).

## What it sets up

| Service | Purpose |
|---|---|
| [Headscale](https://github.com/juanfont/headscale) | Self-hosted Tailscale coordination server (VPN control plane) |
| [Headscale UI](https://github.com/gurucomputing/headscale-ui) | Web interface for managing headscale nodes and keys |
| [Authelia](https://github.com/authelia/authelia) | Two-factor authentication (protects headscale-ui and other services) |
| [SWAG](https://github.com/linuxserver/docker-swag) | Reverse proxy + Let's Encrypt wildcard certs |
| [cloudflared](https://github.com/cloudflare/cloudflared) | Cloudflare Tunnel (bypasses CGNAT, no open ports required) |
| [Portainer](https://github.com/portainer/portainer) | Remote Docker container management |
| [wetty](https://github.com/butlerx/wetty) | Web-accessible oops shell — break-glass SSH via browser (Authelia-gated) |
| [Homer Dashboard](https://github.com/bastienwirtz/homer) | Service index dashboard |

## How the VPN works

This playbook uses [Tailscale](https://tailscale.com/) (the client app) pointed at a self-hosted [Headscale](https://github.com/juanfont/headscale) server instead of Tailscale's cloud.

- **Headscale** runs on your server as the coordination server (replaces tailscale.com)
- **Tailscale** client app is installed on every device (phone, laptop, etc.)
- The **server itself** runs Tailscale as a subnet router, advertising your LAN (`192.168.0.0/16`) to all connected devices
- Once connected, you can reach any device on your home network from anywhere

## Requirements

- A machine running **Ubuntu Server** (PC or Raspberry Pi 4+)
- A domain managed on **Cloudflare DNS** (free account)
- A Cloudflare API token with `Zone:DNS:Edit` permission
- A Cloudflare Tunnel token (Zero Trust → Networks → Tunnels)

> No port forwarding or static IP required — all web traffic flows through the Cloudflare Tunnel.

## Setup

### 1. Cloudflare account

1. Create a free account at [cloudflare.com](https://cloudflare.com) and add your domain
2. In your domain registrar, point the nameservers to the two Cloudflare assigns (wait ~30 min)
3. In **My Profile → API Tokens → Create Token**, create a custom token with:
   - **Zone → DNS → Edit** (scoped to your domain)

   Save the token as `cloudflare_api_token` in `secret.yml`.
4. In **Zero Trust → Networks → Tunnels → Create a tunnel**, choose Cloudflared and copy the token — save it as `cloudflare_tunnel_token` in `secret.yml`.

   In the tunnel's **Public Hostnames** tab, add a wildcard route: hostname `*.your.domain` → service `https://your-server-local-ip:443`. This single rule routes all subdomains to SWAG, which handles per-service routing. The playbook manages DNS records for new services automatically via the Cloudflare API.

> The root domain (`your.domain`) is intentionally blocked at the reverse proxy level.

### 2. Ansible setup

1. Install Ansible: `pip install ansible` (or `brew install ansible` on macOS)
2. Install role dependencies: `ansible-galaxy install -r requirements.yml`
3. Ensure SSH access to your Ubuntu server
4. Copy `secret_example.yml` to `secret.yml` and fill in your values

## Running the playbook

Run the full playbook:
```bash
ansible-playbook run.yml
```

Run a specific part using tags (see `run.yml` for available tags):
```bash
ansible-playbook run.yml -t <tag>
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

> **Important**: The first time you connect a device, you must be on your **home WiFi** (so the app reaches headscale directly without Cloudflare in the path — the Tailscale control protocol can't traverse Cloudflare Tunnel). After the initial registration, the device can connect from anywhere.

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

New services are internal by default — accessible from your local network, through Tailscale, or via Authelia 2FA if exposed publicly.

### Configure the Homer dashboard

Homer files live at `~/homer` on the server. Edit them there directly via SSH.

See the [Homer documentation](https://github.com/bastienwirtz/homer/blob/main/docs/configuration.md) for configuration options.

## Local DNS override

For services to be reachable on your local network without going through Cloudflare, configure your local DNS server (e.g. Pi-hole, router) to resolve your domain directly to the server's local IP:

```
your.domain     → <server-local-ip>
*.your.domain   → <server-local-ip>
```

This is also **required for the initial Tailscale device registration**, since the Tailscale control protocol (TS2021) is not compatible with Cloudflare Tunnel's HTTP/2 proxying.

## Oops shell

A web-accessible SSH shell (`wetty`) is available at `https://oops.your.domain` (or whatever `webssh_subdomain` you set) for recovering the server when normal SSH is unavailable (lost key, ISP blocking port 22, sshd/firewall lockout). It is intentionally reachable over the internet through the Cloudflare Tunnel — it must work when you are remote — and is protected by two independent factors:

1. **Authelia two-factor** in front (the `*.your.domain` access-control rule)
2. The **system SSH user + password**, prompted by wetty itself (it holds no stored credentials and connects back to the host's sshd)

> **Scope:** this rescues cases where the OS/SSH is wedged but Docker is still running. It cannot help if Docker itself is down or the kernel has panicked — for that you need your cloud provider's serial console or IPMI.

## Two-factor authentication

Authelia uses **TOTP** (authenticator-app codes) as the second factor. SMTP is configured (`smtp_*` in `secret.yml`) so Authelia emails the TOTP enrollment link and security notifications.

> The per-login second factor is the **TOTP code** from your authenticator app — email/SMS-delivered login OTP is not an Authelia feature in this configuration. Email is the delivery channel for enrollment and notifications, not for the login code itself.

> Before applying the Authelia role, set a real `smtp_password` in `secret.yml` (for Gmail, an [App Password](https://support.google.com/accounts/answer/185833)). Switching to SMTP replaces the old filesystem notifier — the `show_2fa` helper no longer applies.

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
| Cloudflare Tunnel | `cloudflared` |

## Credits

Thanks to Wolfgang for his [ansible-easy-vpn](https://github.com/notthebee/ansible-easy-vpn) playbook, which this is largely based on.
