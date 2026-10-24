# 🔑 Scenario 08 — Anonymous FTP leaks `db_connect.php`

> **Given:** anonymous FTP login works and the FTP root holds **`db_connect.php`** (downloaded via `get`). That file almost certainly contains **hardcoded database credentials** — the loot. Goal: turn those creds into a shell → root/SYSTEM + proof. Fill `<placeholders>` from your own run, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]]. Services: FTP → [[HTTP]] → DB. Then: [[Credential Attacks]] · [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]] · [[Shells]].

```bash
export IP=<TARGET_IP> ; mkdir -p loot
```

---

## 🧠 WHAT THIS IS
A **credential leak via anonymous FTP.** `db_connect.php` is a web app's DB-connection include; its whole purpose is to hold `$host/$user/$pass/$db`. So this box is a **credential-reuse puzzle**, not an exploit hunt: read the creds, then find *where they work*.

> **Why reuse-first:** a DB password in source is rarely "just" a DB password — devs reuse it for the **SSH/system account, the web admin, or another service**. The DB login itself may also give RCE. Test the password **everywhere** before assuming you need another vuln.

---

## 1️⃣ GRAB + READ THE FILE
```bash
ftp $IP                     # user: anonymous   pass: anonymous (or blank)
#   ls -la ; binary ; prompt off ; mget *     → pull everything, not just db_connect.php
cat db_connect.php          # extract: $servername / $username / $password / $dbname
```
Note the values into `loot/creds.txt`. Also read **every other file** you pulled — more creds, hostnames, or hints often sit alongside it.

## 2️⃣ ENUMERATE THE REST (where can this cred go?)
```bash
sudo nmap -sC -sV -p- $IP -oN nmap/services.txt     # SSH? HTTP? MySQL/3306? MSSQL? SMB? RDP/WinRM?
```
`db_connect.php` implies a **web app** (PHP) and a **database** are present — find both.

## 3️⃣ USE THE CREDENTIALS (try these in order)

### A. Reuse as a login (fastest, most common)
```bash
# Linux box:
ssh <user>@$IP                                   # the DB user/pass reused for SSH
# Windows box:
nxc smb $IP -u <user> -p '<pass>' --local-auth ; evil-winrm -i $IP -u <user> -p '<pass>'
# web admin panel found during enum → same creds
```
→ [[Credential Attacks]]. One hit here = instant foothold.

### B. Log into the database → loot or RCE
```bash
mysql -h $IP -u <user> -p'<pass>'                 # or: mysql -h 127.0.0.1 after a web foothold
#   show databases; use <db>; show tables; select * from users;   → app creds/hashes
```
- Dump the app's **user table** → crack hashes ([[Credential Attacks]]) → new creds to reuse.
- **DB → RCE** where supported: MySQL `INTO OUTFILE` a webshell into the web root; MSSQL `xp_cmdshell`; PostgreSQL `COPY FROM PROGRAM`.

### C. Into the web app
Log into the app the DB belongs to (admin creds from the `users` table) → its upload/feature → webshell ([[HTTP]] → [[Shells]]).

## 4️⃣ FOOTHOLD → PRIVESC
```bash
# Linux:
id; sudo -l; find / -perm -4000 -type f 2>/dev/null; ./linpeas.sh | tee loot/linpeas.txt
# Windows:
whoami /priv    # SeImpersonate → GodPotato/PrintSpoofer → SYSTEM
```
→ [[Linux Privilege Escalation]] / [[Windows Privilege Escalation]]. **Re-test the DB password for `sudo`/`su`** — config passwords are reused constantly.

---

## 🗺️ DECISION FLOW
```
anonymous FTP ──► mget *  ──► read db_connect.php ──► DB creds
      ▼
full nmap: what else is open? (ssh / http / 3306 / smb / winrm)
      ▼
try the password:
   ├─ SSH / WinRM / SMB login (reuse) ──────────► shell ─┐
   ├─ DB login ──► dump users (crack) / INTO OUTFILE|xp_cmdshell|COPY PROGRAM ──► creds/RCE ─┤
   └─ web admin (same creds) ──► upload ──► webshell ─────┘
                                                          ▼
                                   privesc (sudo -l / SUID  |  SeImpersonate) ──► ROOT/SYSTEM ✅
```

## 🚧 STUCK?
1. DB creds don't log in remotely (`3306` filtered) → you likely need a **web foothold first**, then use them on `127.0.0.1`.
2. Password works nowhere obvious → **spray it with the username variants** across SSH/SMB/web; also try it as **root/administrator**.
3. Only `db_connect.php` on FTP → re-list with `ls -la` (hidden files), check **write** access (upload a webshell if FTP root = web root — see [[Scenario 03 — FTP + Apache Index (vsftpd 3.0.5)]]).
→ [[Standalone Boxes — Exam Solve Guide]] (Stuck section).

## 🧠 ONE-LINE LESSON
**A `db_connect.php` on anonymous FTP is a handed-to-you credential: read it, then test that password everywhere (SSH/WinRM/SMB/web/the DB itself). The DB login also dumps crackable app hashes or gives RCE (`INTO OUTFILE`/`xp_cmdshell`/`COPY PROGRAM`). Reuse first, exploit second.**
