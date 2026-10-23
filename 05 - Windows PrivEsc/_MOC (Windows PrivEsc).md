# 🪟 05 — Windows PrivEsc (Map of Content)

> Low-priv Windows shell → **SYSTEM/Administrator**. Start at the hub for the quick checks + priority order, then dive into a technique.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]]. Working hub: [[Windows Privilege Escalation]].

## Notes in this folder
- [x] [[Windows Privilege Escalation]] — **hub / index** (first commands, automated enum, order)
- [x] [[Windows PrivEsc Enumeration]] — baseline host/user/process/policy/filesystem triage (first)
- [x] [[Token Privileges & Potato]] — `SeImpersonate` → PrintSpoofer/GodPotato → SYSTEM 🟢🟢
- [x] [[Windows Service Exploits]] — unquoted paths / weak perms / writable binary 🟢
- [x] [[AlwaysInstallElevated]] — both keys = 1 → malicious MSI 🟢
- [x] [[Windows Stored Credentials]] — registry/unattend/cmdkey/PS history 🟢
- [x] [[Scheduled Tasks & Autoruns]] — writable target run as SYSTEM 🟡
- [x] [[DLL Search Order & PATH Hijacking]] — writable DLL search location / PATH entry 🟡
- [x] [[Registry Permissions & UAC]] — weak registry ACLs; UAC context and limits 🟡
- [x] [[COM, File Association & Protocol Hijacks]] — per-user handler hijacks; validate an elevated consumer 🟡
- [x] [[Application Control & UAC]] — AppLocker/WDAC policy + UAC boundary (context, not a privesc by itself)
- [x] [[Windows to AD Pivot]] — route AD/relay/delegation/GPO/AD CS checks to the domain methodology
- [x] [[Windows Kernel Exploits]] — WES-NG missing patches / SeriousSAM 🟡
- [x] [[Windows Special Privileges]] — SeBackup/SeRestore/SeTakeOwnership/SeLoadDriver… 🟡
- [x] [[Dumping Windows Hashes]] — SAM/LSA/NTDS → PtH & reuse (loot)

## Order
Use the linear [[Windows Privilege Escalation#🧭 EXAM WORKFLOW — low-priv shell → SYSTEM|foothold → SYSTEM workflow]]:

`whoami /priv` → other special privileges → stored creds → services → AlwaysInstallElevated/registry → tasks/autoruns → DLL/PATH → COM/handlers → patch checks → AD pivot.

After a positive finding, stop and validate that route before continuing. Keep kernel LPE last; after Administrator/SYSTEM, collect appropriate credentials/hashes via [[Dumping Windows Hashes]].
Condensed commands: [[Privilege Escalation Cheat Sheet]].

## Scope boundary
For domain escalation after obtaining a foothold, use [[Windows to AD Pivot]], [[Active Directory]], [[BloodHound]], [[AD ACL Abuse]], [[Kerberos]], and [[SMB]]. Those notes own delegation, GPO/ACL, AD CS, and relay workflows.
