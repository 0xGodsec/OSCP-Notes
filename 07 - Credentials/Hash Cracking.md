# 🔑 Hash Cracking

> Turn a captured hash into a plaintext password with **hashcat** (GPU) or **john** (CPU). The two things that matter: **identify the hash type** (right `-m`/format) and pick a **wordlist + rules**. Never crack what you can pass ([[Pass-the-Hash]]).

Part of [[Credential Attacks]]. Related: [[Finding Credentials]] · [[Credential Reuse]] · [[AS-REP Roasting]] · [[Kerberoasting]]

---

## 🧠 THINK
- **Identify first** (`hashid`) — wrong mode = "cracks nothing".
- **Pass NT hashes** instead of cracking them where possible ([[Pass-the-Hash]]).
- Start with `rockyou.txt`; add **rules** (`best64`) before giving up.

## ⚡ IDENTIFY
```bash
hashid '<hash>'
```
```bash
hash-identifier
```

## 💥 HASHCAT (mode reference)
```bash
hashcat -m <mode> hashes.txt /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule
```
| Hash | -m | Seen in |
|---|---|---|
| MD5 | 0 | web apps |
| SHA1 | 100 | web apps |
| NTLM | 1000 | SAM, PtH |
| sha512crypt `$6$` | 1800 | Linux `/etc/shadow` |
| md5crypt `$1$` | 500 | old Linux/Cisco |
| bcrypt `$2*$` | 3200 | modern web apps |
| NetNTLMv2 | 5600 | Responder captures |
| AS-REP `$krb5asrep$` | 18200 | [[AS-REP Roasting]] |
| Kerberoast `$krb5tgs$` | 13100 | [[Kerberoasting]] |
| MySQL SHA1 | 300 | [[MySQL]] |
| MD5(WordPress) `$P$` | 400 | WordPress |

## 💥 JOHN + FORMAT CONVERTERS
```bash
john --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt
```
```bash
john --show hashes.txt
```
```bash
ssh2john id_rsa > h ; zip2john f.zip > h ; keepass2john f.kdbx > h ; office2john doc > h
```

## 💥 /etc/shadow
```bash
unshadow /etc/passwd /etc/shadow > unshadowed.txt
```
```bash
hashcat -m 1800 unshadowed.txt rockyou.txt        # sha512crypt $6$
```

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| Cracked plaintext | reuse everywhere → [[Credential Reuse]] |
| NT hash | don't crack — [[Pass-the-Hash]] |
| `$krb5*` cracked | domain cred → AD chain |
| KeePass/zip/ssh key cracked | open it → harvest more creds |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| rockyou finds nothing | add rules (`best64`, `rockyou-30000`); try bigger lists |
| "cracks nothing" instantly | wrong `-m`/format — re-check with `hashid` |
| Unknown format | hashcat example-hashes reference; paste structure |
| Still won't crack | pass the hash if NT; reuse known passwords; move on |

## 📇 CHEAT SHEET
```bash
hashid '<hash>'
```
```bash
hashcat -m <mode> hashes.txt rockyou.txt -r /usr/share/hashcat/rules/best64.rule
```
```bash
unshadow passwd shadow > u.txt ; hashcat -m 1800 u.txt rockyou.txt
```
**Kill shot:** identify → correct `-m` + wordlist/rules → plaintext → reuse.
