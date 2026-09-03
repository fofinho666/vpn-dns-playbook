#!/bin/bash
set -u
. /etc/tunnel-monitor.env

STATE_DIR=/var/lib/tunnel-monitor
DOWN_SINCE="$STATE_DIR/down_since"
LAST_ALERT="$STATE_DIR/last_alert"
HOST=$(hostname)
mkdir -p "$STATE_DIR"

send_mail() {
  local subject="$1" body="$2"
  printf 'From: %s\nTo: %s\nSubject: %s\nDate: %s\n\n%s\n' \
    "$SMTP_SENDER" "$RECIPIENT" "$subject" "$(date -R)" "$body" |
  curl -sS --url "smtp://$SMTP_HOST:$SMTP_PORT" --ssl-reqd \
    --mail-from "$SMTP_SENDER" --mail-rcpt "$RECIPIENT" \
    --user "$SMTP_USERNAME:$SMTP_PASSWORD" -T -
}

relay_ok() {
  local code
  code=$(curl -s -m 15 -o /dev/null -w '%{http_code}' \
    --resolve "$CHECK_HOST:443:$VPS_HOST" "https://$CHECK_HOST/health")
  [ "$code" = "200" ]
}

tcp_open() {
  timeout 5 bash -c "exec 3<>/dev/tcp/$VPS_HOST/$1" 2>/dev/null && echo yes || echo no
}

if [ "${1:-}" = "--test" ]; then
  send_mail "[$HOST] tunnel-monitor test" "Test message from tunnel-monitor on $HOST." \
    && echo "sent to $RECIPIENT"
  exit
fi

now=$(date +%s)

if relay_ok; then
  if [ -f "$LAST_ALERT" ]; then
    down_for=$(( (now - $(cat "$DOWN_SINCE")) / 60 ))
    send_mail "[$HOST] VPS relay recovered" \
      "https://$CHECK_HOST is reachable again via $VPS_HOST after ${down_for} minutes."
  fi
  rm -f "$DOWN_SINCE" "$LAST_ALERT"
  exit 0
fi

[ -f "$DOWN_SINCE" ] || echo "$now" > "$DOWN_SINCE"
down_for=$(( (now - $(cat "$DOWN_SINCE")) / 60 ))
[ "$down_for" -ge "$DOWN_THRESHOLD_MIN" ] || exit 0

if [ -f "$LAST_ALERT" ] && [ $(( now - $(cat "$LAST_ALERT") )) -lt $(( REALERT_HOURS * 3600 )) ]; then
  exit 0
fi

body="https://$CHECK_HOST has been unreachable via $VPS_HOST for ${down_for} minutes.

VPS ssh port $VPS_SSH_PORT open: $(tcp_open "$VPS_SSH_PORT")
VPS https port 443 open:       $(tcp_open 443)
headscale-tunnel.service:      $(systemctl is-active headscale-tunnel)

Last tunnel log lines:
$(journalctl -u headscale-tunnel -n 5 --no-pager -o cat)

If the VPS is down, check the GCP console: https://console.cloud.google.com/compute/instances"

send_mail "[$HOST] VPS relay DOWN for ${down_for} min" "$body" && echo "$now" > "$LAST_ALERT"
