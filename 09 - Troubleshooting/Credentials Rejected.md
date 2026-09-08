# 🧯 Credentials Rejected

> You have creds that *should* work but auth fails. Usually **wrong format**, **clock skew** (Kerberos/AD), the account **isn't allowed on that service**, or **lockout**. Work this list.

Related: [[Troubleshooting Methodology]] · [[Credential Attacks]] · [[Active Directory]] · [[Kerberos]]

---

## Check in order
1. **Username format** — try each form:
```
user        DOMAIN\user        user@domain.local        .\localuser
```
2. **Clock skew (Kerberos/AD)** — `KRB_AP_ERR_SKEW`:
```bash
sudo ntpdate $IP
```
3. **Right service for the account?** A user may auth to SMB but not WinRM (not in *Remote Management Users*); to the DB but not SSH. Test the reuse matrix ([[Credential Attacks]]).
4. **Local vs domain** — local account needs `.\user` / `-local-auth`; domain needs the FQDN.
5. **Lockout** — stop spraying; check policy:
```bash
rpcclient -U "" -N $IP -c "getdompwinfo"
```
6. **Quoting** — special chars in the password; wrap in single quotes; watch shell escaping.

## Symptom table
| Symptom | Cause | Fix |
|---|---|---|
| `STATUS_LOGON_FAILURE` | wrong creds/format | try all username forms; verify password |
| `KRB_AP_ERR_SKEW` | clock off | `ntpdate $IP` |
| `PRINCIPAL_UNKNOWN` | wrong domain/user | correct FQDN/case; add DC to `/etc/hosts` |
| Auth OK on SMB, fails WinRM | not authorised for that svc | use SMB/RDP; try other users |
| `ACCOUNT_LOCKED_OUT` | too many attempts | wait; stop spraying; smaller list |
| Works in browser, not CLI | cookie/session vs basic | replicate the exact auth the app expects |

## netexec sanity check
```bash
netexec smb $IP -u user -p 'pass'                  # (Pwn3d!)=admin, +=valid
```
```bash
netexec smb $IP -u user -p 'pass' --local-auth      # local account
```

## Rules
- Try **every username format** before concluding the cred is wrong.
- **Sync the clock** for anything Kerberos.
- A rejected cred on one service may still win on another — **run the reuse matrix**.
