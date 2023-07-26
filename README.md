# VPN-DNS-playbook
Ansible playbook to setup a home VPN and DNS with 2fa 🥷

## It setups
- [WireGuard Easy](https://github.com/WeeJeWel/wg-easy) for VPN
- [AdGuardHome](https://github.com/AdguardTeam/AdGuardHome) and [Unbound](https://github.com/NLnetLabs/unbound) for DNS resolver, DNS-over-HTTPS and ad-blocking
- [Authelia](https://github.com/authelia/authelia) for two-factor authentication
- [DDclient](https://github.com/ddclient/ddclient) to update the Dynamic DNS
- [BunkerWeb](https://github.com/bunkerity/bunkerweb) for reverse proxy 
- [Portainer](https://github.com/portainer/portainer) to manage docker containers remotely 
## Requirements 
- **Raspberry Pi 4** with **Ubuntu server** installed 
- Port `80`, `443` and the **wireguard port** opened in your NAT Router
- Get and domain at [NameCheap](https://www.namecheap.com/) and setup [Dynamic DNS](https://www.namecheap.com/support/knowledgebase/article.aspx/36/11/how-do-i-start-using-dynamic-dns/)

## Setup
- Install ansible `brew install ansible`
- Install ansible role dependencies `ansible-galaxy install -r requirements.yml`
- Establish `ssh` connection with your **Ubuntu server**
- Setup ansible vault:
  - Rename `secret_example.yml` to `secret.yml` and fill it with real data
  - Encrypt it with `ansible-vault encrypt secret.yml`

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
- BunkerWeb -> `bunkerweb`
- Authelia -> `authelia`
- AdGuardHome -> `adguard-unbound`
- WireGuard -> `wg-easy`     
- Portainer -> `portainer`
- Homer Dashboard -> `homer`                                                                                                          

## Thanks  
- Wolfgang for his [ansible-easy-vpn](https://github.com/notthebee/ansible-easy-vpn) playbook, from were I copy/past the most 
