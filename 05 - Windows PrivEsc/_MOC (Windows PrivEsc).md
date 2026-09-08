# 🪟 05 — Windows PrivEsc (Map of Content)

> Low-priv Windows shell → **SYSTEM/Administrator**. Start at the hub for the quick checks + priority order, then dive into a technique.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]]. Working hub: [[Windows Privilege Escalation]].

## Notes in this folder
- [x] [[Windows Privilege Escalation]] — **hub / index** (first commands, automated enum, order)
- [x] [[Token Privileges & Potato]] — `SeImpersonate` → PrintSpoofer/GodPotato → SYSTEM 🟢🟢
- [x] [[Windows Service Exploits]] — unquoted paths / weak perms / writable binary 🟢
- [x] [[AlwaysInstallElevated]] — both keys = 1 → malicious MSI 🟢
- [x] [[Windows Stored Credentials]] — registry/unattend/cmdkey/PS history 🟢
- [x] [[Scheduled Tasks & Autoruns]] — writable target run as SYSTEM 🟡
- [x] [[Windows Kernel Exploits]] — WES-NG missing patches / SeriousSAM 🟡
- [x] [[Windows Special Privileges]] — SeBackup/SeRestore/SeTakeOwnership/SeLoadDriver… 🟡
- [x] [[Dumping Windows Hashes]] — SAM/LSA/NTDS → PtH & reuse (loot)

## Order
`whoami /priv` (Potato) → PowerUp/services → AlwaysInstallElevated → stored creds → tasks → WES-NG → special privileges → dump hashes.
Condensed commands: [[Privilege Escalation Cheat Sheet]].
