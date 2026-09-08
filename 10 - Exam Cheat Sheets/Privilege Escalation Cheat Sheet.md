# 📇 Privilege Escalation Cheat Sheet

> Scan-only fast checks. Full detail: [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]]. Run the automated tool AND the manual quick-wins.

## First move (both)
Get OS + identity, then run the enum script.
```bash
id; whoami; hostname; uname -a          # Linux
```
```cmd
whoami /all & systeminfo                 # Windows
```

## Linux — quick wins (in order)
```bash
sudo -l                                   # NOPASSWD/known -> GTFOBins
```
```bash
find / -perm -4000 -type f 2>/dev/null    # SUID -> GTFOBins
```
```bash
getcap -r / 2>/dev/null                    # capabilities
```
```bash
cat /etc/crontab; ls -la /etc/cron.*       # writable cron scripts
```
```bash
grep -riE 'password|secret' /home /var/www /etc 2>/dev/null   # creds
```
Then:
```bash
./linpeas.sh | tee linpeas.txt
```

## Windows — quick wins (in order)
```cmd
whoami /priv                               :: SeImpersonate/SeBackup/etc.
```
- `SeImpersonatePrivilege` → **PrintSpoofer / GodPotato → SYSTEM**.
```cmd
cmdkey /list                               :: saved creds -> runas /savecred
```
```cmd
reg query HKLM /f password /t REG_SZ /s    :: registry creds
```
```cmd
sc query type= service                     :: unquoted paths / weak svc perms
```
Then:
```cmd
.\winPEASx64.exe
```

## Kernel / patches
```bash
# Linux: uname -a -> searchsploit ; Windows: systeminfo -> WES-NG
```

## Rules
- Run **linPEAS/winPEAS** but also do the manual quick-wins above.
- `sudo -l` (Linux) and `whoami /priv` (Windows) are the two highest-value single commands.
- Every cred found → reuse ([[Credential Attacks]]).
