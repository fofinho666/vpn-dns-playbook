# VPN-DNS-Playbook

Ansible playbook to set up a home VPN server with two-factor authentication and secure remote access via Cloudflare Tunnel (works behind CGNAT — no open ports required).

## What it sets up

| Service | Purpose |
|---|---|
| [WireGuard Easy](https://github.com/WeeJeWel/wg-easy) | VPN |
| [Authelia](https://github.com/authelia/authelia) | Two-factor authentication |
| [SWAG](https://github.com/linuxserver/docker-swag) | Reverse proxy + Let's Encrypt certs |
| [cloudflared](https://github.com/cloudflare/cloudflared) | Cloudflare Tunnel (bypasses CGNAT) |
| [Portainer](https://github.com/portainer/portainer) | Remote Docker container management |
| [Homer Dashboard](https://github.com/bastienwirtz/homer) | Service index dashboard |

## Requirements

- A machine running **Ubuntu Server** (PC or Raspberry Pi 4+)
- Your chosen WireGuard port open in your router's NAT settings (UDP)
- A domain managed on **Cloudflare DNS** (free account)
- A Cloudflare API token with `Zone:DNS:Edit` permission
- A Cloudflare Tunnel token (Zero Trust → Networks → Tunnels)

> No ports 80/443 forwarding needed — all web traffic flows through the Cloudflare Tunnel.

## Setup

### 1. Cloudflare account

1. Create a free account at [cloudflare.com](https://cloudflare.com) and add your domain
2. In your domain registrar, point the nameservers to the two Cloudflare assigns (wait ~30 min)
3. In **My Profile → API Tokens → Create Token**, use the "Edit zone DNS" template scoped to your domain — save the token as `cloudflare_api_token` in `secret.yml`
4. In **Zero Trust → Networks → Tunnels → Create a tunnel**, choose Cloudflared and copy the token — save it as `cloudflare_tunnel_token` in `secret.yml`
5. In the tunnel's **Public Hostnames** tab, add one entry per service (all pointing to `https://swag:443` with **No TLS Verify** enabled):

| Subdomain | Domain | Service |
|---|---|---|
| `auth` | your domain | `https://swag:443` |
| `portainer` | your domain | `https://swag:443` |
| `wg` | your domain | `https://swag:443` |

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

### Post-installation

## Service Management

### Add a service

```bash
ansible-playbook add_new_service.yml -e service_url=<url> -e subdomain=<subdomain> -e external=<true|false>
```

The `external` flag controls access:
- `false` (default) — only accessible through VPN or local network
- `true` — accessible from the internet, protected by Authelia 2FA

Examples:
```bash
# Internal service (VPN/local only)
ansible-playbook add_new_service.yml -e service_url=http://192.168.1.86 -e subdomain=octoprint

# External service (internet-accessible with 2FA)
ansible-playbook add_new_service.yml -e service_url=http://192.168.1.87 -e subdomain=nextcloud -e external=true
```

### Remove a service

```bash
ansible-playbook remove_service.yml -e subdomain=<subdomain>
```

Example:
```bash
ansible-playbook remove_service.yml -e subdomain=octoprint
```

This will:
- Remove the subdomain config from SWAG
- Back up and delete the proxy configuration file
- Restart SWAG to apply changes

### Configure the Homer dashboard

Homer files live at `~/homer` on the server. Edit them there directly via SSH.

See the [Homer documentation](https://github.com/bastienwirtz/homer/blob/main/docs/configuration.md) for configuration options.

## Two-factor authentication

On first login, Authelia will try to send you a setup email. Since there is no SMTP server configured, the email is not actually sent.

To retrieve it, SSH into the server and run:
```bash
show_2fa
```

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
| WireGuard | `wg-easy` |
| Portainer | `portainer` |
| Homer Dashboard | `homer` |
| Cloudflare Tunnel | `cloudflared` |

## Credits

Thanks to Wolfgang for his [ansible-easy-vpn](https://github.com/notthebee/ansible-easy-vpn) playbook, which this is largely based on.
