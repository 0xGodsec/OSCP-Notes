# 🪟 Windows PrivEsc Enumeration

> Before choosing an escalation route, build a short facts table: identity, token privileges, OS build, local admins, running privileged programs, writable locations, credentials, and domain membership. This prevents tunnel vision and makes every later finding easier to validate.

Part of [[Windows Privilege Escalation]].

---

## ⚡ BASELINE — identity and OS
```cmd
whoami /all
```
```cmd
whoami /priv
```
```cmd
hostname & systeminfo
```
```cmd
net user %USERNAME% & net localgroup administrators
```

## ⚡ BASELINE — host and execution context
```cmd
tasklist /svc
```
```cmd
sc query state= all
```
```cmd
schtasks /query /fo LIST /v
```
```cmd
set
```

## ⚡ BASELINE — network and domain
```cmd
ipconfig /all
```
```cmd
net user /domain
```
```cmd
wmic computersystem get domain,partofdomain
```

## ⚡ BASELINE — policy and defensive controls
```cmd
netsh advfirewall show allprofiles
```
```powershell
Get-MpComputerStatus
```
```cmd
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\SrpV2 /s
```

## 🧠 TRIAGE ROUTER
| Finding | Next note |
|---|---|
| `SeImpersonate` / `SeAssignPrimaryToken` enabled | [[Token Privileges & Potato]] |
| Other enabled `Se*` privilege | [[Windows Special Privileges]] |
| Service/task/autorun executes writable target | [[Windows Service Exploits]] or [[Scheduled Tasks & Autoruns]] |
| Suspicious app directory, PATH, or missing DLL load | [[DLL Search Order & PATH Hijacking]] |
| Credential artifact | [[Windows Stored Credentials]] |
| Domain joined or domain credential | [[Windows to AD Pivot]] |
| OS build/patch candidate | [[Windows Kernel Exploits]] |

## 📇 EXAM DISCIPLINE
- Record the exact path, ACL, account, trigger, and expected privilege level for every candidate.
- Validate one condition at a time in the authorized lab; an interesting command output is not an exploit.
- Run automated enumeration as a second opinion, then manually confirm its findings.

**Kill shot:** facts first → choose the route whose requirements are actually true.
