# 🧯 No Open Ports / Host Seems Down

> nmap says "host down" or shows nothing open. Almost always **filtering or a scan mistake**, not a dead host. Work this list.

Related: [[Troubleshooting Methodology]] · [[Port Scanning]] · [[Host Discovery]]

---

## Fast fixes (in order)
1. **Skip host discovery** (ICMP is usually blocked):
```bash
sudo nmap -Pn -p- --min-rate 5000 $IP -oN nmap/allports.txt
```
2. **Confirm you're on the VPN** and using the right interface:
```bash
ip a show tun0
```
3. **Full range, not top-1000** — you did use `-p-`, right?
4. **Slow down** if the target rate-limits:
```bash
sudo nmap -Pn -p- -T2 $IP
```
5. **Try UDP** — the only thing open might be UDP:
```bash
sudo nmap -Pn -sU --top-ports 100 $IP
```
6. **TCP discovery** if you must probe liveness:
```bash
sudo nmap -PS22,80,443,445 $IP
```

## Still nothing?
| Check | Action |
|---|---|
| Right IP? | Re-read the target sheet; typo in `$IP`? |
| Routing/VPN | `ping` your gateway; reconnect VPN; check `ip route` |
| Firewall dropping SYN | Try `-sT` (connect scan), different `--min-rate`, `-T2` |
| Everything `filtered` | Note it; move to another target; retry later |
| Only UDP responds | Enumerate that service ([[SNMP]]/[[DNS]]) |

## Rules
- **"Host down" ≠ down** — it's ICMP filtering. `-Pn` first, always.
- Don't burn 30 min here — if `-Pn -p-` + UDP truly show nothing, switch targets and come back.
