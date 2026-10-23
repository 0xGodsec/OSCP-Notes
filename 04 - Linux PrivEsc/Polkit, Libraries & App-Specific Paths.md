# 🐧 Polkit, Libraries & App-Specific Paths

> The remaining Linux privesc routes are often application-specific: a policy rule grants a dangerous action, or a root program loads a library, plugin, configuration, or helper from a location a low-privileged user controls. These are evidence-led routes, not blind file drops.

Part of [[Linux Privilege Escalation]]. Related: [[Writable Files & PATH Hijack]] · [[SUID & SGID]]

---

## 🧠 THINK
- Polkit policy **actions** describe permissions; JavaScript rules and local policy configuration determine whether an identity is actually granted an action.
- A writable shared library is useful only if a root/SUID/service process dynamically loads that exact path and protections do not prevent substitution.
- Plugins, hooks, config files, and helpers bundled with custom software are high-value OSCP targets—read the service/unit and application documentation first.

## ⚡ DETECT
Inspect local polkit rules and registered actions:
```bash
find /etc/polkit-1 /usr/share/polkit-1 -type f 2>/dev/null
```
```bash
pkaction --verbose 2>/dev/null
```
Inspect privileged services and their execution context:
```bash
systemctl cat <service>
```
```bash
ps -eo user,pid,cmd --sort=user
```
For a specific program, inspect declared dynamic dependencies and its search paths:
```bash
readelf -d /path/to/program 2>/dev/null | grep -E 'NEEDED|RPATH|RUNPATH'
```
```bash
ldd /path/to/program 2>/dev/null
```
Find non-standard writable files associated with a root service or application:
```bash
find /opt /usr/local /etc -type f -writable 2>/dev/null
```

## ✅ VALIDATE
| Requirement | Evidence |
|---|---|
| Privileged process/action exists | root service/SUID binary, or polkit action available to current identity |
| User-controlled input is consumed | config, plugin, helper, or library path is actually read/loaded |
| Write access is real | file or containing directory is writable and replacement is possible |
| Trigger and impact are clear | service restart, timer, normal app action, or a permitted polkit action |

## 🔁 FOUND → NEXT
| Finding | Next |
|---|---|
| Root process consumes writable script/config/helper | [[Writable Files & PATH Hijack]] or [[Systemd, Timers & Maintenance Jobs]] |
| Root process has a writable loaded library/plugin path | document exact dependency, architecture, and trigger; validate only in the authorized lab |
| Polkit rule appears permissive | confirm the current identity is authorized for the specific action before treating it as a route |
| No consumer/trigger | not a privesc finding by itself; continue enumeration |

## ⚠️ COMMON MISTAKES
- Treating an installed polkit action as an escalation without checking authorization.
- Replacing a library based only on `ldd` output without proving a privileged process loads it.
- Ignoring custom software under `/opt` and `/usr/local` because it is not a standard Linux component.

## 📇 CHEAT SHEET
```bash
pkaction --verbose 2>/dev/null
```
```bash
readelf -d /path/to/program | grep -E 'NEEDED|RPATH|RUNPATH'
```
```bash
find /opt /usr/local /etc -type f -writable 2>/dev/null
```
**Kill shot:** privileged consumer + proven writable input/dependency + reliable trigger.
