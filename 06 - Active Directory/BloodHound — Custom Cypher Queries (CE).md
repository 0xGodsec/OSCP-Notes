# 🩸 BloodHound — Custom Cypher Queries (CE)

> Pre-loaded, one-click Cypher queries for **BloodHound CE** that turn AD enumeration into button clicks on exam day. Mark your foothold Owned, then click a query instead of typing it under pressure. Companion to [[BloodHound — Master Reference]] · quick-ref [[BloodHound]].

Part of [[Active Directory]]. Related: [[Which AD Attack, When]] · [[AD ACL Abuse]] · [[AD Lateral Movement]] · [[DCSync & Domain Dominance]] · [[Kerberoasting]] · [[AS-REP Roasting]]

**Files:** [[bloodhound-ce-custom-queries.json]] (the 15 queries) · [[load-bloodhound-ce-queries.sh]] (bulk-import loader)

---

## ⚡ HOW TO LOAD THEM (CE ≠ legacy)
BloodHound **CE does not read a `customqueries.json` file** — it keeps saved queries in its database. Two ways to get them in:

**Option A — bulk import (do this once, before exam day):**
```bash
# 1. Log into CE (default http://localhost:8080)
# 2. DevTools → Network → click any /api/v2/... request → copy the JWT from "Authorization: Bearer <JWT>"
BHCE_URL=http://localhost:8080 BHCE_JWT='<JWT>' \
  ./load-bloodhound-ce-queries.sh bloodhound-ce-custom-queries.json
```
They then appear under **Cypher → Saved Queries** as clickable buttons and survive restarts.

**Option B — manual:** paste any query below into the **Cypher** tab → click the **Save** (💾) icon → name it. Fine for one or two; use A for all 15.

> **Prep rule:** no internet during the exam — load these into your attack VM and **test them against a lab domain beforehand** ([[Validation Register]]).

---

## 🧩 CE SCHEMA — the two properties these rely on
CE replaced the old `owned:true` / `highvalue:true` booleans with **tags**:
| Concept | Legacy 4.x | **CE** |
|---|---|---|
| You control it | `n.owned = true` | `n.system_tags CONTAINS 'owned'` |
| Crown jewels | `n.highvalue = true` | `n.system_tags CONTAINS 'admin_tier_0'` |

So **Mark as Owned** on every principal/host you control — the owned-aware queries depend on that tag. (`hasspn`, `dontreqpreauth`, `unconstraineddelegation` are unchanged in CE.)

---

## 🎯 THE QUERIES (what each answers → what to do)

### Triage — run these the moment you have one cred + marked Owned
| Button | Answers | Then |
|---|---|---|
| **What can my OWNED do right now** | every control edge you currently hold | pick the shortest win → [[Which AD Attack, When]] |
| **Shortest path OWNED → Domain Admins** | the whole plan to DA | execute edge-by-edge |
| **Shortest path OWNED → any Tier Zero** | paths to DC / DA group / krbtgt | same, broader target set |

### Creds — find what to crack / grab
| Button | Answers | Then |
|---|---|---|
| **Kerberoastable users** | users with an SPN | `GetUserSPNs -request` → `hashcat -m 13100` ([[Kerberoasting]]) |
| **Kerberoastable WITH path to DA** | which SPN accounts actually chain to DA | roast **these first** |
| **AS-REP roastable users** | pre-auth-disabled users | `GetNPUsers -no-pass` → `-m 18200` ([[AS-REP Roasting]]) |
| **Passwords in the description field** | cleartext creds left in AD | spray/login immediately |

### Lateral — where to move
| Button | Answers | Then |
|---|---|---|
| **Hosts my OWNED can shell** | AdminTo / CanRDP / CanPSRemote targets | psexec / evil-winrm / rdp ([[AD Lateral Movement]]) |
| **Computers with a Domain Admin session** | where DA creds are cached | own host → `lsassy` → DA hash |

### Delegation & ACL — the escalation edges
| Button | Answers | Then |
|---|---|---|
| **Unconstrained delegation computers** | coercion targets | coerce DC → capture TGT |
| **Constrained delegation (who → service)** | S4U candidates | `getST -impersonate` |
| **Shadow-credential targets from OWNED** | `AddKeyCredentialLink` edges | `certipy shadow` → PKINIT ([[ADCS (Certipy)]]) |
| **ACL edges from OWNED** | GenericAll/Write/DACL/Owner/ForceChangePw/AddMember | match edge → abuse ([[AD ACL Abuse]]) |

### Domain dominance & recon
| Button | Answers | Then |
|---|---|---|
| **Who can DCSync the domain** | GetChanges + GetChangesAll holders | `secretsdump -just-dc` ([[DCSync & Domain Dominance]]) |
| **All Tier Zero objects** | your objectives list | prioritise paths toward these |

---

## 🧠 THE LOOP (how to actually use them)
1. Get one cred → collect ([[BloodHound — Master Reference]]) → **Mark Owned**.
2. Click **What can my OWNED do right now** + **Shortest path OWNED → Domain Admins**. Path? Execute it.
3. No path → click the **Creds** queries (Kerberoastable-with-path, AS-REP, description-pw) → crack → new cred → **Mark Owned** → repeat.
4. Still stuck → **Hosts my OWNED can shell** → local privesc → dump → re-collect so new edges appear.

Every new credential loops you back to step 1. **Pass hashes, don't crack them** when you can.

## 🔒 Notes
- Local instance only; the loader stores no credentials — you supply a short-lived JWT at runtime.
- If a query errors in CE, it's almost always the Tier Zero tag — confirm `system_tags` is populated (CE auto-tags Tier Zero after the first analysis run).
