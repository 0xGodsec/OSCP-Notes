# 🪟 DLL Search Order & PATH Hijacking

> A privileged application loads a DLL by name rather than by an absolute, trusted path. If a low-privileged user can write to a directory Windows searches first, their DLL may execute in that application's security context.

Part of [[Windows Privilege Escalation]]. Related: [[Windows Service Exploits]] · [[Scheduled Tasks & Autoruns]]

---

## 🧠 THINK
- This is about a **specific process and DLL**, not blindly dropping DLLs into system directories.
- A useful finding needs all three: privileged process, an insecure DLL load/search order, and a directory you can write to.
- Prefer verifying with Procmon or application logs in a lab. A missing DLL alone is not proof that it is hijackable.

## ⚡ DETECT
Inspect non-Microsoft services and their executable directories:
```cmd
wmic service get name,pathname,startmode | findstr /i /v "C:\\Windows\\"
```
```cmd
icacls "C:\path\to\application"
```
Check the machine PATH and any writable directories it contains:
```cmd
echo %PATH%
```
```cmd
icacls "C:\candidate\path\directory"
```
Use Procmon (filter: Process Name; Operation = `CreateFile`; Result = `NAME NOT FOUND`) to identify a DLL name a privileged program actually searches for.

## ✅ VALIDATE
Before treating it as a route, establish:

| Requirement | Evidence |
|---|---|
| Process is privileged | service/task runs as SYSTEM or an administrator |
| DLL load is unsafe | Procmon shows a relative DLL lookup or predictable missing DLL |
| Candidate directory is writable | `icacls` grants the current user Modify/Write |
| Trigger exists | service restart, scheduled run, or normal application action |

## 🔁 FOUND → NEXT
| Finding | Next |
|---|---|
| Privileged app + writable searched directory | validate DLL architecture/export requirements, then test only in the authorized lab |
| Writable directory but no observed DLL lookup | keep enumerating; do not assume it is exploitable |
| Service executable itself is writable | [[Windows Service Exploits]] |
| Privileged task invokes a writable script/binary | [[Scheduled Tasks & Autoruns]] |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| DLL is loaded by full path | not a search-order issue; check file ACLs instead |
| App will not start after testing | restore the authorized test artifact and inspect Procmon for expected architecture/dependencies |
| PATH entry is writable but no privileged consumer | low value by itself; find a privileged process using it |

## 📇 CHEAT SHEET
```cmd
echo %PATH%
```
```cmd
icacls "C:\candidate\directory"
```
**Kill shot:** privileged process + observed unsafe DLL search + writable searched directory + reliable trigger.
