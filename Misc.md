# 🧰 Misc — Quick Jump Index

> Catch-all landing page for the cross-cutting basics you reach for mid-box. Most of these have a full note elsewhere — this is just the fast index. Only content with **no other home** (file/content search) lives here inline.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]].

---

## 🚀 Jump to the real note

| I need to… | Go |
|---|---|
| Move files onto / off a target | [[File Transfer]] · [[File Transfer Cheat Sheet]] |
| Host files over SMB | [[SMB]] · [[File Transfer]] |
| Transfer files over RDP | [[RDP]] |
| Catch a reverse / bind shell | [[Reverse & Bind Shells]] · [[Reverse Shell Cheat Sheet]] |
| Upgrade a raw shell to a full TTY | [[Shell Upgrade & TTY]] |
| Build a payload / go to Meterpreter | [[msfvenom Payloads]] |
| SSH tunnel / port forward | [[SSH Tunneling]] |
| Pivot through a compromised host | [[Pivoting and Port Forwarding]] · [[Chisel]] · [[Ligolo-ng]] · [[Proxychains & SOCKS]] |
| Run privesc enum scripts | [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]] · [[Privilege Escalation Cheat Sheet]] |
| Find / reuse credentials | [[Finding Credentials]] · [[Credential Attacks]] |
| Clean up after the box | [[Post-Engagement Cleanup]] |
| Connect with FreeRDP | [[RDP]] |

---

## 🔎 File & Content Search

> The one thing without a dedicated note. Hunt for flags (`local.txt` / `proof.txt`), configs, keys, and creds.

### Windows
```powershell
# by extension / name (whole drive, quiet on errors)
Get-ChildItem -Path C:\ -Include *.txt -Recurse -ErrorAction SilentlyContinue
gci C:\ -Include *.txt,*.ini,*.config,*.xml,*.kdbx,*.ps1 -Recurse -EA SilentlyContinue
gci C:\Users\ -Recurse -Include local.txt,proof.txt -EA SilentlyContinue
# by CONTENT
Get-ChildItem C:\ -Recurse -EA SilentlyContinue | Select-String -Pattern "password" -List
```
```cmd
:: CMD equivalents
dir C:\ /s /b /a | findstr /i "\.txt$"
where /r C:\ *.kdbx
```

### Linux
```bash
find / -type f -iname "*.txt" 2>/dev/null          # by name (case-insensitive)
```

```bash
find / -name "local.txt" -o -name "proof.txt" 2>/dev/null
```

```bash
find / -name "id_rsa" 2>/dev/null                  # SSH keys
```

```bash
locate "*.txt"                                       # fast (needs updatedb)
```

```bash
grep -rin "password" / 2>/dev/null                  # by content
```

```bash
find / -type f -mmin -10 2>/dev/null               # recently modified
```

> 🎯 Exam flags are usually `local.txt` (user home/Desktop) and `proof.txt` (root/admin dir). Cross-reference interesting binaries against **GTFOBins** (Linux) / **LOLBAS** (Windows).
