# 🩸 BloodHound — Master Reference

> The deep-dive companion to [[BloodHound]]. Goal of this note: **enumerate AD faster** — collect once, then let the graph answer every "who/where/what can I reach" question instead of hand-querying LDAP. One good collection + the Cypher library below replaces hours of manual enum.

Part of [[Active Directory]]. Quick stage-note: [[BloodHound]]. Related: [[AD Enumeration]] · [[Which AD Attack, When]] · [[AD ACL Abuse]] · [[AD Lateral Movement]] · [[DCSync & Domain Dominance]] · [[Kerberoasting]] · [[AS-REP Roasting]] · [[ADCS (Certipy)]]

```bash
export DC=<DC_IP> DOMAIN=<domain.tld> U=<user> P='<pass>'
echo "$DC dc01.$DOMAIN $DOMAIN" | sudo tee -a /etc/hosts ; sudo ntpdate $DC   # always first
```

---

## 🧠 WHY IT MAKES ENUM FASTER
Manual AD enum = many separate LDAP/SMB/RPC queries (users, groups, memberships, ACLs, SPNs, delegation, trusts) that you then correlate **in your head**. BloodHound pulls all of it **once** into a graph and does the correlation for you:
- "Which of my creds is admin somewhere?" → one query, not `netexec` across a range.
- "Is anything Kerberoastable / AS-REP-roastable?" → one query, not `GetUserSPNs` + `GetNPUsers` guesswork.
- "From the user I just owned, what's the path to DA?" → it draws it.

**Rule: the moment you hold any one valid domain credential, collect.** Re-collect every time you own a new host or user (new sessions/ACLs appear).

---

## 📦 VERSIONS — match collector to GUI (the #1 silent failure)
| Stack | GUI | Collector JSON | Notes |
|---|---|---|---|
| **BloodHound CE** (current) | web UI at `http://localhost:8080` (Docker) | SharpHound ≥ 2.x, `bloodhound-ce-python`, `nxc --bloodhound` | ships with `bloodhound-cli`; Postgres + Neo4j in compose |
| **Legacy 4.x** | Electron app + `neo4j` | SharpHound 1.x, `bloodhound-python` (legacy) | the classic Kali package |

> Mixing a **new collector** with an **old GUI** (or vice-versa) imports **nothing** with no clear error. If an import yields 0 new objects, suspect a version mismatch first. On modern Kali, prefer **CE**.

---

## ⚡ SETUP ON KALI

**BloodHound CE (recommended):**
```bash
pipx install bloodhound-cli        # or: curl the release binary
bloodhound-cli install             # pulls the Docker compose stack
bloodhound-cli start               # UI on http://localhost:8080 (default admin set on first run)
```
**Legacy (neo4j + app):**
```bash
sudo neo4j start                   # first login at http://localhost:7474 — default neo4j:neo4j, change it
bloodhound &                       # the Electron GUI → log into neo4j
```

---

## 🛰️ COLLECTION — pick the method for the situation

### A. Remote from Kali (no shell needed) — the default
```bash
# Legacy GUI:
bloodhound-python   -u $U -p "$P" -d $DOMAIN -dc dc01.$DOMAIN -ns $DC -c all --zip
# CE GUI:
bloodhound-ce-python -u $U -p "$P" -d $DOMAIN -dc dc01.$DOMAIN -ns $DC -c all --zip
```

### B. Via netexec (quick, CE-format, folds into your usual workflow)
```bash
nxc ldap $DC -u $U -p "$P" --bloodhound --collection all --dns-server $DC
```

### C. From a Windows foothold (SharpHound)
```powershell
# EXE or PS1 — run in the user's context:
.\SharpHound.exe -c All --zipfilename loot
powershell -ep bypass -c "IEX(gc .\SharpHound.ps1 -Raw); Invoke-BloodHound -CollectionMethod All"
```

### 🏃 The FAST path — `DCOnly`
When you want the map **now** and don't yet need host sessions/local-admin data:
```bash
bloodhound-python -u $U -p "$P" -d $DOMAIN -dc dc01.$DOMAIN -ns $DC -c DCOnly --zip
```
`DCOnly` talks **only to the DC over LDAP** — no touching member hosts, so it's fast and quiet. You still get **groups, ACLs, Kerberoastable SPNs, AS-REP users, delegation, trusts, GPOs**. You *miss* `HasSession` / `AdminTo` gathered from hosts → re-run with `-c all` (or `Session`,`LoggedOn`) once you want lateral data.

### Collection methods worth knowing
| `-c` / CollectionMethod | Pulls | Use when |
|---|---|---|
| `DCOnly` | LDAP objects, ACLs, SPNs, delegation, trusts, GPOs | **fast first look**, quiet |
| `all` / `All` | DCOnly **+** sessions + local admin from hosts | full picture before lateral |
| `Session` / `LoggedOn` | who's logged on where | hunting cached creds |
| `ACL` | just the ACL edges | targeted ACL hunt |
| `Trusts` | domain/forest trusts | multi-domain |

---

## 🖇️ INGEST
- **CE:** UI → *Administration → File Ingest → Upload* the `.zip`.
- **Legacy:** drag the `.zip` onto the GUI window.
- Then **right-click your foothold principal → Mark as Owned** (do this for every cred/host you control — queries from "Owned" depend on it).

---

## 🔎 FAST-ENUM CYPHER LIBRARY (paste into the search bar's raw query box)
These answer the questions you'd otherwise script by hand. Replace `DOMAIN.TLD` with your upper-cased domain.

**Everything I can attack right now, from what I own:**
```cypher
MATCH p=shortestPath((n)-[*1..]->(m)) WHERE n.owned=true AND m<>n RETURN p
```
**Shortest path from Owned → Domain Admins:**
```cypher
MATCH (n {owned:true}),(g:Group) WHERE g.name STARTS WITH 'DOMAIN ADMINS@'
MATCH p=shortestPath((n)-[*1..]->(g)) RETURN p
```
**Kerberoastable users (have SPN):**
```cypher
MATCH (u:User {hasspn:true}) RETURN u.name, u.serviceprincipalnames ORDER BY u.name
```
**AS-REP roastable (pre-auth not required):**
```cypher
MATCH (u:User {dontreqpreauth:true}) RETURN u.name
```
**Where is a given user/group local admin (AdminTo):**
```cypher
MATCH p=(u {name:'SVC_X@DOMAIN.TLD'})-[:AdminTo|MemberOf*1..]->(c:Computer) RETURN p
```
**Unconstrained delegation computers (juicy):**
```cypher
MATCH (c:Computer {unconstraineddelegation:true}) RETURN c.name
```
**Constrained delegation (who → what service):**
```cypher
MATCH (a)-[:AllowedToDelegate]->(c:Computer) RETURN a.name, c.name
```
**Users whose password is set in the `description` field (classic leak):**
```cypher
MATCH (u:User) WHERE u.description IS NOT NULL RETURN u.name, u.description
```
**Who can DCSync (GetChanges + GetChangesAll):**
```cypher
MATCH p=(n)-[:DCSync|GetChanges|GetChangesAll*1..]->(d:Domain) RETURN p
```
**High-value targets reachable from Owned within N hops** (bump the `3`):
```cypher
MATCH p=(n {owned:true})-[*1..3]->(m {highvalue:true}) RETURN p
```
**Computers where a Domain Admin has a session (go own these):**
```cypher
MATCH p=(c:Computer)-[:HasSession]->(u:User)-[:MemberOf*1..]->(g:Group)
WHERE g.name STARTS WITH 'DOMAIN ADMINS@' RETURN p
```
**All outbound control edges from a principal (what does owning X give me?):**
```cypher
MATCH p=(x {name:'USER@DOMAIN.TLD'})-[r]->(y) RETURN p
```

> Built-in queries cover most of this too (*Shortest Paths to Domain Admins*, *…from Owned Principals*, *Find Kerberoastable Accounts*, *Find Computers with Unconstrained Delegation*, *Find AS-REP Roastable Users*, *Shortest Path to High Value Targets*). Use those first; drop to raw Cypher when you need a custom angle.

> 💡 **On BloodHound CE?** Pre-load these as one-click saved-query buttons before exam day: [[BloodHound — Custom Cypher Queries (CE)]] (15 queries + bulk-import loader).

---

## 🧭 EDGE → ABUSE (read an edge, know the command)
| Edge in the graph | What it means | Do this | Note |
|---|---|---|---|
| `AdminTo` | local admin on that computer | psexec/wmiexec → dump SAM/LSA | [[AD Lateral Movement]] |
| `CanRDP` / `CanPSRemote` | interactive / WinRM to host | `xfreerdp` / `evil-winrm` | [[AD Lateral Movement]] |
| `HasSession` | that user's creds cached on host | own host → `lsassy`/secretsdump | [[DCSync & Domain Dominance]] |
| `MemberOf` | group membership (transitive) | inherit the group's rights | — |
| `GenericAll` / `Owns` | full control of object | reset pw / targeted roast / shadow-cred | [[AD ACL Abuse]] |
| `GenericWrite` / `WriteProperty` | write attrs | set SPN → Kerberoast; set logon script | [[AD ACL Abuse]] |
| `ForceChangePassword` | reset their password | `net rpc password` / `bloodyAD` | [[AD ACL Abuse]] |
| `AddMember` | add to a group | `bloodyAD add groupMember` | [[AD ACL Abuse]] |
| `WriteDACL` / `WriteOwner` | rewrite the ACL | grant self DCSync → dump | [[AD ACL Abuse]] → [[DCSync & Domain Dominance]] |
| `AllowedToDelegate` | constrained delegation | `getST -impersonate` (S4U) | [[Kerberoasting]] family |
| `GetChanges` + `GetChangesAll` | DCSync rights | `secretsdump -just-dc` | [[DCSync & Domain Dominance]] |
| `AddKeyCredentialLink` | shadow credentials | `certipy shadow` / `pywhisker` → PKINIT | [[ADCS (Certipy)]] |

Each row's command detail lives in [[AD ACL Abuse]] and [[Which AD Attack, When]] — this table is the lookup.

---

## 🖼️ READING THE GRAPH FAST (the mental loop)
1. **Mark everything you own** (users + computers) → `owned:true`.
2. Run **Shortest Paths from Owned Principals to Domain Admins**. Path exists → execute it edge-by-edge, left to right.
3. No path? Run the **fast-enum queries**: Kerberoastable, AS-REP, unconstrained delegation, DCSync-capable, description-field passwords. Any hit = a new lead → crack/abuse → new cred → **Mark as Owned → re-query**.
4. Still nothing? You likely need **local privesc on a reachable host** ([[Windows Privilege Escalation]]) → dump new creds → **re-collect** (`-c all`) so fresh sessions/ACLs appear.
5. Every new credential loops you back to step 1.

---

## 🚧 TROUBLESHOOTING
| Problem | Fix |
|---|---|
| Collection fails: DNS / "could not resolve" | add `-ns $DC`, put the DC in `/etc/hosts` as FQDN |
| `KRB_AP_ERR_SKEW` / clock errors | `sudo ntpdate $DC` (or `rdate`) before collecting |
| Import adds **0 objects** | **version mismatch** — collector JSON vs GUI (CE ↔ legacy); re-collect with the matching tool |
| neo4j won't start / won't connect | `sudo neo4j start`; reset creds at `:7474`; check port 7687 free |
| CE UI empty after upload | wait for ingest to finish (check *File Ingest* status); refresh |
| SharpHound killed by AV | collect remotely with `bloodhound-python` / `nxc --bloodhound` from Kali instead |
| LDAPS required / LDAP signing | add `-dc` FQDN; try `--use-ldaps` (bloodhound-python) |
| No `AdminTo`/`HasSession` edges | you ran `DCOnly` — re-run `-c all` (or `Session`) to gather host data |

---

## 🔒 OPSEC / EXAM NOTES
- `DCOnly` is quieter than `all` (no host touches) — good for a first pass; `--stealth` (SharpHound) throttles further.
- Save the `.zip` into your per-target `loot/` folder and note the collection time — the report needs the evidence.
- No internet in the exam: keep the GUI, collectors, and Neo4j/Docker images **pre-installed and tested** before exam day ([[Validation Register]]).
- BloodHound only *maps*; it executes nothing — pair every edge with its tool in [[Which AD Attack, When]].

## 📇 TL;DR
```bash
# 1. collect (fast first look)
bloodhound-python -u $U -p "$P" -d $DOMAIN -dc dc01.$DOMAIN -ns $DC -c DCOnly --zip
# 2. import → Mark as Owned → "Shortest Paths from Owned to Domain Admins"
# 3. no path? → Kerberoastable / AS-REP / delegation / DCSync queries → new cred → re-mark → repeat
# 4. need host data? → re-collect -c all
```
**Kill shot:** one cred → collect → mark owned → follow the drawn edge chain to DA.
