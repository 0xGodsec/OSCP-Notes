# 🏰 Active Directory (Hub)

> AD is its own world on the OSCP exam (the dedicated AD set). Spot a **domain** (DC = 88+389+445+53+135+3268) → switch to AD methodology. This is the index — set up, then follow the chain: enumerate → foothold cred → roast/spray → BloodHound → escalate → own the domain.

Related: [[SMB]] · [[Kerberos]] · [[LDAP]] · [[Credential Attacks]] · [[Windows Privilege Escalation]] · [[WinRM]] · [[Pivoting and Port Forwarding]]

---

## 🧠 IS THIS AD?
DC fingerprint: **88 (Kerberos) + 389/636 (LDAP) + 445 (SMB) + 53 (DNS) + 135/139 + 3268 (GC)**. `netexec smb $IP` shows the domain + hostname.

## ⚡ SETUP (do first — or Kerberos breaks)
```bash
export IP=10.10.10.10 DC=$IP DOMAIN=corp.local U=user P=pass
```
```bash
echo "$DC dc01.$DOMAIN $DOMAIN" | sudo tee -a /etc/hosts
```
```bash
sudo ntpdate $DC
```

---

## 🎯 THE CHAIN (click into each stage)
| # | Stage | Note |
|---|---|---|
| 1 | Enumerate (unauth users + authed dump) | [[AD Enumeration]] |
| 2 | AS-REP roast (no creds) | [[AS-REP Roasting]] |
| 3 | Password spray to a foothold cred | [[Password Spraying]] |
| 4 | Kerberoast (needs 1 cred) | [[Kerberoasting]] |
| 5 | Map paths to DA | [[BloodHound]] |
| 6 | Hop hosts / get shells | [[AD Lateral Movement]] |
| 7 | Abuse ACL edges | [[AD ACL Abuse]] |
| 8 | DCSync / NTDS / Golden Ticket | [[DCSync & Domain Dominance]] |

## 🔁 FOUND → NEXT (router)
| FINDING                  | GO                                                   |
| ------------------------ | ---------------------------------------------------- |
| Domain in `netexec smb`  | [[AD Enumeration]]                                   |
| Userlist (RID/kerbrute)  | [[AS-REP Roasting]] + [[Password Spraying]]          |
| AS-REP / Kerberoast hash | crack → [[Hash Cracking]]                            |
| Any domain cred          | [[Kerberoasting]] + [[BloodHound]]                   |
| `(Pwn3d!)`               | [[AD Lateral Movement]] → [[Dumping Windows Hashes]] |
| BloodHound ACL edge      | [[AD ACL Abuse]]                                     |
| DCSync rights / DA       | [[DCSync & Domain Dominance]]                        |
| GPP `cpassword`          | `gpp-decrypt` → [[Password Spraying]]                |

## 🚧 STUCK?
Kerberos skew → `ntpdate`; name resolution → `/etc/hosts` + `-ns $DC`; anon denied → get a cred (AS-REP/spray/another service); no BloodHound path → local privesc ([[Windows Privilege Escalation]]) → new creds → re-collect. Then → [[Stuck — What Now]].

## ⚠️ COMMON MISTAKES
- No `/etc/hosts` / using IP not FQDN (Kerberos fails) · ignored **clock skew** · spraying without checking **lockout policy** · skipping **BloodHound** · not reusing a foothold cred as **local admin on other hosts** · forgetting AS-REP roast needs **no creds**.

## 📇 QUICK ORDER
identify DC → /etc/hosts + clock → user enum → AS-REP/spray → foothold cred → Kerberoast + BloodHound → lateral/local admin → DCSync → Golden Ticket.
See [[Active Directory Cheat Sheet]] for the condensed command list.
