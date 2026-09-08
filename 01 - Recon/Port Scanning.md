# 🔎 Port Scanning (nmap)

> The practical nmap reference: full TCP sweep → targeted service scan → UDP → NSE. Same three-scan flow as [[Recon Methodology]], with the flags, output handling, and gotchas. **Miss a port, miss the box.**

Related: [[Recon Methodology]] · [[Host Discovery]] · [[OS & Service Fingerprinting]] · [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]]

---

## 🧠 SCANNING → THINK
- **Always `-p-`** — the intended port is often above 1024.
- **Two-stage:** fast `-p-` to find open ports, then `-sC -sV` on *only* those (fast + detailed).
- **UDP separately**, in the background — it's slow but hides easy wins ([[SNMP]]/[[DNS]]/TFTP).
- **Save output** (`-oN`/`-oA`) — you'll re-read it all box long.
- ICMP blocked? → `-Pn` (see [[Host Discovery]]).

## ⚡ THE THREE SCANS
```bash
export IP=10.10.10.10 ; mkdir -p nmap
```
1) Fast full TCP (find open ports):
```bash
sudo nmap -p- --min-rate 5000 -T4 $IP -oN nmap/allports.txt
```
2) Detailed on open ports (scripts + versions):
```bash
sudo nmap -sC -sV -p<comma,list> $IP -oN nmap/services.txt
```
3) Top UDP (run in background):
```bash
sudo nmap -sU --top-ports 100 $IP -oN nmap/udp.txt
```
Extract the open-port list quickly for stage 2:
```bash
grep -oE '^[0-9]+/tcp' nmap/allports.txt | cut -d/ -f1 | paste -sd,
```

## 🎛️ KEY FLAGS
| Flag | Meaning |
|---|---|
| `-p-` | all 65535 TCP ports |
| `-sC` | default NSE scripts |
| `-sV` | service/version detection |
| `-sU` | UDP scan |
| `-Pn` | skip host discovery (assume up) |
| `-sS` | SYN scan (default w/ root, fast/stealthy) |
| `-A` | OS + version + scripts + traceroute (noisy) |
| `--min-rate N` | send ≥ N packets/sec (speed) |
| `-T0..T5` | timing (T4 typical; T2 for flaky) |
| `-oN/-oG/-oA` | normal / greppable / all output formats |
| `--version-intensity 9` | try harder on version ID |
| `-6` | scan IPv6 |

## 🧩 USEFUL NSE
```bash
sudo nmap -p<ports> --script vuln $IP -oN nmap/vuln.txt        # broad vuln checks (noisy)
```
```bash
sudo nmap -p445 --script "smb-vuln-*" $IP                      # e.g. MS17-010 -> [[SMB]]
```
```bash
sudo nmap -p<port> --script "safe or default" $IP
```
NSE scripts live in `/usr/share/nmap/scripts/` — `ls` there or `nmap --script-help <name>`.

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| "Host seems down" | `-Pn` (skip ping) → [[Host Discovery]] |
| Everything filtered | Slow to `-T2`, re-run `-p-`, check VPN/routing, try UDP |
| Scan too slow | `--min-rate 5000`, split port ranges, background the UDP scan |
| Version unknown | `-sV --version-intensity 9`; banner-grab manually → [[OS & Service Fingerprinting]] |
| Ports change between scans | Some boxes rate-limit — slow down; scan again |
| UDP all "open\|filtered" | Normal for UDP; confirm with service-specific probes/NSE |

## ⚠️ COMMON MISTAKES
- Scanning only the **top 1000** TCP.
- **Never running UDP.**
- Not saving output → re-scanning repeatedly, wasting time.
- Running heavy `-A`/`--script vuln` on all ports first (slow) instead of the fast two-stage flow.
- Forgetting `-Pn` when ICMP is filtered.

## ✅ DON'T MISS
- [ ] Full TCP `-p-`
- [ ] Targeted `-sC -sV` on open ports
- [ ] UDP top-ports (backgrounded)
- [ ] Save all output (`-oN`)
- [ ] `-Pn` if host "down"
- [ ] Route each open port to its service note

## 📇 CHEAT SHEET
```bash
sudo nmap -p- --min-rate 5000 -T4 $IP -oN nmap/allports.txt
```
```bash
sudo nmap -sC -sV -p<list> $IP -oN nmap/services.txt
```
```bash
sudo nmap -sU --top-ports 100 $IP -oN nmap/udp.txt
```
```bash
sudo nmap -p<ports> --script vuln $IP -oN nmap/vuln.txt
```
**Kill flow:** `-p-` → `-sC -sV` → UDP → NSE where relevant.
