# 🔀 Proxychains & SOCKS

> How to actually *use* a SOCKS proxy created by [[SSH Tunneling]] (`ssh -D`) or [[Chisel]] (`R:socks`). Point proxychains at the SOCKS port and prefix your tools — with the one rule that trips everyone up: **TCP connect scans only** (`-sT -Pn`).

Part of [[Pivoting and Port Forwarding]]. Related: [[SSH Tunneling]] · [[Chisel]] · [[Ligolo-ng]]

---

## 🧠 THINK
- Proxychains routes a tool's TCP through a SOCKS proxy (from `ssh -D` or chisel).
- **SYN scans and raw-socket tools don't traverse SOCKS** → use `nmap -sT -Pn`.
- **No proxychains needed with [[Ligolo-ng]]** (it uses a TUN route instead).

## ⚙️ CONFIGURE
Edit `/etc/proxychains4.conf` — last line, match your proxy's port:
```
socks5 127.0.0.1 1080
```
(`ssh -D 1080` and chisel `R:socks` both default to 1080.) Leave `proxy_dns` on for name resolution through the tunnel; use `strict_chain` (default) for a single proxy.

## 💥 USE IT (prefix any TCP tool)
```bash
proxychains nmap -sT -Pn -p 445,80,139,3389 172.16.1.0/24
```
```bash
proxychains netexec smb 172.16.1.5
```
```bash
proxychains xfreerdp /u:user /p:pass /v:172.16.1.5
```
```bash
proxychains curl http://172.16.1.5/
```
Tip: `-q` (quiet) hides proxychains' per-connection log spam for cleaner output.

## 🔁 FOUND → NEXT
| SITUATION | NEXT |
|---|---|
| SOCKS up (ssh -D / chisel) | proxychains your tools (`-sT -Pn`) |
| Scan finds internal hosts | proxychains netexec/curl/rdp into them |
| Need GUI/native speed | switch to [[Ligolo-ng]] (no proxychains) |
| UDP required | proxychains is TCP-only → [[Ligolo-ng]] |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| nmap returns nothing | must be `-sT -Pn` (SYN won't traverse SOCKS) |
| "no route"/timeouts | wrong SOCKS port in conf; confirm the tunnel is up |
| DNS not resolving | keep `proxy_dns`; or use IPs directly |
| Slow / flaky | reduce nmap scope/ports; or switch to [[Ligolo-ng]] TUN |
| UDP tool needed | SOCKS can't — use [[Ligolo-ng]] |

## 📇 CHEAT SHEET
```
# /etc/proxychains4.conf
socks5 127.0.0.1 1080
```
```bash
proxychains -q nmap -sT -Pn -p 445,80,3389 172.16.1.0/24
```
```bash
proxychains netexec smb 172.16.1.5
```
**Rule:** `-sT -Pn` through SOCKS; for native speed/UDP/GUI use [[Ligolo-ng]].
