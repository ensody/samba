#!/usr/bin/env bash
set -euo pipefail

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

nmbd -D
exec smbd -F --no-process-group </dev/null
