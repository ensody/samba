# Samba Docker image

This is a bare Samba Docker image giving you just the raw Samba server and a simple, but very direct configuration solution.

Note: Most existing Samba Docker images allow creating users and setting smb.conf values via environment variables or via a custom YAML based config system. This Docker image takes a more direct approach. You have to set up your own smb.conf (but you can use the template below) and you have to configure users with a normal shell script.

## Volumes

You'll need to mount these volumes:

* `/etc/samba`: Should contain your smb.conf.
* `/var/lib/samba`: Samba server's data
* `/scripts`: This can contain two scripts to prepare the container. Those scripts will be executed via `-euo pipefail` to ensure that script errors will actually trigger a failure instead of ignoring them.
  * `/scripts/one-time-init.sh`: will be executed exactly once per container creation and allows e.g. creating Linux users and groups before Samba is launchedl
  * `/scripts/prepare-sh`: executed every time before Samba is launched.
* One or more data volumes for your shares, as referenced in your `smb.conf` (e.g. `/data`).

## Zeroconf/Bonjour

Service discovery is not built into this image. You'll need, for example, Avahi either on the host or in a separate Docker container. If it's on the host you can create your service definition like this:

```sh
cat > /etc/avahi/services/smb.service <<EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">%h</name>
  <service>
    <type>_adisk._tcp</type>
    <txt-record>sys=waMa=0,adVF=0x100</txt-record>
    <txt-record>dk0=adVN=TimeMachine,adVF=0x82</txt-record>
  </service>
  <service>
    <type>_smb._tcp</type>
    <port>445</port>
  </service>
</service-group>
EOF
```

Note that the first service sets up TimeMachine discovery. If you don't use macOS you can optionally remove it, but it shouldn't hurt either.

## Example

You can modify and copy-paste this into your shell:

```sh
# Where to store all the data and configs
SAMBA_ROOT=/var/data/samba

mkdir -p "$SAMBA_ROOT"/{conf,data,db,scripts}

cat > "$SAMBA_ROOT"/scripts/one-time-init.sh <<EOF
# Add the primary user and group for host-level ownership (we also use force user in smb.conf).
# You can optionally also use this as your sole/primary Samba login or add more users.
groupadd -g 1000 smb
useradd -u 1000 -g smb smb

# Optional: set the password (or via: docker exec -it samba smbpasswd -a smb)
PASSWORD="yourpassword" echo -e "\$PASSWORD\n\$PASSWORD" | smbpasswd -a -s smb
EOF

cat > "$SAMBA_ROOT"/conf/smb.conf <<EOF
[global]
   server string = %h (Samba)

   log level = 1

   load printers = no
   printing = bsd
   printcap name = /dev/null
   disable spoolss = yes

   obey pam restrictions = yes
   pam password change = yes
   map to guest = bad user
   usershare allow guests = yes

   create mask = 0664
   force create mode = 0664
   directory mask = 0775
   force directory mode = 0775

   write list = @smb
   # Since we're in a Docker container we want to have proper ownership on the host
   force user = smb
   force group = smb
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes

   vfs objects = catia fruit streams_xattr

   fruit:metadata = stream
   fruit:nfs_aces = no
   fruit:delete_empty_adfiles = yes
   fruit:veto_appledouble = no
   fruit:wipe_intentionally_left_blank_rfork = yes

# A publicly discoverable share
[NAS]
   path = /data/nas
   writeable = no
   guest ok = yes

# A hidden share
[Hidden]
   path = /data/hidden
   browseable = no
   writeable = yes

# A share for TimeMachine backups (macOS)
[TimeMachine]
   path = /data/timemachine
   writeable = yes
   fruit:time machine = yes
   # If you want to limit the maximum backup size:
   #fruit:time machine max size = 1200G
EOF

docker run --restart always -d --name samba --net=host -v "$SAMBA_ROOT"/data/:/data/ -v "$SAMBA_ROOT"/db:/var/lib/samba -v "$SAMBA_ROOT"/conf:/etc/samba ghcr.io/ensody/samba
```
