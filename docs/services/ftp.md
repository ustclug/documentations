# LUG FTP

Services: [FTP/FTPS](ftp://ftp.lug.ustc.edu.cn), [SFTP](sftp://ftp.lug.ustc.edu.cn), [HTTP](http://ftp.lug.ustc.edu.cn), [HTTPS](https://ftp.lug.ustc.edu.cn)

- Provides some storage for LDAP users (works like home.ustc.edu.cn: `https://ftp.lug.ustc.edu.cn/~username/`).

Git repository: [ustclug/lugftp](https://github.com/ustclug/lugftp)

Docker Hub: [ustclug/ftp](https://hub.docker.com/r/ustclug/ftp/)

Server: `ftp.s.ustclug.org` (management SSH port 2222)

Theme: See page footer.

Deploy: [Docker Compose](https://github.com/ustclug/docker-run-script/blob/master/ftp/docker-compose.yml)

- Use `docker compose ls` to find the on-server path.
- Docker network `ustclug` is also managed by the Docker Compose project.

Note that the name `ustclug-master` is fixed by udev.
Inspect `/etc/udev/rules.d/*.rules` for details.

## Thumbnail service

Source: [YaTeX](https://github.com/ustclug/yatex)

Generates thumbnails for images in the form of `/path/to/image@1920x1080.jpg`, while also accepting an optional quality parameter.

Refer to [`config.yml`](https://github.com/ustclug/yatex/blob/master/config.yml) for the initial format, dimension & quality whitelists.

## Notes

1.  SSL cert is required when running LUG FTP.
2.  `ssh-keygen -A` is required to be manually run when initializing.
3.  About directory permission:
    1. It is strongly suggested to keep permission & owner metadata when backing up/restoring.
    2. Public folder root: set owner `root:root` and permission 0755.
    3. Subfolders: set owner to `1000:1000`. `_h5ai` and `wp-content` needs to be set to a different owner (misconfigured?). And `Incoming` shall be set to 0775.
4.  Port 22 is delegated to the LUG FTP container for SFTP, and SSH access to the host has been reassigned to port 2222.
