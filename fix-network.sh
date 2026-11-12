#!/usr/bin/env bash
# Ubuntu Network Rescue - remet le réseau en marche (NetworkManager)
set -u

if [ "$EUID" -ne 0 ]; then
  echo "Lance ce script avec sudo : sudo ./fix-network.sh"
  exit 1
fi

echo "[1/6] Interfaces actuelles"
ip -br a

echo
echo "[2/6] Activation du réseau et du Wi-Fi"
nmcli networking on
nmcli radio wifi on
rfkill unblock all

echo
echo "[3/6] Redémarrage de NetworkManager"
systemctl restart NetworkManager
sleep 3

echo
echo "[4/6] Montée des interfaces physiques"
for iface in $(ls /sys/class/net); do
  case "$iface" in
    lo|docker*|veth*|br-*|virbr*) continue ;;
  esac
  ip link set "$iface" up 2>/dev/null && echo "  $iface -> UP"
done

echo
echo "[5/6] Connexion (DHCP) des interfaces Ethernet / Wi-Fi"
nmcli -t -f DEVICE,TYPE device | while IFS=: read -r dev type; do
  case "$type" in
    ethernet|wifi)
      echo "  Connexion de $dev ($type)..."
      nmcli device connect "$dev" 2>&1 | sed 's/^/    /'
      ;;
  esac
done
sleep 3

echo
echo "[6/6] Tests"
ip -br a
if ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1; then
  echo "✅ Connexion IP OK (8.8.8.8)"
  if ping -c 2 -W 3 google.com >/dev/null 2>&1; then
    echo "✅ DNS OK (google.com)"
  else
    echo "⚠️  DNS KO -> redémarrage de systemd-resolved"
    systemctl restart systemd-resolved
    sleep 2
    ping -c 2 -W 3 google.com >/dev/null 2>&1 && echo "✅ DNS OK" || echo "❌ DNS toujours KO"
  fi
else
  echo "❌ Pas de connexion. Vérifie le câble / le Wi-Fi, ou la section 'driver' du README."
fi
