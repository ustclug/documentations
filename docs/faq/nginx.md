# Nginx 相关配置

## 使用 Git 同步配置，但需要 host-specific 的配置

1. Nginx 自带一个变量 `$hostname` 可以在合适的地方用来 if 或者 map，但是在这个办法不顶用的时候（例如，[`resolver` 不支持变量][ngx-2128]）就只能用下面这个笨办法了。
2. 把需要 host-specific 的那个文件加入 `.gitignore`，然后在合适的位置留下一个 README。

  [ngx-2128]: https://trac.nginx.org/nginx/ticket/2128

## 文件打开数大小限制

在默认设置中，nginx 的最大文件打开数上限并不大。当有大量访问时，文件打开数可能会超过限额，导致网站响应缓慢。在新配置服务器时，这一项设置很容易被忽略掉。

解决方法：

1. `sudo systemctl edit nginx.service`（部分机器上的服务名可能为 `openresty.service`）
2. 在打开的 override 文件的 `[Service]` 下方添加 `LimitNOFILE=524288`（视情况这个值可以相应调整）

## 关于 gateway 配置中的 `/tmp/mem` 路径

!!! tip "更新"

    我们已不再在 nginx.conf 里使用 `/tmp/mem` 了，以下内容仅作存档。

错误表现是 `systemctl start nginx.service` 失败，使用 status 或 journalctl 可以看到以下信息：

    [emerg] mkdir() "/tmp/mem/nginx_temp" failed (2: No such file or directory)

这是因为[我们的 `nginx.conf`](https://git.lug.ustc.edu.cn/ustclug/nginx-config/-/blob/d6f9bf7443117b4d6ebe0a566dc6bb48753a8f58/nginx.conf#L34) 中钦点了 `proxy_temp /tmp/mem/nginx_temp`，而 `/tmp/mem` 是我们自己建的一个 tmpfs 挂载点，它不是任何发行版的默认配置，所以新装的系统如果直接 pull 了这份 nginx config 就会报以上错误。

（使用 `/tmp/mem` 的原因是，由于 nginx 反代需要频繁读写临时文件，为了减少磁盘 IO 占用，故将其临时文件放入内存中）

正确的解决方法是补上对应的 fstab 行：

    tmpfs   /tmp/mem    tmpfs   0   0

如果创建/挂载了 /tmp/mem 后，启动仍然出错，则需要检查 openresty.service/nginx.service 文件中是否包含 `PrivateTmp=yes`。如果包含，则需要 `systemctl edit`，将此项设置为 `false`。

!!! warning "fstab 与 systemd"

    调整 fstab 之后，需要执行 `systemctl daemon-reload`，否则 systemd 可能会在第二日凌晨挂载已被注释的磁盘项。

## OpenResty

### Lua 相关

![Order of Lua Nginx Module Directives](https://cloud.githubusercontent.com/assets/2137369/15272097/77d1c09e-1a37-11e6-97ef-d9767035fc3e.png)

这里关注三个相关的步骤：`access_by`, `log_by` 和 `header_filter_by`，以及 `ngx.ctx` 和 `ngx.var` 的注意事项。

测试用 server 块：

```nginx
server {
	listen 80 default_server;
	listen [::]:80 default_server;

	root /var/www/html;

	index index.html index.htm index.nginx-debian.html;

	server_name _;

	set $testvar "";
	access_by_lua_file /etc/nginx/lua/access.lua;
	header_filter_by_lua_file /etc/nginx/lua/header_filter.lua;
	log_by_lua_file /etc/nginx/lua/log.lua;

	location / {
		try_files $uri $uri/ =404;
	}

	location /lua-test0 {
		return 302 /lua-test1;
	}

	location /lua-test1 {
        return 200;
	}

	location /lua-test2 {
		try_files $uri $uri/ @internal1;
	}

	location @internal1 {
		return 418;
	}
}
```

三个 lua:

```lua title="/etc/nginx/lua/access.lua"
local ctx = ngx.ctx
ctx.testvar = "testvar"
ngx.var.testvar = "testvar"
ngx.log(ngx.ERR, "ctx ", ctx.testvar)
ngx.log(ngx.ERR, "var ", ngx.var.testvar)
```

```lua title="/etc/nginx/lua/header_filter.lua"
local ctx = ngx.ctx

ngx.log(ngx.ERR, "ctx ", ctx.testvar)
ngx.log(ngx.ERR, "var ", ngx.var.testvar)
```

```lua title="/etc/nginx/lua/log.lua"
local ctx = ngx.ctx

ngx.log(ngx.ERR, "ctx ", ctx.testvar)
ngx.log(ngx.ERR, "var ", ngx.var.testvar)
```

#### rewrite/return 与 access_by

访问 localhost/lua-test0 或者 localhost/lua-test1，没有 access.lua 的输出：

```log
2024/07/22 02:50:16 [error] 9465#9465: *12 [lua] header_filter.lua:3: ctx nil, client: 127.0.0.1, server: _, request: "GET /lua-test0 HTTP/1.1", host: "localhost"
2024/07/22 02:50:16 [error] 9465#9465: *12 [lua] header_filter.lua:4: var nil, client: 127.0.0.1, server: _, request: "GET /lua-test0 HTTP/1.1", host: "localhost"
2024/07/22 02:50:16 [error] 9465#9465: *12 [lua] log.lua:3: ctx nil while logging request, client: 127.0.0.1, server: _, request: "GET /lua-test0 HTTP/1.1", host: "localhost"
2024/07/22 02:50:16 [error] 9465#9465: *12 [lua] log.lua:4: var nil while logging request, client: 127.0.0.1, server: _, request: "GET /lua-test0 HTTP/1.1", host: "localhost"
```

如果访问 localhost/somefile，是有输出的：

```log
2024/07/22 03:03:42 [error] 9628#9628: *19 [lua] access.lua:4: ctx testvar, client: 127.0.0.1, server: _, request: "GET /somefile HTTP/1.1", host: "localhost"
2024/07/22 03:03:42 [error] 9628#9628: *19 [lua] access.lua:5: var testvar, client: 127.0.0.1, server: _, request: "GET /somefile HTTP/1.1", host: "localhost"
2024/07/22 03:03:42 [error] 9628#9628: *19 [lua] header_filter.lua:3: ctx testvar, client: 127.0.0.1, server: _, request: "GET /somefile HTTP/1.1", host: "localhost"
2024/07/22 03:03:42 [error] 9628#9628: *19 [lua] header_filter.lua:4: var testvar, client: 127.0.0.1, server: _, request: "GET /somefile HTTP/1.1", host: "localhost"
2024/07/22 03:03:42 [error] 9628#9628: *19 [lua] log.lua:3: ctx testvar while logging request, client: 127.0.0.1, server: _, request: "GET /somefile HTTP/1.1", host: "localhost"
2024/07/22 03:03:42 [error] 9628#9628: *19 [lua] log.lua:4: var testvar while logging request, client: 127.0.0.1, server: _, request: "GET /somefile HTTP/1.1", host: "localhost"
```

**这是因为 `return` 语句发生在 `rewrite` 阶段，因此跳过了 `access` 阶段，`access_by_lua_block` 就没有被执行**。因此 Content phase 中的程序不能假设 access_by 肯定被执行了。

#### `ngx.ctx`

<https://github.com/openresty/lua-nginx-module?tab=readme-ov-file#ngxctx>

支持任意 lua 数据结构的，与单独 request 绑定的状态变量。同时也不需要像 `ngx.var` 一样提前 `set`。

!!! warning "小心内部跳转"

    > Internal redirects (triggered by nginx configuration directives like `error_page`, `try_files`, `index` and etc) will destroy the original request `ngx.ctx` data (if any) and the new request will have an empty ngx.ctx table.

访问 localhost/lua-test2（假设前面的 `try_files` 失败）：

```log
2024/07/22 03:10:15 [error] 9630#9630: *22 [lua] access.lua:4: ctx testvar, client: 127.0.0.1, server: _, request: "GET /lua-test2 HTTP/1.1", host: "localhost"
2024/07/22 03:10:15 [error] 9630#9630: *22 [lua] access.lua:5: var testvar, client: 127.0.0.1, server: _, request: "GET /lua-test2 HTTP/1.1", host: "localhost"
2024/07/22 03:10:15 [error] 9630#9630: *22 [lua] header_filter.lua:3: ctx nil, client: 127.0.0.1, server: _, request: "GET /lua-test2 HTTP/1.1", host: "localhost"
2024/07/22 03:10:15 [error] 9630#9630: *22 [lua] header_filter.lua:4: var testvar, client: 127.0.0.1, server: _, request: "GET /lua-test2 HTTP/1.1", host: "localhost"
2024/07/22 03:10:15 [error] 9630#9630: *22 [lua] log.lua:3: ctx nil while logging request, client: 127.0.0.1, server: _, request: "GET /lua-test2 HTTP/1.1", host: "localhost"
2024/07/22 03:10:15 [error] 9630#9630: *22 [lua] log.lua:4: var testvar while logging request, client: 127.0.0.1, server: _, request: "GET /lua-test2 HTTP/1.1", host: "localhost"
```

这个问题对一些需要在 access 中做一些事情，将状态存储在 `ngx.ctx` 中，然后在 header_filter 或者 log 中取消对应效果的逻辑（例如 [resty.limit.conn](https://github.com/openresty/lua-resty-limit-traffic/blob/master/lib/resty/limit/conn.md) 在访问的文件*当前*不存在的情况下）来说是致命的。

#### `ngx.var`

<https://github.com/openresty/lua-nginx-module?tab=readme-ov-file#ngxvarvariable>

使用有一些麻烦：

- 性能相比于 `ngx.ctx` 来说低一些，官方文档不建议将 `ngx.var` 使用到关键路径上。
- 需要提前定义变量。
- 只能赋值数字或者字符串，赋值 table 可能不会直接报错，但是实际上不工作。

但是相比于 `ngx.ctx`，最大的优势就是即使经过了 internal redirection，`ngx.var` 的内容也会保留。

由于 `ngx.var` 其本身**不**适合存储复杂的结构，第三方模块 ([lua-resty-ctxdump](https://github.com/tokers/lua-resty-ctxdump/), 2-clause BSD license) 处理这个问题的做法是：将实际内容保存在模块内部的 memo 表中，而需要存储在 ngx.var 里面的只是 memo 表的 key（数字）。

#### 模块管理

OpenResty 官方推荐使用 opm (`openresty-opm`) 管理模块。手动维护模块的话需要自行处理配置，对应的是 [`lua_package_path`](https://github.com/openresty/lua-nginx-module?tab=readme-ov-file#lua_package_path)（`http` 块内，分号分割路径，最后 `;;` 代表内置的原始路径）。

例如：

```nginx
lua_package_path "/etc/nginx/lua/module/?.lua;;";
```

以 <https://github.com/tokers/lua-resty-ctxdump/blob/master/lib/resty/ctxdump.lua> 为例，下载到 `/etc/nginx/lua/module/` 下之后，就可以在其他 lua 文件内使用了：

```lua title="/etc/nginx/lua/access.lua"
local ctxdump = require "ctxdump"
local ctx = ngx.ctx
ctx.testvar = {foo = "bar", num = 42}
-- 需要 set $ctx_ref "";
ngx.var.ctx_ref = ctxdump.stash_ngx_ctx()
ngx.log(ngx.ERR, "ctx foo ", ctx.testvar.foo)
ngx.log(ngx.ERR, "ctx num ", ctx.testvar.num)
ngx.log(ngx.ERR, "var ctx_ref ", ngx.var.ctx_ref)
```

```lua title="/etc/nginx/lua/log.lua"
local ctxdump = require "ctxdump"
ngx.log(ngx.ERR, "var ctx_ref ", ngx.var.ctx_ref)
ngx.ctx = ctxdump.apply_ngx_ctx(ngx.var.ctx_ref)
local ctx = ngx.ctx
ngx.log(ngx.ERR, "ctx foo ", ctx.testvar.foo)
ngx.log(ngx.ERR, "ctx num ", ctx.testvar.num)
```

如果没有找到文件，报错信息中会包含所有尝试过的路径。

#### 代码复用与模块编写

最简单的代码复用的方法是使用 `loadfile()` 函数，这样几乎不需要修改代码内容。

```lua
local f = loadfile("/etc/nginx/lua/somefile.lua")
if f then
    f()
else
    ngx.log(ngx.ERR, "failed to load somefile.lua")
end
```

但是这么做是没有 JIT 缓存的，意味着每个请求都需要整个加载一遍对应的原始 lua 代码。一个基本的模块类似于下面这样：

```lua
local _M = {}

local function some_internal_func(a)
    return a + a
end

function _M.f1(a, b)
    local aa = some_internal_func(a)
    local bb = some_internal_func(b)
    return aa + bb
end

return _M
```
