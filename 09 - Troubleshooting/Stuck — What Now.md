# 🧯 Stuck — What Now

> The meta-checklist for "I've tried everything and I'm getting nowhere." 90% of the time the answer is **enumeration you missed** or **a credential you already have**. Work this before switching targets — then switch.

Related: [[Troubleshooting Methodology]] · [[Enumeration Methodology]] · [[Credential Attacks]]

---

## The checklist (run top to bottom)
1. **Re-read your own notes** for this box. What did you find but not act on?
2. **Did you scan everything?**
```bash
sudo nmap -Pn -p- --min-rate 5000 $IP        # full TCP
```
```bash
sudo nmap -Pn -sU --top-ports 100 $IP        # UDP
```
3. **New hostname/domain anywhere?** Add to `/etc/hosts` → re-run **vhost** + **AD** enum.
4. **Cred reuse** — take every user/pass/hash/key and test on **every** service and host ([[Credential Attacks]]).
5. **Web:** re-fuzz dirs *and* params, read JS/source, check `/robots.txt`, backups, `.git`, admin panels.
6. **Version → searchsploit** for every service — did you check them all?
7. **Anonymous/default/null** access — did you try it on every service?
8. **Post-foothold:** scanned **localhost/internal** ports? swept the **subnet**? ([[Pivoting and Port Forwarding]])

## Mindset resets
- **Don't marry the box.** Time-boxed out (~20–30 min dead-air)? → switch target, return later.
- **Fatigue is a bug** — take the scheduled break; the answer often appears after.
- **Change one variable at a time** so you learn what worked.
- **Assume missed enumeration** before assuming "impossible".

## The usual culprits (what people miss)
| Missed thing | Where |
|---|---|
| A port above 1000 / a UDP service | [[Port Scanning]] |
| A vhost only reachable by hostname | [[Web Enumeration]] / [[HTTPS]] |
| Creds in a config/share/mailbox you read but didn't reuse | [[Credential Attacks]] |
| `php://filter` source / LFI→RCE path | [[LFI]] |
| SMB null session / RID-brute users | [[SMB]] / [[RPC]] |
| AS-REP roast (needs no creds) | [[Kerberos]] |
| Localhost-only DB/service after foothold | [[Pivoting and Port Forwarding]] |
| `sudo -l` / `whoami /priv` for privesc | [[Linux Privilege Escalation]] / [[Windows Privilege Escalation]] |

## Rule
If the full checklist is genuinely exhausted, it's a **switch-targets** moment, not a "grind harder" moment. Log where you stopped and come back with fresh eyes or a credential from another box.
