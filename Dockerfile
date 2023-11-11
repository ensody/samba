FROM ubuntu:rolling

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && apt-get -y upgrade && apt-get install -y --no-install-recommends samba samba-vfs-modules smbclient ca-certificates && rm -rf /var/lib/apt/lists/* && groupadd smb && useradd -d /tmp -s /sbin/nologin -G smb smbuser

EXPOSE 137/udp 138/udp 139 445
