#!/bin/sh
# Maintainer: Jan-Niklas Niebel <me@jnnkls.wtf> 

set -u

CONF="/etc/modprobe.d/dirtyfrag.conf"
MODULES="esp4 esp6 rxrpc"

if [ "$(id -u)" != "0" ]; then
  echo "Fehler: Dieses Script muss als root laufen."
  echo "Beispiel:"
  echo "curl -fsSL <url> | sudo sh"
  exit 1
fi

echo "Pruefe geladene Module..."

LOADED=""

for mod in $MODULES; do
  if grep -q "^${mod} " /proc/modules; then
    LOADED="$LOADED $mod"
  fi
done

if [ -z "$LOADED" ]; then
  echo "Keines der Module ist aktuell geladen: $MODULES"
  echo
  printf "Trotzdem dauerhaft blockieren? [y/N]: "
else
  echo "Geladene betroffene Module:$LOADED"
  echo
  printf "Module jetzt entladen und dauerhaft blockieren? [y/N]: "
fi

if [ -r /dev/tty ]; then
  read ans < /dev/tty
else
  echo
  echo "Keine interaktive Eingabe moeglich."
  exit 1
fi

case "$ans" in
  y|Y|yes|YES|Yes|j|J|ja|JA|Ja)

    echo
    echo "Schreibe $CONF ..."

    {
      printf 'install esp4 /bin/false\n'
      printf 'install esp6 /bin/false\n'
      printf 'install rxrpc /bin/false\n'
    } > "$CONF"

    echo "Versuche Module zu entladen..."
    rmmod esp4 esp6 rxrpc 2>/dev/null || true

    echo "Fertig."
    echo
    echo "Aktueller Status:"

    for mod in $MODULES; do
      if grep -q "^${mod} " /proc/modules; then
        echo "WARNUNG: $mod weiterhin geladen"
      else
        echo "OK: $mod nicht geladen"
      fi
    done

    echo
    echo "Fertig."
    ;;

  *)
    echo
    echo "Abgebrochen. Keine Aenderungen vorgenommen."
    exit 0
    ;;
esac