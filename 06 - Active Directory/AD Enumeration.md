# 🏰 AD Enumeration

> Map the domain — before and after you have a credential. Unauthenticated: users (RID/kerbrute), anonymous LDAP/SMB. Authenticated: users, groups, shares, policy, SPNs, and full BloodHound collection. Everything downstream (roasting, spraying, escalation) starts here.

Part of [[Active Directory]]. Related: [[SMB]] · [[LDAP]] · [[RPC]] · [[Kerberos]] · [[BloodHound]]

---

## 🧠 THINK
- **Set `/etc/hosts` + sync the clock first** — Kerberos breaks on bare IPs / skew.
- DC fingerprint: **88 + 389/636 + 445 + 53 + 135 + 3268**.
- No creds → harvest a **userlist** (RID brute, kerbrute, anon LDAP). One cred → dump **everything**.

## ⚡ SETUP
```bash
export IP=10.10.10.10 DC=$IP DOMAIN=corp.local
```
```bash
echo "$DC dc01.$DOMAIN $DOMAIN" | sudo tee -a /etc/hosts
```
```bash
sudo ntpdate $DC        # fix clock or Kerberos errors (KRB_AP_ERR_SKEW)
```

## ⚡ UNAUTHENTICATED (no creds yet)
Domain/host identity:
```bash
netexec smb $DC
```
Users via null session + RID brute:
```bash
netexec smb $DC -u '' -p '' --users --rid-brute
```

```bash
enum4linux-ng -A $DC
```
Anonymous LDAP:
```bash
netexec ldap $DC -u '' -p '' --users
```

```bash
ldapsearch -x -H ldap://$DC -b "DC=corp,DC=local"
```
Kerberos user enumeration (needs only a userlist):
```bash
kerbrute userenum -d $DOMAIN --dc $DC /usr/share/seclists/Usernames/xato-net-10-million-usernames.txt
```
**Save every username to `users.txt`.** → then [[AS-REP Roasting]] / [[Password Spraying]].

## ⚡ AUTHENTICATED (any valid cred)
```bash
export U=jdoe P='Password1'
```

```bash
netexec smb $DC -u $U -p $P --users --groups --shares --pass-pol
```

```bash
netexec ldap $DC -u $U -p $P --users
```

```bash
ldapdomaindump -u "$DOMAIN\\$U" -p $P $DC
```
Then collect BloodHound data → [[BloodHound]], and roast SPNs → [[Kerberoasting]].

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| Domain in `netexec smb` | set /etc/hosts + clock, full enum |
| Users (RID/kerbrute) | [[AS-REP Roasting]] + [[Password Spraying]] |
| Anon LDAP dump | grep descriptions for creds; SPN/preauth flags |
| Any valid cred | authed enum + [[Kerberoasting]] + [[BloodHound]] |
| `--pass-pol` lockout threshold | decide safe spray window |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Null/anon denied | need a cred — AS-REP roast, spray, or creds from another service |
| Name resolution fails | add DC+domain to `/etc/hosts`; use `-ns $DC` for bloodhound-python |
| Kerberos skew error | `sudo ntpdate $DC`; use FQDN not IP → [[Credentials Rejected]] |
| `enumdomusers` denied | `--rid-brute`; try guest; LDAP anon |

## 📇 CHEAT SHEET
```bash
echo "$DC dc01.$DOMAIN $DOMAIN" | sudo tee -a /etc/hosts ; sudo ntpdate $DC
```

```bash
netexec smb $DC -u '' -p '' --rid-brute
```

```bash
kerbrute userenum -d $DOMAIN --dc $DC users.txt
```

```bash
netexec smb $DC -u $U -p $P --users --groups --shares --pass-pol
```
**Kill flow:** identify DC → /etc/hosts+clock → userlist (RID/kerbrute) → cred → authed dump → BloodHound.
