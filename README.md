# 🛟 Ubuntu Network Rescue

Guide pour **remettre le réseau en marche sur Ubuntu en ligne de commande** (filaire ou Wi-Fi), étape par étape.

> Testé sur Ubuntu avec NetworkManager (Desktop 20.04 / 22.04 / 24.04). Sur Ubuntu Server, voir la section [Netplan](#-ubuntu-server-netplan).

---

## 📋 Sommaire

1. [Diagnostic rapide](#1--diagnostic-rapide)
2. [Relancer NetworkManager](#2--relancer-networkmanager)
3. [Activer le réseau et le Wi-Fi](#3--activer-le-réseau-et-le-wi-fi)
4. [Monter l'interface](#4--monter-linterface)
5. [Obtenir une IP (DHCP)](#5--obtenir-une-ip-dhcp)
6. [Tester la connexion](#6--tester-la-connexion)
7. [Problème de DNS](#7--problème-de-dns)
8. [Se connecter au Wi-Fi en CLI](#8--se-connecter-au-wi-fi-en-cli)
9. [L'interface n'apparaît pas (driver)](#9--linterface-napparaît-pas-driver)
10. [Ubuntu Server (Netplan)](#-ubuntu-server-netplan)
11. [Script automatique](#-script-automatique)

---

## 1 – Diagnostic rapide

```bash
ip -br a
```

Regarde le nom de l'interface (`enp3s0`, `eth0`, `wlp2s0`…), son état (`UP` / `DOWN`) et si elle a une adresse IP.

```bash
nmcli general status
nmcli device status
```

## 2 – Relancer NetworkManager

```bash
sudo systemctl restart NetworkManager
sudo systemctl status NetworkManager
```

## 3 – Activer le réseau et le Wi-Fi

```bash
sudo nmcli networking on
sudo nmcli radio wifi on
sudo rfkill unblock all
rfkill list
```

## 4 – Monter l'interface

Remplace `enp3s0` par le nom vu à l'étape 1.

```bash
sudo ip link set enp3s0 up
```

## 5 – Obtenir une IP (DHCP)

Avec NetworkManager :

```bash
sudo nmcli device connect enp3s0
```

Ou en forçant le DHCP :

```bash
sudo dhclient -v enp3s0
```

Vérifier :

```bash
ip -br a
ip route
```

Tu dois voir une IP et une route `default via ...`.

## 6 – Tester la connexion

```bash
ping -c 3 8.8.8.8
ping -c 3 google.com
```

| Résultat | Signification |
|---|---|
| `8.8.8.8` ✅ + `google.com` ✅ | Tout fonctionne |
| `8.8.8.8` ✅ + `google.com` ❌ | Problème de **DNS** → étape 7 |
| `8.8.8.8` ❌ | Pas de connexion → reprendre les étapes 2 à 5 (ou vérifier le câble / la box) |

## 7 – Problème de DNS

```bash
sudo systemctl restart systemd-resolved
resolvectl status
```

Si ça ne suffit pas, forcer un DNS temporairement :

```bash
sudo resolvectl dns enp3s0 1.1.1.1 8.8.8.8
```

## 8 – Se connecter au Wi-Fi en CLI

```bash
nmcli device wifi list
nmcli device wifi connect "NOM_DU_WIFI" password "MOT_DE_PASSE"
```

## 9 – L'interface n'apparaît pas (driver)

```bash
lspci -nnk | grep -iA3 net      # carte PCI (Wi-Fi / Ethernet)
lsusb                           # adaptateur USB
dmesg | grep -iE "firmware|wlan|eth|r8169|iwlwifi"
sudo ubuntu-drivers devices
sudo ubuntu-drivers autoinstall
```

Pour une carte Realtek / Broadcom, il faut parfois un paquet dédié (`r8168-dkms`, `bcmwl-kernel-source`…). Sans connexion, installe-le depuis une clé USB ou un partage de connexion du téléphone (USB tethering).

---

## 🖧 Ubuntu Server (Netplan)

Sur Ubuntu Server, la config est dans `/etc/netplan/`.

```bash
ls /etc/netplan/
sudo nano /etc/netplan/00-installer-config.yaml
```

Exemple DHCP :

```yaml
network:
  version: 2
  ethernets:
    enp3s0:
      dhcp4: true
```

Appliquer :

```bash
sudo netplan try      # teste avec retour auto si ça casse
sudo netplan apply
```

---

## ⚡ Script automatique

Le script [`fix-network.sh`](fix-network.sh) enchaîne toutes les étapes (activation, redémarrage de NetworkManager, interfaces up, DHCP, tests, DNS).

```bash
chmod +x fix-network.sh
sudo ./fix-network.sh
```

---

## 🧾 Aide-mémoire

| Action | Commande |
|---|---|
| Voir les interfaces | `ip -br a` |
| État NetworkManager | `nmcli general status` |
| Relancer le réseau | `sudo systemctl restart NetworkManager` |
| Monter une interface | `sudo ip link set IFACE up` |
| Forcer le DHCP | `sudo dhclient -v IFACE` |
| Tester | `ping -c 3 8.8.8.8` |
| Relancer le DNS | `sudo systemctl restart systemd-resolved` |
| Liste Wi-Fi | `nmcli device wifi list` |

## 📄 Licence

MIT – voir [LICENSE](LICENSE).
