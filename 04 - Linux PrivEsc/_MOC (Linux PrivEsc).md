# 🐧 04 — Linux PrivEsc (Map of Content)

> Low-priv Linux shell → **root**. Start at the hub for the quick checks + priority order, then dive into a technique.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]]. Working hub: [[Linux Privilege Escalation]].

## Notes in this folder
- [x] [[Linux Privilege Escalation]] — **hub / index** (first 5 commands, automated enum, priority order)
- [x] [[Sudo Abuse]] — `sudo -l` → GTFOBins / LD_PRELOAD / sudo CVEs 🟢
- [x] [[SUID & SGID]] — GTFOBins escapes / PATH hijack / injection 🟢
- [x] [[Cron Jobs]] — writable script / relative PATH / wildcard (+ `pspy`) 🟢
- [x] [[Systemd, Timers & Maintenance Jobs]] — systemd timers, `at`, anacron, backup/logrotate targets 🟡
- [x] [[Linux Credential Hunting]] — histories, keys, configs → reuse/`su` 🟢
- [x] [[Linux Capabilities]] — `cap_setuid` / file R/W caps 🟡
- [x] [[Writable Files & PATH Hijack]] — writable `/etc/passwd`/service + PATH 🟡
- [x] [[Polkit, Libraries & App-Specific Paths]] — policy rules, shared libraries, plugins, custom root apps 🟡
- [x] [[Docker & LXD Privesc]] — group → mount host `/` 🟢 (if in group)
- [x] [[Linux Kernel Exploits]] — verify PwnKit early; actual kernel CVEs last 🟡

## Order
`sudo -l` + check `pkexec` → groups → SUID → cron/timers (pspy) → creds → caps → writable files/libraries → docker/lxd → verified kernel route.
Condensed commands: [[Privilege Escalation Cheat Sheet]].

## Low-priv shell → root
1. Stabilise the shell, record `id`, OS, and groups.
2. Run the hub's first commands; a positive `sudo -l`, SUID, cron, group, capability, or writable-file result sends you to that technique immediately.
3. Hunt credentials alongside configuration checks; reuse them with `su`, SSH, or services.
4. Keep kernel exploits last, after configuration and credential routes are exhausted.
5. On root, capture the proof and return to [[Credential Attacks]] for reuse.
