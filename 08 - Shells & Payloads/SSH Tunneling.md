# 🔀 SSH Tunneling (Port Forwarding)

> When you have **SSH creds on the pivot host**, SSH forwarding is the simplest, most reliable way to reach an internal network: local forward (one internal port → your localhost), remote forward (an internal port back to you), and dynamic (a SOCKS proxy for a whole subnet).

Part of [[Pivoting and Port Forwarding]]. Related: [[Proxychains & SOCKS]] · [[SSH]] · [[Chisel]]

---

## 🧠 THINK
- Prefer SSH forwarding whenever you have creds on the pivot — no tool upload needed.
- **-L** local (reach one internal service on your box), **-D** dynamic (SOCKS → whole subnet), **-R** remote (bring an internal port to you).
- Pair `-D` with proxychains → [[Proxychains & SOCKS]].

## 💥 LOCAL FORWARD (-L)
Reach internal `172.16.1.5:80` on your `127.0.0.1:8080`:
```bash
ssh -L 8080:172.16.1.5:80 user@PIVOT
```
Then browse `http://127.0.0.1:8080`.

## 💥 DYNAMIC / SOCKS (-D) — best for scanning
```bash
ssh -D 1080 user@PIVOT
```
Set `/etc/proxychains4.conf` → `socks5 127.0.0.1 1080`, then:
```bash
proxychains nmap -sT -Pn -p 445,80,3389 172.16.1.0/24
```
```bash
proxychains netexec smb 172.16.1.5
```

## 💥 REMOTE FORWARD (-R)
Bring an internal port back to your Kali (e.g. when the pivot can reach a host you can't):
```bash
ssh -R 9001:127.0.0.1:9001 user@PIVOT
```

## 🧷 HANDY FLAGS
`-fN` (background, no shell), `-i key` (key auth), `-J user@host1` (jump/proxy through a host for a double pivot).

## 🔁 FOUND → NEXT
| SITUATION | NEXT |
|---|---|
| One internal service | `-L` local forward → browse localhost |
| Whole subnet to scan | `-D` SOCKS → [[Proxychains & SOCKS]] |
| Internal port back to you | `-R` remote forward |
| No SSH creds on pivot | use [[Chisel]] / [[Ligolo-ng]] |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| SSH forwarding disabled | `AllowTcpForwarding no` on server — use [[Chisel]]/[[Ligolo-ng]] |
| proxychains slow/misses hosts | `-sT -Pn` only (SYN won't traverse SOCKS) → [[Proxychains & SOCKS]] |
| Double pivot needed | chain with `-J`, or nested tunnels / [[Ligolo-ng]] |
| No creds, only a shell | switch to [[Chisel]] |

## 📇 CHEAT SHEET
```bash
ssh -D 1080 user@PIVOT              # SOCKS -> proxychains
```
```bash
ssh -L 8080:172.16.1.5:80 user@PIVOT   # local forward
```
```bash
ssh -R 9001:127.0.0.1:9001 user@PIVOT  # remote forward
```
**Kill shot:** SSH creds on pivot → `-D` SOCKS → proxychains the internal subnet.
