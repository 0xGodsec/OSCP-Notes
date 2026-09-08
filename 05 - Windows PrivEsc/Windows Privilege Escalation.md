# 🪟 Windows Privilege Escalation (Hub)

> Low-priv Windows shell (`iis apppool`, a user, a service account). Goal: **SYSTEM** / Administrator. This is the index — run the quick checks, then jump to the per-technique note. Token/potato and service misconfigs are the bread-and-butter OSCP wins.

Related: [[Shells]] · [[Credential Attacks]] · [[SMB]] · [[Active Directory]]

---

## ⚡ FIRST COMMANDS
```cmd
whoami /priv
```
```cmd
whoami /all
```
```cmd
systeminfo
```
```cmd
net user & net localgroup administrators
```

## 🤖 AUTOMATED ENUM
```powershell
.\winPEASx64.exe
```
```powershell
powershell -ep bypass -c ". .\PowerUp.ps1; Invoke-AllChecks"
```
Feed `systeminfo` to **WES-NG** for missing patches. Transfer tools via `impacket-smbserver share . -smb2support` or `certutil` — see [[File Transfer Cheat Sheet]].

---

## 🎯 TECHNIQUES (priority order — click into each)
| # | Technique | Note | Prob |
|---|---|---|---|
| 1 | `SeImpersonate` → PrintSpoofer/GodPotato → SYSTEM | [[Token Privileges & Potato]] | 🟢🟢 |
| 2 | Unquoted paths / weak service perms / writable binary | [[Windows Service Exploits]] | 🟢 |
| 3 | AlwaysInstallElevated (both keys = 1) → MSI | [[AlwaysInstallElevated]] | 🟢 |
| 4 | Stored creds (registry/unattend/cmdkey/PS history) | [[Windows Stored Credentials]] | 🟢 |
| 5 | Scheduled tasks / autoruns with writable target | [[Scheduled Tasks & Autoruns]] | 🟡 |
| 6 | Missing patches / kernel LPE / SeriousSAM | [[Windows Kernel Exploits]] | 🟡 |
| 7 | SeBackup/SeRestore/SeTakeOwnership/SeLoadDriver/… | [[Windows Special Privileges]] | 🟡 |
| — | After admin/SYSTEM: pull SAM/LSA/NTDS | [[Dumping Windows Hashes]] | 🟢 (loot) |

## 🔁 FOUND → NEXT (router)
| FINDING | GO |
|---|---|
| `SeImpersonate` Enabled | [[Token Privileges & Potato]] |
| Unquoted/weak-perm service | [[Windows Service Exploits]] |
| AlwaysInstallElevated=1 (both) | [[AlwaysInstallElevated]] |
| unattend/autologon/cmdkey cred | [[Windows Stored Credentials]] |
| Writable scheduled task/autorun | [[Scheduled Tasks & Autoruns]] |
| Missing patch / readable SAM | [[Windows Kernel Exploits]] |
| Other Se* privilege enabled | [[Windows Special Privileges]] |
| Reached admin/SYSTEM | [[Dumping Windows Hashes]] → reuse |

## 🚧 STUCK?
No `SeImpersonate`? → PowerUp services, AlwaysInstallElevated, stored creds, WES-NG patches. winPEAS blocked by AV? → run `accesschk`/`reg query`/PowerUp modules individually. Then → [[Stuck — What Now]].

## ⚠️ COMMON MISTAKES
- Not checking `whoami /priv` first (miss easy Potato→SYSTEM) · wrong Potato for the build · ignoring PowerUp · overlooking stored creds · kernel exploits before token/service checks · not dumping hashes after SYSTEM.

## 📇 QUICK ORDER
`whoami /priv` (Potato) → PowerUp/services → AlwaysInstallElevated → stored creds → tasks → WES-NG patches → special privileges → dump hashes.
See [[Privilege Escalation Cheat Sheet]] for the condensed commands.
