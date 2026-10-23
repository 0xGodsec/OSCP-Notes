# 🪟 Windows Privilege Escalation (Hub)

> Low-priv Windows shell (`iis apppool`, a user, a service account). Goal: **SYSTEM** / Administrator. This is the index — run the quick checks, then jump to the per-technique note. Token/potato and service misconfigs are the bread-and-butter OSCP wins.

Related: [[Shells]] · [[Credential Attacks]] · [[SMB]] · [[Active Directory]]

---

## 🧭 EXAM WORKFLOW — low-priv shell → SYSTEM
Windows has no `root`; after the normal-user flag, aim for **Administrator** or, ideally, **NT AUTHORITY\\SYSTEM**. Work top-to-bottom. When a row gives a positive finding, stop the broad enumeration and follow that note until it succeeds or is disproved.

| Phase | Test first | Positive finding → use | If not found → continue |
|---|---|---|---|
| 0. Stabilize | identity, architecture, OS, domain status | record `whoami /all`, `systeminfo`, domain membership | 1 |
| 1. Token quick win | `whoami /priv` | `SeImpersonate` / `SeAssignPrimaryToken` → [[Token Privileges & Potato]] | 2 |
| 2. Other special rights | full `whoami /priv` | `SeBackup`, `SeRestore`, `SeDebug`, etc. → [[Windows Special Privileges]] | 3 |
| 3. Credentials | autologon, `cmdkey`, unattend, history, configs | usable credential → [[Windows Stored Credentials]] | 4 |
| 4. Services | PowerUp; service paths, ACLs, binaries | weak ACL, unquoted path, writable executable → [[Windows Service Exploits]] | 5 |
| 5. Installer / registry | AlwaysInstallElevated; execution-related registry ACLs | both installer keys set, or privileged consumer uses writable value → [[AlwaysInstallElevated]] / [[Registry Permissions & UAC]] | 6 |
| 6. Tasks / autoruns | scheduled-task targets and startup/Run entries | privileged task/autorun uses writable target → [[Scheduled Tasks & Autoruns]] | 7 |
| 7. Application load paths | writable application directory, PATH, DLL/plugin lookup | privileged app searches writable location → [[DLL Search Order & PATH Hijacking]] | 8 |
| 8. Handler edge cases | COM, protocol, file-association registration | elevated consumer honors user-controlled handler → [[COM, File Association & Protocol Hijacks]] | 9 |
| 9. Patch route | OS build and hotfixes | applicable, stable LPE or SeriousSAM evidence → [[Windows Kernel Exploits]] | 10 |
| 10. Domain fork | domain joined / domain credential | move to [[Windows to AD Pivot]] → [[Active Directory]] | document findings / re-enumerate |

### Recommended command order
Run these individually from the low-privileged shell. They feed phases 0–6 above.

```cmd
whoami /all
```
```cmd
whoami /priv
```
```cmd
systeminfo
```
```cmd
wmic computersystem get domain,partofdomain
```
```powershell
powershell -ep bypass -c ". .\PowerUp.ps1; Invoke-AllChecks"
```
```cmd
cmdkey /list
```
```cmd
schtasks /query /fo LIST /v
```

Then use [[Windows PrivEsc Enumeration]] for the full manual checklist. Do not run a kernel exploit until phases 1–8 have produced no usable route.

## ⚡ FIRST COMMANDS
Run the complete baseline in [[Windows PrivEsc Enumeration]]; these four commands are the fastest triage.
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

## 🎯 TECHNIQUES (reference order — click into each)
| # | Technique | Note | Prob |
|---|---|---|---|
| 1 | `SeImpersonate` → PrintSpoofer/GodPotato → SYSTEM | [[Token Privileges & Potato]] | 🟢🟢 |
| 2 | Unquoted paths / weak service perms / writable binary | [[Windows Service Exploits]] | 🟢 |
| 3 | AlwaysInstallElevated (both keys = 1) → MSI | [[AlwaysInstallElevated]] | 🟢 |
| 4 | Stored creds (registry/unattend/cmdkey/PS history) | [[Windows Stored Credentials]] | 🟢 |
| 5 | Scheduled tasks / autoruns with writable target | [[Scheduled Tasks & Autoruns]] | 🟡 |
| 6 | DLL search-order / PATH hijack | [[DLL Search Order & PATH Hijacking]] | 🟡 |
| 7 | Weak registry ACLs / UAC context | [[Registry Permissions & UAC]] | 🟡 |
| 8 | COM / file-association / protocol-handler hijack | [[COM, File Association & Protocol Hijacks]] | 🟡 |
| 9 | Local-admin UAC context / application-control policy | [[Application Control & UAC]] | ⚪ context |
| 10 | Missing patches / kernel LPE / SeriousSAM | [[Windows Kernel Exploits]] | 🟡 |
| 11 | SeBackup/SeRestore/SeTakeOwnership/SeLoadDriver/… | [[Windows Special Privileges]] | 🟡 |
| — | After admin/SYSTEM: pull SAM/LSA/NTDS | [[Dumping Windows Hashes]] | 🟢 (loot) |

## 🔁 FOUND → NEXT (router)
| FINDING | GO |
|---|---|
| `SeImpersonate` Enabled | [[Token Privileges & Potato]] |
| Unquoted/weak-perm service | [[Windows Service Exploits]] |
| AlwaysInstallElevated=1 (both) | [[AlwaysInstallElevated]] |
| unattend/autologon/cmdkey cred | [[Windows Stored Credentials]] |
| Writable scheduled task/autorun | [[Scheduled Tasks & Autoruns]] |
| Writable DLL directory / writable PATH location | [[DLL Search Order & PATH Hijacking]] |
| Writable privileged registry key | [[Registry Permissions & UAC]] |
| Per-user COM/protocol/file-association setting read by elevated app | [[COM, File Association & Protocol Hijacks]] |
| Domain joined / domain credential / DC in scope | [[Windows to AD Pivot]] |
| Missing patch / readable SAM | [[Windows Kernel Exploits]] |
| Other Se* privilege enabled | [[Windows Special Privileges]] |
| Reached admin/SYSTEM | [[Dumping Windows Hashes]] → reuse |

## 🚧 STUCK?
No `SeImpersonate`? → PowerUp services, AlwaysInstallElevated, stored creds, WES-NG patches. winPEAS blocked by AV? → run `accesschk`/`reg query`/PowerUp modules individually. Then → [[Stuck — What Now]].

## ⚠️ COMMON MISTAKES
- Not checking `whoami /priv` first (miss easy Potato→SYSTEM) · wrong Potato for the build · ignoring PowerUp · overlooking stored creds · kernel exploits before token/service checks · not dumping hashes after SYSTEM.

## 📇 QUICK ORDER
baseline enum → `whoami /priv` (Potato) → PowerUp/services → AlwaysInstallElevated → stored creds → tasks → DLL/PATH + registry/COM → WES-NG patches → special privileges → dump hashes.
See [[Privilege Escalation Cheat Sheet]] for the condensed commands.

## 🌐 DOMAIN / NETWORK PATHS
These are not local privilege escalation checks. Once a domain credential or an AD-joined foothold is available, use [[Windows to AD Pivot]] then [[Active Directory]], [[BloodHound]], [[AD ACL Abuse]], [[Kerberos]], and [[SMB]]. They cover delegation, GPO/ACL control, AD CS exposure, and relay paths. Keep this folder focused on turning a local low-privileged shell into admin/SYSTEM.
