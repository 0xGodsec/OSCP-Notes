# 🖥️ RDP — Port 3389

> **Remote Desktop Protocol** (3389/tcp; NTLM/Kerberos auth, **NLA** requires creds pre-session). GUI Windows access. On OSCP: reuse a credential/hash to log in, occasionally BlueKeep (very old, unpatched Win7/2008), pass-the-hash via Restricted Admin mode, and it's a handy way to *interact* with GUI-only privesc or run tools. Also a spray/brute target (watch lockouts). `rdp-ntlm-info` leaks domain/hostname/OS build with **no auth**.

Related: [[Credential Attacks]] · [[SMB]] · [[WinRM]] · [[Windows Privilege Escalation]]

---

## 🧠 PORT 3389 → THINK
- **Have creds/hash?** → `xfreerdp` to log in (GUI).
- **NLA on?** need valid creds to even reach the login. **Off** → could brute/see login screen.
- **BlueKeep (CVE-2019-0708)** on old Win7/2008 (situational, can crash).
- **Restricted Admin mode** → **pass-the-hash** RDP.
- Great for **GUI-only** exploitation and dropping/running tools.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```
```bash
nmap -p3389 -sV --script rdp-ntlm-info,rdp-enum-encryption $IP   # hostname/domain/NLA
```
```bash
xfreerdp /u:user /p:pass /v:$IP /cert:ignore          # log in if you have creds
```
**Verdict:** creds work → GUI session. Old OS + no NLA → check BlueKeep. Else it's a reuse/brute target.

## ⏱️ ENUMERATE
```bash
nmap -p3389 --script rdp-ntlm-info $IP           # leaks hostname, domain, OS build (no creds!)
```
```bash
netexec rdp $IP -u users.txt -p passwords.txt --continue-on-success
```
Log in:
```bash
xfreerdp /u:user /p:'pass' /v:$IP /cert:ignore /dynamic-resolution +clipboard
```
```bash
xfreerdp /u:user /pth:<NThash> /v:$IP /cert:ignore     # pass-the-hash (Restricted Admin)
```
**Look for:** `rdp-ntlm-info` domain/hostname/OS (free recon), which creds authenticate.

## 🗡️ EXPLOIT
- 🟢 **Credential/hash reuse → GUI login.**
- 🟡 **Spray/brute** (lockout-aware) with a userlist.
- 🟡 **Pass-the-hash** via `/pth` (Restricted Admin mode).
- 🔵 **BlueKeep (CVE-2019-0708)** — Win7/2008 R2 unpatched; use with care (can BSOD).

RDP turns creds into a **full GUI** — priceless for GUI-only apps, installers, and some privesc. After an admin GUI session → run winPEAS/mimikatz → [[Windows Privilege Escalation]].

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Cred works | GUI access | xfreerdp session | interactive desktop |
| rdp-ntlm-info | Free recon | note domain/OS | plan AD/privesc |
| NT hash only | PtH | `xfreerdp /pth` | session |
| Old Win7/2008 | BlueKeep? | scanner + PoC (careful) | SYSTEM |
| Admin GUI | Loot/privesc | run winPEAS/mimikatz | escalate/reuse |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| NLA blocks (no creds) | Get creds first (SMB/web/AD); NLA needs them |
| Cred rejected | Try other creds/hash; user may lack RDP rights (Remote Desktop Users) |
| `/pth` fails | Restricted Admin disabled — use plaintext or WinRM/psexec instead |
| Black screen/session busy | Someone's logged in; try `/multimon` off, reconnect, or use SMB exec |
| BlueKeep crashes target | High-risk exploit; prefer creds; if you must, match exact build |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** forgetting `rdp-ntlm-info` gives **free domain/OS recon** · not trying **PtH** (`/pth`) · brute-forcing into **lockouts** (check policy) · reaching for BlueKeep before trying credential reuse · missing that the user needs to be in **Remote Desktop Users**.
**Reuse:** same Windows cred/hash → [[SMB]], [[WinRM]], [[MSSQL]], [[LDAP]]. See [[Credential Attacks]].
**Don't miss:** `rdp-ntlm-info` recon (domain/OS, no creds) · reuse every cred/hash (`/pth`) · check Remote Desktop Users membership · BlueKeep only on old unpatched (careful).
**Stop when:** no creds and not BlueKeep-vulnerable → move on. With a session → work shifts to [[Windows Privilege Escalation]]. RDP is usually the GUI cash-out for a credential — prefer WinRM/psexec for automation; use RDP when you need a desktop.

## 📇 CHEAT SHEET
```bash
nmap -p3389 --script rdp-ntlm-info $IP
```
```bash
netexec rdp $IP -u users.txt -p passwords.txt --continue-on-success
```
```bash
xfreerdp /u:user /p:'pass' /v:$IP /cert:ignore +clipboard /dynamic-resolution
```
```bash
xfreerdp /u:user /pth:<NThash> /v:$IP /cert:ignore        # pass-the-hash
```
**Kill shots:** cred/hash → xfreerdp GUI · rdp-ntlm-info recon · BlueKeep (situational).
