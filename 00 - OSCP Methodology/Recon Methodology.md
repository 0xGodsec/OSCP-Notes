# 🔎 Recon Methodology

> The scanning game plan for a single target: **find every open port** (TCP + UDP), **fingerprint every service**, and **re-scan whenever you learn something new**. Missed ports = missed paths = failed boxes. This is the most important 15 minutes on any machine.

Related: [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]] · [[Web Enumeration]] · [[Enumeration Methodology]] · [[Port Scanning]]

---

## 🧠 NEW TARGET → THINK
- **Full TCP range first** — the intended port is often *not* in the top 1000.
- **Then targeted `-sC -sV`** on the ports you found.
- **Don't skip UDP** — SNMP/DNS/TFTP/SNMP live there and are easy wins.
- Every open port → **open its [[00 - START HERE (OSCP Playbook Index)|02 - Services]] note** and work the tree.
- New hostname/domain → `/etc/hosts` → **re-enumerate** (vhosts, AD).

## ⚡ THE THREE SCANS (run in this order)
Set the target once:
```bash
export IP=10.10.10.10
```
```bash
mkdir -p nmap
```
1) Fast full TCP sweep (all 65535 ports):
```bash
sudo nmap -p- --min-rate 5000 -T4 $IP -oN nmap/allports.txt
```
2) Service/version + default scripts on just the open ports:
```bash
sudo nmap -sC -sV -p<comma,list> $IP -oN nmap/services.txt
```
3) Top UDP ports (slow — start it early, let it run):
```bash
sudo nmap -sU --top-ports 100 $IP -oN nmap/udp.txt
```

## 🧭 INTERPRET → ROUTE
| See | Think | Go |
|---|---|---|
| 80/443/8080 | web = #1 foothold | [[HTTP]] / [[HTTPS]] / [[Web Enumeration]] |
| 139/445 | SMB, maybe MS17-010 | [[SMB]] |
| 88/389/135 | it's a **DC / domain** | [[Kerberos]] / [[LDAP]] / [[RPC]] → [[Active Directory]] |
| 21/22/23 | FTP/SSH/Telnet cred surfaces | [[FTP]] / [[SSH]] / [[Telnet]] |
| 161/UDP | SNMP goldmine | [[SNMP]] |
| 1433/3306/5432 | databases | [[MSSQL]] / [[MySQL]] / [[PostgreSQL]] |
| 3389/5985 | Windows access | [[RDP]] / [[WinRM]] |

## 🔁 RE-SCAN TRIGGERS (recon is a loop, not a step)
- Found a **hostname/domain** → add to `/etc/hosts` → re-run web vhost enum + AD enum.
- Got a **foothold** → scan **internal** interfaces/localhost ports (things bound to 127.0.0.1) → [[Pivoting and Port Forwarding]].
- A service hints at another (e.g., web config names a DB host) → enumerate that.
- Nothing found on top ports → you already ran `-p-`, right? If not, do it now.

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Host "down" / no response | Add `-Pn` (skip host discovery) |
| Everything filtered | Slow down (`-T2`), try `-p-` again, check VPN/routing, try UDP |
| Version unknown | `-sV --version-intensity 9`; banner-grab with `nc`/`openssl s_client`; NSE scripts |
| Scan too slow | `--min-rate`, split ranges, run UDP separately in background |
| Web behaves oddly | It's vhost/SNI-based — get the hostname from the cert ([[HTTPS]]) and set `/etc/hosts` |

## ⚠️ COMMON MISTAKES
- Only scanning the **top 1000** TCP ports.
- **Skipping UDP** entirely.
- Not re-scanning after finding a hostname or a foothold.
- Not opening the **service note** for each open port (missing enumeration steps).
- Forgetting `-Pn` when ICMP is blocked (concluding "host down").

## ✅ DON'T MISS
- [ ] `nmap -p-` full TCP
- [ ] `nmap -sC -sV` on open ports
- [ ] `nmap -sU --top-ports 100`
- [ ] Add hostnames to `/etc/hosts`, re-enumerate
- [ ] Open every service's note and work its tree
- [ ] After foothold: scan internal/localhost ports

## 📇 CHEAT SHEET
```bash
export IP=10.10.10.10 ; mkdir -p nmap
```
```bash
sudo nmap -p- --min-rate 5000 -T4 $IP -oN nmap/allports.txt
```
```bash
sudo nmap -sC -sV -p<list> $IP -oN nmap/services.txt
```
```bash
sudo nmap -sU --top-ports 100 $IP -oN nmap/udp.txt
```
**Kill flow:** full TCP → targeted `-sC -sV` → UDP → route each port to its service note → re-scan on new info.
