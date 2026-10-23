# 🪟 Weak Registry Permissions & UAC Context

> Weak ACLs on a registry value consumed by a privileged service or task can redirect what it runs. UAC is different: it is an elevation boundary for administrators, not a substitute for gaining Administrator or SYSTEM from an ordinary user account.

Part of [[Windows Privilege Escalation]]. Related: [[Windows Service Exploits]] · [[AlwaysInstallElevated]]

---

## 🧠 THINK
- A writable key matters only if a privileged component actually consumes its value.
- Verify ownership, permissions, value semantics, and a safe trigger before changing anything.
- `UAC enabled` does **not** mean a standard user can become admin. If the current user is already a local administrator but has a medium-integrity shell, the goal may only be a high-integrity shell—not SYSTEM.

## ⚡ DETECT
Review services for registry-backed configuration, then inspect the referenced key:
```cmd
sc qc <service_name>
```
```cmd
reg query "HKLM\Software\Vendor\Product" /s
```
```powershell
Get-Acl 'Registry::HKEY_LOCAL_MACHINE\Software\Vendor\Product' | Format-List
```
Check UAC policy and current token integrity:
```cmd
whoami /groups | findstr /i "Mandatory Label"
```
```cmd
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
```
PowerUp can help identify weak registry permissions:
```powershell
. .\PowerUp.ps1; Invoke-AllChecks
```

## ✅ VALIDATE
| Requirement | Evidence |
|---|---|
| A privileged consumer exists | service/task/application runs as SYSTEM/admin |
| Config is security-relevant | value controls executable path, DLL path, script, or plugin location |
| Key/value is writable | current identity has SetValue/CreateSubKey rights |
| Change will be read | documented reload/restart/event in the authorized lab |

## 🔁 FOUND → NEXT
| Finding | Next |
|---|---|
| Privileged consumer + writable execution-related value | document the ACL and validate the controlled execution path in the lab |
| Only user-controlled autorun key | persistence/user-context only; see [[Scheduled Tasks & Autoruns]] |
| Both AlwaysInstallElevated keys set | [[AlwaysInstallElevated]] |
| Current user is local admin at medium integrity | evaluate the permitted UAC elevation path; then continue with normal SYSTEM checks |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Can edit a key but no privileged consumer | not an escalation on its own |
| Access denied | record the ACL; move to services, tokens, or credentials |
| UAC prompts for admin credentials | current user is not already entitled to elevate; find a real privilege boundary issue |

## 📇 CHEAT SHEET
```cmd
whoami /groups | findstr /i "Mandatory Label"
```
```powershell
Get-Acl 'Registry::HKEY_LOCAL_MACHINE\Software\Vendor\Product'
```
**Kill shot:** writable execution-controlling registry value that a SYSTEM/admin process reliably consumes.
