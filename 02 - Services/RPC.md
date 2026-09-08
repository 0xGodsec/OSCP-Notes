# 🔧 MSRPC — Port 135 (+ 593, 49152+)

> **Microsoft RPC endpoint mapper** (Windows). Port 135 is the "phone directory" that tells clients which high port (49152+) a given RPC service listens on (593 = RPC-over-HTTP). Real enum happens with **`rpcclient` binding named pipes (`\pipe\samr`, `\pipe\lsarpc`) over SMB/445**, so "RPC enumeration" is really SMB-transported: pull users, groups, RIDs, password policy, and domain info — often **without credentials** (null/guest session; modern Windows often restricts these). It feeds [[SMB]] and [[Active Directory]].

Related: [[SMB]] · [[Active Directory]] · [[LDAP]] · [[Credential Attacks]]

---

## 🧠 PORT 135 → THINK
- **Windows box.** 135 almost always means Windows.
- Real enum happens with **`rpcclient` against 445**, not 135 directly.
- Try **null session** first: `rpcclient -U "" -N`.
- **`enumdomusers`** → usernames for spraying/AS-REP.
- 135 + 139/445 + 3389/5985 = classic Windows target → pivot to AD notes.
- 593 = RPC-over-HTTP; 49152+ = the dynamic ports 135 hands out.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p135,139,445 -sV $IP
```

```bash
rpcclient -U "" -N $IP -c "srvinfo;enumdomusers"   # null session probe
```
**Verdict:** null session returns users/info → enumerate fully. Access denied → need creds; note and pivot.

## ⏱️ ENUMERATE
```bash
# rpcclient (interacts over 445) — the workhorse. Null; if denied try guest or authenticated.
rpcclient -U "" -N $IP                 # null / anonymous
```

```bash
rpcclient -U "guest%" $IP              # guest, empty password
```

```bash
rpcclient -U 'DOMAIN\user%Pass' $IP    # authenticated (much more data: enumprivs, LSA lookups)
# Inside rpcclient:
#   srvinfo              -> OS/version
#   enumdomusers         -> users (+RIDs)      | enumdomgroups -> groups
#   querydominfo         -> domain, server role
#   getdompwinfo         -> password policy (lockout!)
#   queryuser 0x1f4      -> 0x1f4=500=Administrator
#   lookupnames administrator / lookupsids S-1-5-21-...-500   -> name<->SID
```

```bash
# RID cycling when enumdomusers is blocked — often still returns names
netexec smb $IP -u '' -p '' --rid-brute 4000
```

```bash
netexec smb $IP -u guest -p '' --rid-brute
```

```bash
# Endpoint mapper dump + consolidated Windows enum
impacket-rpcdump $IP                          # or: rpcdump.py @$IP — list RPC services
```

```bash
nmap -p135 --script msrpc-enum $IP
```

```bash
enum4linux-ng -A $IP | tee nmap/enum4linux.txt
```
**Look for:** usernames (→ spray/AS-REP, save to `users.txt`), password policy (→ safe to spray?), domain name, admin RIDs; rpcdump exposing extra services; enum4linux consolidating users/groups/shares/policy.

## 🗡️ EXPLOIT
- 🟢 **Null/guest user enumeration** → userlist → spray / AS-REP roast ([[Active Directory]]).
- 🟢 **RID cycling** when direct enum is blocked.
- 🟡 **Password policy read** → decide spray safety.
- 🔵 **rpcdump** reveals extra RPC services (task scheduler, printer/spooler) → occasionally an AD attack path (e.g., spooler coercion — advanced/situational).
- 🔵 **Legacy DCOM RCE (MS03-026)** — only on very old hosts; confirm version first, don't assume.

135/RPC rarely *is* the foothold. The chain:
1. Harvest users via rpcclient/RID-brute.
2. Feed them to spray or AS-REP: `impacket-GetNPUsers domain/ -usersfile users.txt -no-pass -dc-ip $IP`.
3. Crack/obtain a cred → authenticate to [[SMB]] / [[WinRM]] / [[RDP]]. With a cred, re-run rpcclient authenticated for deeper data.

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Null session works | Anonymous enum | `enumdomusers`, `getdompwinfo` | userlist + policy |
| Users listed | Spray/roast fuel | save to users.txt → AS-REP/spray | possible cred |
| enumdomusers denied | Restricted | `--rid-brute` | users anyway |
| Password policy w/ high/zero lockout | Safe to spray | netexec spray | cred |
| Domain name + DC role | It's a DC | go [[Active Directory]] | Kerberos attacks |
| rpcdump shows spooler | Coercion maybe | situational (advanced) | — |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `NT_STATUS_ACCESS_DENIED` on null | Try `guest%`; then `--rid-brute`; else you need creds |
| rpcclient connects but no users | Use RID cycling; try enum4linux-ng; enumerate via [[LDAP]] instead |
| Only 135 open, 445 filtered | rpcclient (needs 445) won't work — try `impacket-rpcdump`; enumerate via other services |
| Everything denied | Get a cred elsewhere, come back authenticated |
| Modern Server 2019/2022 | Null sessions usually disabled — expect to need creds |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** attacking port 135 directly instead of using **rpcclient over 445** · **spraying before reading the lockout policy** (`getdompwinfo`) → locking accounts on the exam · giving up when `enumdomusers` is denied (**try RID cycling**) · not saving harvested users to a reusable `users.txt`.
**Reuse:** usernames → spray [[SMB]], [[WinRM]], [[RDP]], [[MSSQL]]; domain confirmed → [[LDAP]] + [[Active Directory]] (Kerberoast/AS-REP). See [[Credential Attacks]].
**Don't miss:** `rpcclient -U "" -N` and `-U guest%` · `enumdomusers`, `enumdomgroups`, `querydominfo` · **`getdompwinfo`** (lockout before spraying!) · `--rid-brute` if direct enum denied · `impacket-rpcdump` for extra RPC services · save all users → `users.txt`.
**Stop when:** null/guest denied AND RID cycling denied AND no creds → exhausted anonymously; acquire a credential from another service and return. With a userlist, action moves to [[Credential Attacks]] / [[Active Directory]].

## 📇 CHEAT SHEET
```bash
nmap -p135,139,445 -sV $IP
```

```bash
rpcclient -U "" -N $IP -c "enumdomusers;enumdomgroups;querydominfo;getdompwinfo"
```

```bash
netexec smb $IP -u '' -p '' --rid-brute        # users when enum denied
```

```bash
impacket-rpcdump $IP                            # list RPC services
```

```bash
enum4linux-ng -A $IP                            # consolidated Windows enum
```
**Kill shots:** null session → `enumdomusers` → userlist → AS-REP/spray → cred → WinRM/SMB shell.
