#!/bin/bash

port_list_input=${1//:/|}
port_list=${port_list_input:-"80|443"}
netstat -ntW | gawk '{print tolower($6),gensub(/^(.+):([^:]+)$/,"\\1 \\2","g",$4)}' | grep -P " ($port_list)\$" | sort | uniq -c | sort -k 4 -k 3 | awk "{printf(\"connection,protocol=tcp,port=%s,address=%s %s=%s\n\",\$4,\$3,\$2,\$1)}"
netstat -ntW | gawk '{print tolower($6),gensub(/^(.+):([^:]+)$/,"\\2","g",$4)}' | grep -P " ($port_list)\$" | sort | uniq -c | sort -k 3 | awk "{printf(\"connection,protocol=tcp,port=%s,address=any %s=%s\n\",\$3,\$2,\$1)}"
