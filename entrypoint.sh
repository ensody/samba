#!/usr/bin/env sh
set -euo pipefail

initialized=/var/.samba-initialized

mkdir -p /var/lib/samba/private

if [ ! -e "$initialized" ]; then
  if [ -e /scripts/one-time-init.sh ]; then
    sh -euo pipefail /scripts/one-time-init.sh
  fi
  touch "$initialized"
fi

if [ -e /scripts/prepare.sh ]; then
  sh -euo pipefail /scripts/prepare.sh
fi

rm -f /etc/samba/smb.conf
if [ -e /conf/smb.conf ]; then
  ln -s /conf/smb.conf /etc/samba/smb.conf
else
  ln -s /app/defaults/smb.conf /etc/samba/smb.conf
fi

if [ "${AVAHI_ENABLED:-}" != "false" ]; then
  { while true; do avahi-daemon || true; done } &
fi

nmbd -D
exec smbd -F --no-process-group </dev/null
