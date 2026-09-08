# 🐧 04 — Linux PrivEsc (Map of Content)

> Low-priv Linux shell → **root**. Start at the hub for the quick checks + priority order, then dive into a technique.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]]. Working hub: [[Linux Privilege Escalation]].

## Notes in this folder
- [x] [[Linux Privilege Escalation]] — **hub / index** (first 5 commands, automated enum, priority order)
- [x] [[Sudo Abuse]] — `sudo -l` → GTFOBins / LD_PRELOAD / sudo CVEs 🟢
- [x] [[SUID & SGID]] — GTFOBins escapes / PATH hijack / injection 🟢
- [x] [[Cron Jobs]] — writable script / relative PATH / wildcard (+ `pspy`) 🟢
- [x] [[Linux Kernel Exploits]] — PwnKit (pkexec) + kernel CVEs 🟢 (PwnKit)
- [x] [[Linux Credential Hunting]] — histories, keys, configs → reuse/`su` 🟢
- [x] [[Linux Capabilities]] — `cap_setuid` / file R/W caps 🟡
- [x] [[Writable Files & PATH Hijack]] — writable `/etc/passwd`/service + PATH 🟡
- [x] [[Docker & LXD Privesc]] — group → mount host `/` 🟢 (if in group)

## Order
`sudo -l` → SUID → cron (pspy) → PwnKit → creds → caps → writable files → docker/lxd → kernel.
Condensed commands: [[Privilege Escalation Cheat Sheet]].
