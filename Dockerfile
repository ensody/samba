FROM ghcr.io/ensody/avahi:latest

WORKDIR /app

COPY entrypoint.sh /
COPY smb.conf /app/defaults/
COPY smb.service /etc/avahi/services/
RUN addgroup -g 1000 smb && adduser -D -u 1000 -G smb smb && apk --no-cache upgrade && apk --no-cache add samba

EXPOSE 137/udp 138/udp 139 445

CMD ["tini", "--", "/entrypoint.sh"]
