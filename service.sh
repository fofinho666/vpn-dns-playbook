#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
RESET='\033[0m'
RED='\033[0;31m'
CYAN='\033[0;36m'

prompt()  { read -rp "  $1: " "$2"; }
confirm() { echo -en "  $1 [y/N]: "; read -r _ans; [[ "$_ans" =~ ^[Yy]$ ]]; }

echo
echo -e "  ${BOLD}${CYAN}Service Manager${RESET}"
echo
echo "  1) Add a service"
echo "  2) Remove a service"
echo
read -rp "  > " choice
echo

case $choice in
  1)
    prompt "Subdomain" subdomain
    prompt "Service URL (e.g. http://192.168.1.86:8080)" url
    echo

    if [[ -z "$subdomain" ]]; then
      echo -e "  ${RED}Error: subdomain cannot be empty${RESET}"; exit 1
    fi
    if [[ ! "$url" =~ ^https?:// ]]; then
      url="http://${url}"
    fi

    ansible-playbook add_new_service.yml \
      -e "subdomain=${subdomain}" \
      -e "service_url=${url}"
    ;;

  2)
    prompt "Subdomain to remove" subdomain
    echo

    if [[ -z "$subdomain" ]]; then
      echo -e "  ${RED}Error: subdomain cannot be empty${RESET}"; exit 1
    fi

    if confirm "Remove ${BOLD}${subdomain}${RESET}?"; then
      echo
      ansible-playbook remove_service.yml -e "subdomain=${subdomain}"
    else
      echo "  Cancelled."
    fi
    ;;

  *)
    echo -e "  ${RED}Invalid choice. Enter 1 or 2.${RESET}"; exit 1
    ;;
esac
