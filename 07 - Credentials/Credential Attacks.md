# 🔑 Credential Attacks (Hub)

> The connective tissue of every OSCP box. **One credential found anywhere gets tested everywhere.** This is the index — find, crack, spray, pass, and reuse credentials. Every service note funnels here.

Related: [[SMB]] · [[SSH]] · [[HTTP]] · [[Windows Privilege Escalation]] · [[Active Directory]] · [[Shells]]

---

## 🧠 THE GOLDEN RULE
> **Every username, password, and hash you find → try it on every service on every host.**

Keep two live files during the exam:
```bash
# append constantly as you enumerate
users.txt        # every username seen anywhere
```

```bash
creds.txt        # user:pass pairs found
```

---

## 🎯 TECHNIQUES (click into each)
| Technique | Note |
|---|---|
| Where creds come from + username enumeration | [[Finding Credentials]] |
| Spray (1 pw → many users) + brute force | [[Password Spraying]] |
| Crack hashes (hashcat/john + modes) | [[Hash Cracking]] |
| Pass-the-Hash (NTLM without plaintext) | [[Pass-the-Hash]] |
| **Reuse everywhere** (the matrix) | [[Credential Reuse]] |

## 🔁 FOUND → NEXT (router)
| FINDING | GO |
|---|---|
| Plaintext password | [[Credential Reuse]] (+ [[Password Spraying]] to mutate) |
| NT hash | [[Pass-the-Hash]] (or [[Hash Cracking]]) |
| `$6$`/`$1$` shadow, web hash | [[Hash Cracking]] |
| Kerberos `$krb5*` | [[Hash Cracking]] (-m 18200/13100) |
| Username only | [[Finding Credentials]] → [[Password Spraying]] |
| SSH key / KeePass / zip | [[Hash Cracking]] (converters) → open → harvest |

## 🚧 STUCK?
Hash won't crack → rules/bigger lists, confirm type; spray locks accounts → check policy, 1 pw/window; cred works nowhere → keep it (host/service maybe not found yet), re-scan. Format/skew issues → [[Credentials Rejected]].

## ⚠️ COMMON MISTAKES
- Cracking a hash then **not reusing** the plaintext · brute-forcing without checking **lockout** · wrong **hash mode** · forgetting **pass-the-hash** · not **mutating** a found password · testing on **one host** only.

## 📇 QUICK ORDER
find ([[Finding Credentials]]) → identify+crack ([[Hash Cracking]]) or pass ([[Pass-the-Hash]]) → spray ([[Password Spraying]]) → **reuse on every service & host** ([[Credential Reuse]]).
See [[Credential Attacks Cheat Sheet]] for the condensed commands.
