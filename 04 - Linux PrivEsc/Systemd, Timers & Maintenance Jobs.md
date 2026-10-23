# 🐧 systemd, Timers & Maintenance Jobs

> Root work is not limited to cron. `systemd` services/timers, `at`, anacron, logrotate, backup jobs, and vendor maintenance scripts can all become a root path when they execute a writable target or trust a writable directory.

Part of [[Linux Privilege Escalation]]. Related: [[Cron Jobs]] · [[Writable Files & PATH Hijack]]

---

## 🧠 THINK
- A writable unit file alone is not enough: establish that a privileged process reads it and that it will reload, restart, or run at boot.
- Inspect both the declared command and every script, environment file, working directory, and referenced configuration path.
- `pspy` is useful here too; it reveals maintenance jobs that are not obvious from static configuration.

## ⚡ DETECT
```bash
systemctl list-timers --all
```
```bash
systemctl list-unit-files --state=enabled
```
```bash
systemctl cat <service-or-timer>
```
```bash
atq; cat /etc/anacrontab 2>/dev/null; ls -la /etc/anacrontab /etc/anacron* 2>/dev/null
```
```bash
find /etc/systemd /usr/lib/systemd /lib/systemd /etc/logrotate.d /etc/cron.* -type f -writable 2>/dev/null
```
```bash
grep -RniE 'postrotate|prerotate|firstaction|lastaction|include' /etc/logrotate.conf /etc/logrotate.d 2>/dev/null
```
**Look for:** a root-run unit/timer/maintenance script that references a script, executable, environment file, directory, or logrotate hook you can modify.

## ✅ VALIDATE
| Requirement | Evidence |
|---|---|
| Privileged consumer | `systemctl cat` or observed process shows root execution |
| Controllable target | current user can modify or replace the executed script/binary/config |
| Real trigger | listed timer, a known restart/reboot, log rotation, or observed process event |
| Correct interpretation | unit uses the referenced file/path; it is not merely an unused config |

## 🔁 FOUND → NEXT
| Finding | Next |
|---|---|
| Root timer/service executes writable script | validate the execution chain; trigger only in the authorized lab |
| Writable `ExecStart` dependency or environment file | validate reload/restart conditions, then document the route |
| Writable logrotate hook/config consumed by root | validate schedule and hook behavior |
| Root cron job | [[Cron Jobs]] |
| No writable target/trigger | record it and continue with the next privesc phase |

## 📇 CHEAT SHEET
```bash
systemctl list-timers --all; systemctl list-unit-files --state=enabled
```
```bash
atq; cat /etc/anacrontab 2>/dev/null
```
```bash
./pspy64
```
**Kill shot:** root maintenance job + writable consumed target + predictable trigger.
