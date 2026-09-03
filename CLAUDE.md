# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

An Ansible playbook that provisions two machines:
- **`server`** — home Ubuntu server running all services as Docker containers behind SWAG (nginx reverse proxy)
- **`vps`** — cheap public VPS (GCP e2-micro) running a raw-TCP socat relay so the server is reachable from the internet without open ports on the home network

## Running the playbooks

```bash
# Install dependencies first (once)
ansible-galaxy install -r requirements.yml

# Provision the VPS
ansible-playbook vps.yml

# Provision the home server
ansible-playbook server.yml

# Run a single role by tag
ansible-playbook server.yml -t <tag>
```

All secrets live in `secret.yml` (not committed). Copy `secret_example.yml` to start.

## Service management

```bash
./service.sh          # interactive: add or remove a service
# Or directly:
ansible-playbook add_new_service.yml -e subdomain=octoprint -e service_url=http://192.168.1.86:8080
ansible-playbook remove_service.yml -e subdomain=octoprint
```

New services get an nginx proxy-conf in `docker_dir/swag/nginx/proxy-confs/` that restricts access to `local_ip_range` and `tailscale_ip_range` — i.e. internal by default.

## Architecture

### Traffic flow (public HTTPS)

```
Browser → Cloudflare DNS (unproxied A record) → VPS :443
       → socat → autossh reverse tunnel (127.0.0.1:8443 on VPS → SWAG :443 on LAN)
       → SWAG → Docker service
```

The relay is raw TCP (not HTTP proxied) because the Tailscale TS2021 protocol is incompatible with Cloudflare's HTTP/2 proxy. Cloudflare DNS records must stay unproxied (orange cloud OFF).

### Role ordering in `server.yml`

The roles have hard dependency ordering:
- `tailscale` must run **after** `swag` — it connects to `https://<headscale_subdomain>.<domain>`, which SWAG must already be serving
- `dns_relay` must run **after** `tailscale` — dnsmasq binds to the Tailscale node IP (`100.64.0.1`)

### Docker network

All containers share a single bridge network (`docker_network`, subnet `10.8.2.0/24`). Static IPs are defined in `inventory.yml`. The gateway is `10.8.2.1`.

The `docker` role deploys a `tailscale-docker-nat-fix` systemd service and two iptables `ACCEPT` rules at the top of the `nat` table's `POSTROUTING` chain (above the `-j ts-postrouting` jump) — one for `tailscale_ip_range` and one for `local_ip_range`, both with destination `docker_network_subnet`. They preserve the real client source IP for tailnet/LAN traffic reaching the containers; without them Tailscale's `ts-postrouting` MASQUERADE rewrites the source to `10.8.2.1`, which is in neither allow range, so SWAG returns 403 on all internal services. The rules **must** live in `POSTROUTING`, not `ts-postrouting`: tailscaled flushes and rebuilds `ts-postrouting` on every reconfig (network change, `tailscale set`, exit-node toggle), which silently drops anything inserted there, but it never touches the main `POSTROUTING` chain. Internet-bound exit-node traffic doesn't match these rules (destination isn't the docker subnet), so it still falls through to the `ts-postrouting` MASQUERADE and the exit node keeps working.

### DNS relay

`dnsmasq` runs on the server, listening only on the Tailscale node IP (`100.64.0.1`). It forwards all DNS queries to `local_dns` (the LAN DNS server). Tailscale clients use this relay as their DNS server so they can resolve internal hostnames from off-LAN.

The `ufw` role opens port 53 from `tailscale_ip_range` for this to work.

### Headscale DERP map

`roles/headscale/files/derp.yaml` is a pinned static copy of the Tailscale DERP map. Without it, Headscale would try to fetch the map from `controlplane.tailscale.com` at startup, which is DNS-sinkholed on the LAN and causes a crash-loop. To refresh it, fetch `https://controlplane.tailscale.com/derpmap/default` from a non-filtered host and update the file.

### Tunnel monitoring

The `tunnel_monitor` role installs a systemd timer on the server that fetches `https://<headscale_subdomain>.<domain>/health` through the VPS IP every 5 minutes. After 15 minutes of failure it emails `smtp_sender` with port checks and the last tunnel log lines, re-alerts every 24h, and mails again on recovery. `tunnel-monitor --test` on the server sends a test email. Thresholds are in `roles/tunnel_monitor/defaults/main.yml`.

### VPS DNS management

The `vps_relay` role manages Cloudflare DNS records directly via the Cloudflare API. It creates unproxied A records pointing `auth.<domain>`, `<headscale_subdomain>.<domain>`, and `<webssh_subdomain>.<domain>` to the VPS IP.

### Service access patterns

`add_new_service.yml` (and `service.sh`) support two access modes, both LAN + Tailscale IP restricted:

- **Internal only** (default) — reachable on LAN or via Tailscale, no additional auth
- **Internal + Authelia 2FA** — same IP restriction, plus Authelia gate; pass `-e authelia_protected=true` or answer yes in `service.sh`

To expose a service to the internet instead (no IP restriction), manually edit the generated nginx conf: remove the `allow`/`deny` block and add Authelia in front — see `roles/swag/templates/nginx/proxy-confs/oops.subdomain.conf` for the snippet placement. Then add an unproxied A record for the subdomain pointing at the VPS IP; the `vps_relay` role only manages the three records listed above.

## Key variables

Defined in `inventory.yml` (structural, not secret):
- `docker_dir` — `/opt/docker` (root of all container config and data)
- `docker_ip_range` / `docker_gateway` — Docker bridge network
- `local_ip_range` — `192.168.0.0/16`
- `tailscale_ip_range` — `100.64.0.0/10`
- `tailscale_node_ip` — `100.64.0.1` (server's Tailscale IP, dnsmasq listens here)

Defined in `secret.yml` (sensitive, not committed):
- `host`, `user`, `ssh_port` — home server SSH target
- `vps_host`, `vps_user`, `vps_ssh_port` — VPS SSH target
- `domain`, `headscale_subdomain`, `webssh_subdomain`
- `cloudflare_api_token`, `headscale_api_key`, `tailscale_preauth_key`, `headplane_cookie_secret`
- `authelia_password`, `jwt_secret`, `session_secret`, `storage_encryption_key`
- `smtp_*` — Authelia email delivery
- `local_dns` — LAN DNS server IP
