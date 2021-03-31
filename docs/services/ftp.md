# LUG FTP

service: [FTP/FTPS](ftp://ftp.ustclug.org), [SFTP](sftp://ftp.ustclug.org), [HTTP](http://ftp.ustclug.org), [HTTPS](https://ftp.ustclug.org), [AFP](afp://ftp.ustclug.org)

Git Repository: [github.com/ustclug/lugftp](https://github.com/ustclug/lugftp)

DockerHub: [ustclug/ftp](https://hub.docker.com/r/ustclug/ftp/)

server: vdp.s.ustclug.org

theme: [h5ai](https://larsjung.de/h5ai/)

deploy: [ftp.sh](https://git.lug.ustc.edu.cn/ustclug/docker-run-script/blob/master/ftp/ftp.sh)

## Notes

1. SSL cert is required when running lugftp.
2. `ssh-keygen -A` is required to be manually run when initializing.
3. About directory permission:
   1. Public folder root: set owner to root:root, permission to dr-xr-xr-x
   2. Subfolders: set owner to 1000:1000. `_h5ai` and `wp-content` needs to be set to a different owner (misconfigured?). And `Incoming` shall be set to drwxrwxr-x.