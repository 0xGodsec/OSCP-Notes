# 🏰 BloodHound

> Collect the domain's users/groups/ACLs/sessions and let BloodHound **draw the shortest path to Domain Admin**. It turns "I have a cred" into "here is the exact chain to own the domain." Run it as soon as you have any valid credential.

Part of [[Active Directory]]. Related: [[AD Enumeration]] · [[AD ACL Abuse]] · [[AD Lateral Movement]] · [[DCSync & Domain Dominance]]

---

## 🧠 THINK
- Needs **one valid domain credential**.
- Collect with `bloodhound-python` (from Kali) or SharpHound (on a Windows shell), import the ZIP into the BloodHound GUI.
- **Mark owned** nodes; run pre-built queries: *Shortest Paths to Domain Admins*, *from Owned Principals*.
- The edges (GenericAll, WriteDACL, AddMember, AdminTo, CanRDP, delegation) tell you the next move.

## ⚡ COLLECT
From Kali (remote collection):
```bash
bloodhound-python -u $U -p $P -d $DOMAIN -dc dc01.$DOMAIN -c all -ns $DC
```
From a Windows foothold (SharpHound):
```powershell
.\SharpHound.exe -c All
```
This produces `.json`/a ZIP → import into the BloodHound GUI (`sudo neo4j start`, then the app).

## 🔎 KEY QUERIES / EDGES
| Edge / query | Meaning | Route |
|---|---|---|
| Shortest Path to Domain Admins | the plan | follow the edges |
| AdminTo / CanRDP / CanPSRemote | local admin/remote on a host | [[AD Lateral Movement]] |
| GenericAll / GenericWrite / WriteDACL / Owns | control over an object | [[AD ACL Abuse]] |
| ForceChangePassword | reset another user's pw | [[AD ACL Abuse]] |
| AddMember | add self to a group | [[AD ACL Abuse]] |
| GetChanges + GetChangesAll | DCSync rights | [[DCSync & Domain Dominance]] |
| HasSession (as target) | creds may be cached there | own that host, dump |

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| Path to DA drawn | execute each edge in order |
| ACL edge over a principal | [[AD ACL Abuse]] |
| AdminTo a host | [[AD Lateral Movement]] → dump → reuse |
| DCSync rights | [[DCSync & Domain Dominance]] |
| No path from owned | local privesc on a host → new creds → re-collect |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Collection fails (DNS/skew) | `-ns $DC`, `/etc/hosts`, `sudo ntpdate $DC` |
| neo4j won't start | `sudo neo4j start`; default creds neo4j/neo4j (change on first login) |
| No path shown | mark more owned nodes; local privesc → new creds → recollect; look for ACLs manually |
| SharpHound blocked by AV | use `bloodhound-python` from Kali instead |

## 📇 CHEAT SHEET
```bash
sudo neo4j start
```

```bash
bloodhound-python -u $U -p $P -d $DOMAIN -dc dc01.$DOMAIN -c all -ns $DC
```
Import ZIP → mark owned → *Shortest Paths to Domain Admins*.
**Kill shot:** cred → BloodHound → follow the edge chain to DA.
