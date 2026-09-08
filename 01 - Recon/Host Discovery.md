# 🔎 Host Discovery

> Finding live hosts — on a single target (is it up? do I need `-Pn`?) and across a subnet (which IPs exist, e.g., after landing in an internal network / AD set). On OSCP the single-host case is usually **"just use `-Pn`"**; the subnet case matters once you pivot.

Related: [[Port Scanning]] · [[Recon Methodology]] · [[Pivoting and Port Forwarding]] · [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]]

---

## 🧠 IS IT UP? → THINK
- Exam targets often **block ICMP** → nmap says "host down" though it's fine. **Use `-Pn`.**
- Don't waste time proving a host is up — if you have the IP, scan it with `-Pn`.
- **Subnet discovery** matters after a foothold: enumerate the internal network for more hosts (AD set, pivots).

## ⚡ SINGLE HOST
Just scan it, skipping discovery:
```bash
sudo nmap -Pn -p- --min-rate 5000 $IP -oN nmap/allports.txt
```
Quick "is it reachable at all" sanity checks:
```bash
ping -c 2 $IP
```
```bash
sudo nmap -sn $IP        # ping-only (may falsely report down if ICMP blocked -> use -Pn instead)
```

## ⚡ SUBNET / INTERNAL (after a foothold)
Ping sweep a range:
```bash
sudo nmap -sn 10.10.10.0/24 -oN nmap/sweep.txt
```
No nmap on the pivot host? Use a shell one-liner from the foothold:
```bash
for i in $(seq 1 254); do (ping -c1 -W1 10.10.10.$i >/dev/null && echo "10.10.10.$i up" &); done; wait
```
ARP scan on a local segment (very reliable on the same L2):
```bash
sudo arp-scan --localnet
```
Then port-scan each live host ([[Port Scanning]]); pivot as needed ([[Pivoting and Port Forwarding]]).

## 🎛️ DISCOVERY FLAGS
| Flag | Meaning |
|---|---|
| `-Pn` | skip discovery, treat all as up (use when ICMP blocked) |
| `-sn` | ping scan only (no port scan) |
| `-PE/-PP/-PM` | ICMP echo/timestamp/netmask probes |
| `-PS<ports>` | TCP SYN discovery to given ports |
| `-PA<ports>` | TCP ACK discovery |
| `-PU<ports>` | UDP discovery |
| `-n` | no DNS resolution (faster) |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| nmap says "host down" | `-Pn` — ICMP is filtered, host is likely fine |
| `-sn` finds nothing on subnet | Hosts block ping — use TCP discovery `-PS22,80,443,445` or scan `-Pn` directly |
| No tools on pivot host | bash `/dev/tcp` port check, `ping` loop, or upload a static scanner |
| Too many hosts | Prioritise by open 445/80/88 (Windows/web/DC) |
| Different subnet visible post-foothold | Add a route/proxy → [[Pivoting and Port Forwarding]] |

## ⚠️ COMMON MISTAKES
- Concluding a target is **down** because ICMP is blocked — always try `-Pn`.
- Spending time on discovery for a **single known IP** — just scan it.
- Forgetting to **sweep the internal subnet** after getting a foothold (missing the rest of the AD set).
- Relying on ping when hosts only answer on TCP.

## ✅ DON'T MISS
- [ ] Single host → `-Pn` and scan
- [ ] After foothold → **sweep the internal /24**
- [ ] Use TCP discovery when ICMP is blocked (`-PS`)
- [ ] Port-scan every live host found
- [ ] Prioritise 445/80/88 hosts

## 📇 CHEAT SHEET
```bash
sudo nmap -Pn -p- --min-rate 5000 $IP -oN nmap/allports.txt      # single host
```

```bash
sudo nmap -sn 10.10.10.0/24 -oN nmap/sweep.txt                   # subnet sweep
```

```bash
for i in $(seq 1 254); do (ping -c1 -W1 10.10.10.$i >/dev/null && echo 10.10.10.$i &); done; wait
```

```bash
sudo arp-scan --localnet                                          # local L2
```
**Rule:** ICMP blocked ≠ host down → `-Pn`. After a foothold, always sweep for more hosts.
