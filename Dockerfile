FROM ubuntu:rolling

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive

COPY entrypoint.sh /
COPY smb.conf /app/defaults/
RUN userdel ubuntu && groupadd -g 1000 smb && useradd -u 1000 -g smb smb && apt-get -y update && apt-get -y upgrade && apt-get install -y --no-install-recommends tini samba samba-vfs-modules smbclient ca-certificates && rm -rf /var/lib/apt/lists/*

EXPOSE 137/udp 138/udp 139 445

CMD ["tini", "--", "bash", "/entrypoint.sh"]
