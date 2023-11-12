#!/usr/bin/env bash
set -euxo pipefail

initialized=/var/.samba-initialized

if [ ! -e "$initialized" ]; then
  if [ -e /scripts/one-time-init.sh ]; then
    bash -euo pipefail /scripts/one-time-init.sh
  fi
  touch "$initialized"
fi

if [ -e /scripts/prepare.sh ]; then
  bash -euo pipefail /scripts/prepare.sh
fi

rm -f /etc/samba/smb.conf
if [ -e /conf/smb.conf ]; then
  ln -s /conf/smb.conf /etc/samba/smb.conf
else
  ln -s /app/defaults/smb.conf /etc/samba/smb.conf
fi

nmbd -D
exec smbd -F --no-process-group </dev/null
