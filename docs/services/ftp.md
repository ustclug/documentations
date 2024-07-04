# LUG FTP

Services: [FTP/FTPS](ftp://ftp.lug.ustc.edu.cn), [SFTP](sftp://ftp.lug.ustc.edu.cn), [HTTP](http://ftp.lug.ustc.edu.cn), [HTTPS](https://ftp.lug.ustc.edu.cn), [AFP](afp://ftp.lug.ustc.edu.cn)

Git repository: [ustclug/lugftp](https://github.com/ustclug/lugftp)

Docker Hub: [ustclug/ftp](https://hub.docker.com/r/ustclug/ftp/)

Server: vdp.s.ustclug.org (management ssh port 2222)

Theme: [h5ai](https://larsjung.de/h5ai/)

Deploy: [ftp.sh](https://github.com/ustclug/docker-run-script/blob/master/ftp/ftp.sh)

## Notes

1.  SSL cert is required when running LUG FTP.
2.  `ssh-keygen -A` is required to be manually run when initializing.
3.  About directory permission:
    1. It is strongly suggested to keep permission & owner metadata when backing up/restoring.
    2. Public folder root: set owner `root:root` and permission 0755.
    3. Subfolders: set owner to `1000:1000`. `_h5ai` and `wp-content` needs to be set to a different owner (misconfigured?). And `Incoming` shall be set to 0775.
4.  Do not use Google DNS in host, as China Mobile network may drop UDP packets to 8.8.8.8. A misconfigured DNS may lead to LDAP in container broken.
5.  Port 22 is delegated to the LUG FTP container for SFTP, and SSH access to the host has been reassigned to port 2222.

### Debian Bookworm kernel issue

After upgrading vdp.s to Bookworm, we found NFS frequently deadlocking. We traced this down to an issue with Linux 6.1. Linux 5.10 from Bullseye works fine, so we have pinned the kernel to 5.10 for the time being.

```yaml title="/etc/apt/preferences.d/linux-image-amd64"
Package: linux-image-amd64
Pin: release n=bullseye-security
Pin-Priority: 900
```

Then we manually installed the package from bullseye-security and removed the 6.1 kernel.
