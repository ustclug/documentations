#!/bin/sh

if [ $# -ne 2 ]; then
  echo "Need exactly 2 arguments" >&2
  exit 1
fi

VMID="$1"
PHASE="$2"

[ "$VMID" -eq 230 ] || exit 0

NAME=virtiofsd-230
SOCKPATH="/run/$NAME.sock"

case "$PHASE" in
  pre-start)
    systemctl stop "$NAME".service
    rm -f "$SOCKPATH" "$SOCKPATH".pid

    systemd-run \
      --collect \
      --unit="$NAME" \
      /usr/libexec/virtiofsd \
      --syslog \
      --socket-path "$SOCKPATH" \
      --shared-dir /mnt/mirrorlog \
      --announce-submounts \
      --inode-file-handles=mandatory
      ;;
  pre-stop) ;;
  post-start) ;;
  post-stop) ;;
  *) echo "Unknown phase $PHASE" >&2; exit 1;;
esac
