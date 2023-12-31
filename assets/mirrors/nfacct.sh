#!/bin/bash

sudo nfacct list | awk '-F[ ,;]' "{printf(\"nfacct,object=%s bytes=%i,pkgs=%i\n\",\$11,\$8,\$4)}"
