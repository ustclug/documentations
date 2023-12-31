#!/bin/bash

sudo nfacct list | awk '-F[ ,;]' "{printf(\"nfacct,object=%s bytes=%ii,pkgs=%ii\n\",\$11,\$8,\$4)}"
