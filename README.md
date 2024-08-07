# Samba Docker image

This is a bare Samba Docker image giving you just the raw Samba server and a simple, but very direct configuration solution.

Note: Most existing Samba Docker images allow creating users and setting smb.conf values via environment variables or via a custom YAML based config system. This Docker image takes a more direct approach. You have to set up your own smb.conf (or extend the default) and you have to configure users with a normal shell script.

The CI automatically checks for updates (e.g. security fixes) several times per day and publishes a new image only when necessary. So, this image could be used with podman-auto-update or Watchtower.

## Defaults

There's a default `smb` user/group with UID/GID 1000. You can either go with the defaults or use the `one-time-init.sh` script to delete/replace that user. The same script can also be used to add more users.

There's a [default smb.conf](https://github.com/ensody/samba/blob/main/smb.conf). You can add your shares and customizations via an `extra.conf` file or define a custom `smb.conf` to override the defaults.

When using these defaults you can simplify your shares to a minimum (more examples are shown below):

```
[MyShare]
   path = /data/myshare
   write list = @smb
```

Zeroconf is active by default. You can turn it off by setting the environment variable `AVAHI_ENABLED=false`. If you want to control Avahi separately you can use the [avahi](https://github.com/ensody/avahi) Docker image which also contains an SMB example in the README.

## Volumes

You'll need to mount these volumes:

* `/conf`: Should contain your `extra.conf` if you want to use the default `smb.conf`. Alternatively, provide the complete `smb.conf` instead.
* `/var/lib/samba`: Samba server's data
* (optional) `/scripts`: This can contain shell scripts to prepare the container. Those scripts will be executed via `-euo pipefail` to ensure that script errors will actually trigger a failure instead of ignoring them.
  * `/scripts/one-time-init.sh`: Will be executed exactly once per container creation and allows e.g. creating Linux users and groups before Samba is launched.
  * `/scripts/prepare.sh`: Executed every time before Samba is launched.
* One or more data volumes for your shares, as referenced in your `smb.conf` (e.g. `/data`).

## Example

You can modify and copy-paste this into your shell:

```sh
# Where to store all the data and configs
SAMBA_ROOT=/var/data/samba

mkdir -p "$SAMBA_ROOT"/{conf,data,db,scripts}

# Optional script to set up users and passwords
cat > "$SAMBA_ROOT/scripts/one-time-init.sh" <<'EOF'
# Optional: set the "smb" user's password (alternative: docker exec -it samba smbpasswd -a smb)
#PASSWORD="yourpassword" echo -e "$PASSWORD\n$PASSWORD" | smbpasswd -a -s smb

# Optional: Add more groups and users.
#addgroup -g 1001 extragroup
#adduser -D -u 1001 -G extragroup extrauser
#PASSWORD="extrauserpassword" echo -e "$PASSWORD\n$PASSWORD" | smbpasswd -a -s extrauser
EOF

# Configure shares and additonal settings
cat > "$SAMBA_ROOT/conf/extra.conf" <<'EOF'
# This allows everyone in the smb group to write to all shares.
# Alternatively you can configure this for every share separately.
write list = @smb

# A publicly discoverable share that is only accessible (read and write) by the smb group
[NAS]
   path = /data/nas

# A share with full read-write access for guests
[Public]
   path = /data/public
   writeable = yes
   guest ok = yes

# A hidden share (you must explicitly specify the full path when connecting)
[Hidden]
   path = /data/hidden
   browseable = no

# A share for Time Machine backups (macOS)
[TimeMachine]
   path = /data/timemachine
   fruit:time machine = yes
   # If you want to limit the maximum backup size:
   #fruit:time machine max size = 1200G
EOF

docker run --restart always -d --name samba --net=host -v "$SAMBA_ROOT/data/:/data/" -v "$SAMBA_ROOT/db:/var/lib/samba" -v "$SAMBA_ROOT/conf:/conf" -v "$SAMBA_ROOT/scripts:/scripts" ghcr.io/ensody/samba:latest
```
