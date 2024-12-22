#!/bin/sh

if test $# -ne 2; then
  echo "Need exactly 2 arguments" >&2
  exit 1
fi

VMID="$1"
PHASE="$2"

case "$VMID" in
  201) SHARED_DIR=/mnt/docker2 ;;
  230) SHARED_DIR=/mnt/mirrorlog ;;
  *) exit 0 ;;
esac

NAME="virtiofsd-$VMID"
SOCKPATH="/run/$NAME.sock"

case "$PHASE" in
  pre-start)
    systemctl stop "$NAME".service || true
    rm -f "$SOCKPATH" "$SOCKPATH".pid

    systemd-run \
      --collect \
      --unit="$NAME" \
      /usr/libexec/virtiofsd \
      --syslog \
      --socket-path "$SOCKPATH" \
      --shared-dir "$SHARED_DIR" \
      --announce-submounts \
      --inode-file-handles=mandatory
      ;;
  pre-stop) ;;
  post-start) ;;
  post-stop) ;;
  *) echo "Unknown phase $PHASE" >&2; exit 1;;
esac
