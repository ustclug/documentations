#!/bin/sh

ps -e -o s= -o comm= |
  grep -v '^S ' |
  sed 's|/.*$|/|g' |
  sort | uniq -c |
  awk '{printf("process,state=%s,name=%s count=%ii\n",$2,$3,$1)}'
