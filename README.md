# VPN-DNS-playbook
Ansible playbook to setup a home VPN and DNS with 2fa 🥷

## It setups
- [WireGuard Easy](https://github.com/WeeJeWel/wg-easy) for VPN
- [AdGuardHome](https://github.com/AdguardTeam/AdGuardHome) and [Unbound](https://github.com/NLnetLabs/unbound) for DNS resolver, DNS-over-HTTPS and ad-blocking
- [Authelia](https://github.com/authelia/authelia) for two-factor authentication
- [DDclient](https://github.com/ddclient/ddclient) to update the Dynamic DNS
- [Nginx Proxy Manager](https://nginxproxymanager.com) for reverse proxy 
- [Portainer](https://github.com/portainer/portainer) to manage docker containers remotely 
- [Homer Dashboard](https://github.com/bastienwirtz/homer) to index our services
## Requirements 
- **Raspberry Pi 4** with **Ubuntu server** installed 
- Port `80`, `443` and the **wireguard port** opened in your NAT Router
- Get and domain at [NameCheap](https://www.namecheap.com/) and setup [Dynamic DNS](https://www.namecheap.com/support/knowledgebase/article.aspx/36/11/how-do-i-start-using-dynamic-dns/)

## Setup
- Install ansible `brew install ansible`
- Install ansible role dependencies `ansible-galaxy install -r requirements.yml`
- Establish `ssh` connection with your **Ubuntu server**
- Setup ansible vault:
  - Create a `secret.yml` file based on `secret_example.yml`, and fill it with real data
  - Encrypt it with `ansible-vault encrypt secret.yml`
- Setup secret_services vault (optional):
  - Create a `secret_services.yml` file base on `secret_services_example.yml`, and fill it with real data
  - Encrypt it with `ansible-vault encrypt secret_services.yml`

The each service should declare the following fields:
- `name` (mandatory) - the service name
- `url` (mandatory) - the service url on your local network
- `use_cors` (optional) - if the service should use CORS, false by default
- `external` (optional) - if the service should be externally exposed, false by default

Check `secret_services_example.yml` for an example

### Homer dashboard
To add services or configure homer, you need to `ssh` into your server. All the homer files are at `~/homer`.

Refer to [homer documentation](https://github.com/bastienwirtz/homer/blob/main/docs/configuration.md) for more information

## Run
- Run the hole playbook `ansible-playbook run.yml`
- Run parts of the playbook `ansible-playbook run.yml -t <tag>`, check **run.yml** to know the available tags

### Post-installation  
- After running the playbook set this server as the default DNS server of your NAT router
- Go to AdGuard and choose/add your DNS blocklists

## Two-factor authentication email
When setting up the 2fa for the first time. Authelia will inform you that it set you an email.   
This email will not be sent since there's no SMTP server :( 

To see this email. SSH into your VPN server and enter: `show_2fa`

## Debug
### Logs
Most of this runs on docker containers, to see the logs of them run: `sudo docker logs -f <container name>` .  
The container names are:
- Nginx Proxy Manager -> `nginx-proxy-manager`
- Authelia -> `authelia`
- AdGuardHome -> `adguard-unbound`
- WireGuard -> `wg-easy`     
- Portainer -> `portainer`
- Homer Dashboard -> `homer`                                                                                                          

## Thanks  
- Wolfgang for his [ansible-easy-vpn](https://github.com/notthebee/ansible-easy-vpn) playbook, from were I copy/past the most 
