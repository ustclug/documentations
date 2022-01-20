# Generate 204

Service: 204.ustclug.org ([HTTP](http://204.ustclug.org) / [HTTPS](https://204.ustclug.org))

Server: (gateway)

Blog: [add-http-204-service](https://servers.ustclug.org/2016/08/add-http-204-service/)

### Configration

```nginx title="/etc/nginx/sites-available/204.ustclug.org"
server {
	listen      80;
	listen      [::]:80;
	listen      443 ssl http2;
	listen      [::]:443 ssl http2;
	server_name 204.ustclug.org;
	access_log  /var/log/nginx/204_access.log;
	error_log   /var/log/nginx/204_error.log;
	return 204;
}
```

The authoritative copy is on [LUG GitLab](https://git.lug.ustc.edu.cn/ustclug/nginx-config/blob/master/sites-available/204.ustclug.org).
