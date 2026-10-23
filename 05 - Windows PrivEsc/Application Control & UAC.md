# 🪟 Application Control & UAC

> AppLocker and WDAC control what may execute; UAC separates a standard user from an administrator's elevated token. Neither automatically creates an escalation path. Enumerate them to understand constraints and correctly classify what a candidate can achieve.

Part of [[Windows Privilege Escalation]]. Related: [[Registry Permissions & UAC]]

---

## ⚡ DETECT
Check current integrity level and local-group membership:
```cmd
whoami /groups | findstr /i "Mandatory Label Administrators"
```
```cmd
net user %USERNAME%
```
Check UAC policy:
```cmd
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
```
Check AppLocker policy and WDAC/Code Integrity events:
```powershell
Get-AppLockerPolicy -Effective -Xml
```
```powershell
Get-WinEvent -LogName 'Microsoft-Windows-CodeIntegrity/Operational' -MaxEvents 20
```

## 🧠 INTERPRET
| Finding | Meaning |
|---|---|
| Standard user; elevation prompts for different credentials | no existing admin entitlement—find a real privesc route |
| User is in Administrators but token is medium integrity | UAC context; an approved elevation may produce high integrity, not automatically SYSTEM |
| AppLocker/WDAC policy blocks a tool | execution-control constraint; continue with allowed built-in enumeration and legitimate assessment procedures |
| SYSTEM task/service has writable target | actual privesc candidate—see service/task notes |

## 🚧 COMMON MISTAKES
- Calling a UAC prompt a privesc when it requires someone else's credentials.
- Treating an AppLocker or WDAC restriction as an escalation vulnerability.
- Confusing high-integrity Administrator with SYSTEM; keep checking services, tokens, and credential access after elevation.

**Kill shot:** classify the token and controls accurately, then pursue a separate privilege-boundary flaw.
