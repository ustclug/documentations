#!/bin/bash

ps -e -o s= -o comm= | grep -v '^S' | sort | uniq -c | awk '{printf("process,state=%s,name=%s count=%i\n",$2,$3,$1)}'
