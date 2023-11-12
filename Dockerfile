FROM ubuntu:rolling

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive

COPY entrypoint.sh /
RUN apt-get -y update && apt-get -y upgrade && apt-get install -y --no-install-recommends tini samba samba-vfs-modules smbclient ca-certificates && rm -rf /var/lib/apt/lists/* && userdel ubuntu

EXPOSE 137/udp 138/udp 139 445

CMD ["tini", "--", "bash", "/entrypoint.sh"]
