# Mirrors-specific monitoring

## Connections (Users online)

```toml title="/etc/telegraf/telegraf.d/exec.conf"
[[inputs.exec]]
  commands = [
    "/opt/monitor/telegraf/connection.sh 21:80:443:873:9418",
    "/opt/monitor/telegraf/nfacct.sh",
    "/opt/monitor/telegraf/process.sh",
  ]
  timeout = "5s"
  data_format = "influx"
```

```shell title="/opt/monitor/telegraf/connection.sh"
#!/bin/bash

port_list_input=${1//:/|}
port_list=${port_list_input:-"80|443"}
netstat -ntW | gawk '{print tolower($6),gensub(/^(.+):([^:]+)$/,"\\1 \\2","g",$4)}' | grep -P " ($port_list)\$" | sort | uniq -c | sort -k 4 -k 3 | awk "{printf(\"connection,protocol=tcp,port=%s,address=%s %s=%s\n\",\$4,\$3,\$2,\$1)}"
netstat -ntW | gawk '{print tolower($6),gensub(/^(.+):([^:]+)$/,"\\2","g",$4)}' | grep -P " ($port_list)\$" | sort | uniq -c | sort -k 3 | awk "{printf(\"connection,protocol=tcp,port=%s,address=any %s=%s\n\",\$3,\$2,\$1)}"
```

```shell title="/opt/monitor/telegraf/nfacct.sh"
#!/bin/bash

sudo nfacct list | awk '-F[ ,;]' "{printf(\"nfacct,object=%s bytes=%i,pkgs=%i\n\",\$11,\$8,\$4)}"
```

```shell title="/opt/monitor/telegraf/process.sh"
#!/bin/bash

ps -e -o s= -o comm= | grep -v '^S' | sort | uniq -c | awk '{printf("process,state=%s,name=%s count=%i\n",$2,$3,$1)}'
```
