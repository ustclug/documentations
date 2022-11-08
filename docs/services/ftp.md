# LUG FTP

Services: [FTP/FTPS](ftp://ftp.ustclug.org), [SFTP](sftp://ftp.ustclug.org), [HTTP](http://ftp.ustclug.org), [HTTPS](https://ftp.ustclug.org), [AFP](afp://ftp.ustclug.org)

Git repository: [ustclug/lugftp](https://github.com/ustclug/lugftp)

Docker Hub: [ustclug/ftp](https://hub.docker.com/r/ustclug/ftp/)

Server: vdp.s.ustclug.org (management ssh port 2222)

Theme: [h5ai](https://larsjung.de/h5ai/)

Deploy: [ftp.sh](https://git.lug.ustc.edu.cn/ustclug/docker-run-script/blob/master/ftp/ftp.sh)

## Notes

1.  SSL cert is required when running LUG FTP.
2.  `ssh-keygen -A` is required to be manually run when initializing.
3.  About directory permission:
    1. It is strongly suggested to keep permission & owner metadata when backing up/restoring.
    2. Public folder root: set owner `root:root` and permission 0755.
    3. Subfolders: set owner to `1000:1000`. `_h5ai` and `wp-content` needs to be set to a different owner (misconfigured?). And `Incoming` shall be set to 0775.
4.  Do not use Google DNS in host, as China Mobile network may drop UDP packets to 8.8.8.8. A misconfigured DNS may lead to LDAP in container broken.
5.  Port 22 is delegated to the LUG FTP container for SFTP, and SSH access to the host has been reassigned to port 2222.
