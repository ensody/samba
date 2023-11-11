# Samba Docker image

This is a bare Samba container without any custom configuration system.

Why? All existing 3rd-party containers have their custom environment variable or YAML based config system. You might prefer a more raw solution.

Sample usage:

```sh
docker run --restart always -d --init --name samba --net=host -v /path/to/samba/data/:/data/ -v /path/to/samba/db:/var/lib/samba -v /path/to/samba/conf:/etc/samba ghcr.io/ensody/samba bash -c "groupadd smb; useradd -d /tmp -s /sbin/nologin -G smb smbuser; nmbd -D; exec smbd -F --no-process-group </dev/null"
```
