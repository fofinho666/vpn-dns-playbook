# VPN-DNS-Playbook

Ansible playbook to set up a home VPN and DNS server with two-factor authentication.

## What it sets up

| Service | Purpose |
|---|---|
| [WireGuard Easy](https://github.com/WeeJeWel/wg-easy) | VPN |
| [AdGuardHome](https://github.com/AdguardTeam/AdGuardHome) + [Unbound](https://github.com/NLnetLabs/unbound) | DNS resolver, DNS-over-HTTPS, and ad-blocking |
| [Authelia](https://github.com/authelia/authelia) | Two-factor authentication |
| [DDclient](https://github.com/ddclient/ddclient) | Dynamic DNS updates |
| [SWAG](https://github.com/linuxserver/docker-swag) | Reverse proxy |
| [Portainer](https://github.com/portainer/portainer) | Remote Docker container management |
| [Homer Dashboard](https://github.com/bastienwirtz/homer) | Service index dashboard |

## Requirements

- **Raspberry Pi 4** with **Ubuntu Server** installed
- The following ports open in your router's NAT settings:
  - `80` (TCP)
  - `443` (TCP)
  - Your chosen WireGuard port (UDP)
- A domain from [NameCheap](https://www.namecheap.com/) with [Dynamic DNS](https://www.namecheap.com/support/knowledgebase/article.aspx/36/11/how-do-i-start-using-dynamic-dns/) configured

## Setup

1. Install Ansible: `brew install ansible`
2. Install role dependencies: `ansible-galaxy install -r requirements.yml`
3. Establish an SSH connection to your Ubuntu server
4. Configure the Ansible vault:
   - Copy `secret_example.yml` to `secret.yml` and fill in your values
   - Encrypt it: `ansible-vault encrypt secret.yml`

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

1. Set this server as the default DNS server in your router
2. Open AdGuard and choose/add your DNS blocklists

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
| AdGuardHome | `adguard-unbound` |
| WireGuard | `wg-easy` |
| Portainer | `portainer` |
| Homer Dashboard | `homer` |

## Credits

Thanks to Wolfgang for his [ansible-easy-vpn](https://github.com/notthebee/ansible-easy-vpn) playbook, which this is largely based on.
