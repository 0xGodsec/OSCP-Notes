# 🔎 Scenario Index — by Signal

> Fast lookup for the [[_MOC (Standalone Scenarios)|scenario bank]]: **"I see X → open scenario Y."** Spot the signal in your scan/screen, jump to the matching playbook. A box usually trips **several** rows — work the richest one first.

Back to [[_MOC (Standalone Scenarios)]] · method [[Standalone Boxes — Exam Solve Guide]].

---

## 🚪 By port / service
| You see | Signal | Scenario |
|---|---|---|
| **21 FTP** open | can you log in **anonymously**? | [[Scenario 03 — FTP + Apache Index (vsftpd 3.0.5)]] · [[Scenario 08 — Anonymous FTP leaks db_connect.php]] |
| **Anon FTP with documents/`.db`** | mine the files (sqlite/pdf/office) | [[Scenario 12 — Anonymous FTP document & DB loot]] |
| **Anon FTP with a `.env`** | Laravel keys → reuse + RCE | [[Scenario 15 — Laravel .env leak (anon FTP)]] |
| **6379 Redis** (no auth) | file-write → webshell/SSH-key/cron, or module RCE | [[Scenario 13 — Unauthenticated Redis (6379) RCE]] |
| **25 + 110 + 143** | full **mail stack** (SMTP/POP3/IMAP) | [[Scenario 01 — Roundcube Mail Server]] |
| **80 / 443** only, **+ 3389** | web-only **Windows** box | [[Scenario 04 — Windows Web + RDP (80,443,3389)]] |
| **445 + 5985 + 3389** together | Windows, **one cred opens 3 shells** | [[Scenario 05 — Windows Multi-Service (SMB, Postgres, WinRM, RDP)]] |
| **5432 PostgreSQL** | try `postgres:postgres` → `COPY FROM PROGRAM` RCE | [[Scenario 05 — Windows Multi-Service (SMB, Postgres, WinRM, RDP)]] |
| **3306 MySQL** reachable | weak creds → `INTO OUTFILE` / dump | [[Scenario 08 — Anonymous FTP leaks db_connect.php]] |
| **22 SSH** + a found cred | reuse — SSH is the landing spot, not the entry | [[Scenario 08 — Anonymous FTP leaks db_connect.php]] |
| **3389 RDP / 5985 WinRM** | landing spot once you hold creds | [[Scenario 04 — Windows Web + RDP (80,443,3389)]] · [[Scenario 05 — Windows Multi-Service (SMB, Postgres, WinRM, RDP)]] |

## 🌐 By what the web page is
| You see | Signal | Scenario |
|---|---|---|
| Polished **marketing template** (hosting/company) | **decoy** → enumerate hidden surface | [[Scenario 02 — Cloud Web Hosting (brochure page)]] |
| **"Site under construction"** + a builder footer | fingerprint builder + fuzz hidden app | [[Scenario 10 — Under Construction + builder fingerprint]] |
| **`Index of /`** (directory listing) | writable upload? → webshell | [[Scenario 03 — FTP + Apache Index (vsftpd 3.0.5)]] |
| **Named CMS** admin login (e.g. WBCE `/admin/login/`) | get admin → authed RCE | [[Scenario 06 — WBCE CMS (authenticated RCE)]] |
| **Functional app** (login/search/catalog/upload) | identify product → SQLi/upload/PoC | [[Scenario 09 — Library Education Portal (known web app)]] |
| **Education/learning/coaching portal, LMS, school/course system** | same family → identify product → SQLi/upload/PoC | [[Scenario 09 — Library Education Portal (known web app)]] |
| **Named "… Management System" login (FMS, HMS, etc.)** | same family → identify product → SQLi/default-cred/PoC | [[Scenario 09 — Library Education Portal (known web app)]] |
| **File-upload field** (CV / avatar / docs) | bypass filter → webshell | [[Scenario 14 — File Upload Portal (CV upload → webshell)]] |
| **WordPress** + a named **plugin** | the plugin is the hole → wpscan → plugin CVE | [[Scenario 11 — WordPress Mail Masta LFI]] |
| **IIS 403 Forbidden** on a dir | bypass path/header/method or fuzz inside | [[Scenario 07 — 403 Forbidden Directory (IIS bypass)]] |

## 🧰 By error / banner / artefact
| You see | Means | Scenario |
|---|---|---|
| `403 … credentials you supplied` | **IIS** 403 | [[Scenario 07 — 403 Forbidden Directory (IIS bypass)]] |
| `Index of /` title | Apache dir listing on | [[Scenario 03 — FTP + Apache Index (vsftpd 3.0.5)]] |
| `db_connect.php` / `config.php` grabbable | **credential leak** → reuse everywhere | [[Scenario 08 — Anonymous FTP leaks db_connect.php]] |
| `Server: Microsoft-IIS` / `.aspx` | Windows; `.aspx` webshell, 8.3 short-name | [[Scenario 04 — Windows Web + RDP (80,443,3389)]] · [[Scenario 07 — 403 Forbidden Directory (IIS bypass)]] |
| `Generator`/footer = a product name | **fingerprint** → searchsploit / default admin | [[Scenario 10 — Under Construction + builder fingerprint]] · [[Scenario 06 — WBCE CMS (authenticated RCE)]] |
| `vsftpd 3.0.5` / `2.0.8` | **not** the 2.3.4 backdoor → config/anon/loot path | [[Scenario 03 — FTP + Apache Index (vsftpd 3.0.5)]] · [[Scenario 11 — WordPress Mail Masta LFI]] |
| `Exim 4.87–4.91` on 25 | **CVE-2019-10149 → root** | [[Scenario 01 — Roundcube Mail Server]] |
| `?pl=` / Mail Masta / `csvexport.php` | **unauth LFI** (CVE-2016-10956) → `wp-config.php` | [[Scenario 11 — WordPress Mail Masta LFI]] |
| `Redis … 4.0.14` / port 6379 | **unauth Redis** → file-write RCE | [[Scenario 13 — Unauthenticated Redis (6379) RCE]] |
| `.env` with `APP_KEY` / `APP_DEBUG=true` | **Laravel** → reuse + Ignition/APP_KEY RCE | [[Scenario 15 — Laravel .env leak (anon FTP)]] |
| `contractors.db` / a loose `.db`/`.sqlite` | open it: `sqlite3 .dump` → creds/PII | [[Scenario 12 — Anonymous FTP document & DB loot]] |

## 🖥️ By OS tell
| Tell | OS | Privesc target |
|---|---|---|
| 3389 / 445 / 5985 / `.aspx` / IIS | **Windows** | `whoami /priv` → **SeImpersonate → GodPotato** → SYSTEM |
| 22 OpenSSH-Ubuntu / Apache-Ubuntu / vsftpd | **Linux** | `sudo -l` → SUID → cron → config creds → root |

## 🪟 By Windows privesc signal (post-foothold)
| You see | Signal | Scenario |
|---|---|---|
| **No `SeImpersonate`** + PowerUp/winPEAS flags a service | weak service ACL / unquoted path / writable binary or dir | [[Scenario 16 — Windows Service Hijacking → SYSTEM]] |
| `SERVICE_CHANGE_CONFIG` / `SERVICE_ALL_ACCESS` on a service | `sc config binpath=` → SYSTEM | [[Scenario 16 — Windows Service Hijacking → SYSTEM]] |
| Unquoted path with a space + writable prefix dir | plant `C:\...\Gap.exe` → restart | [[Scenario 16 — Windows Service Hijacking → SYSTEM]] |

---

## 🧠 Recurring meta-lessons (true on every scenario)
1. **Version → route.** The exact product/version decides the foothold — `searchsploit` before hand-rolling, but **verify the PoC/preconditions**.
2. **Reuse every credential.** One password/hash → try it on **SSH, WinRM, SMB, RDP, the DB, and every web login** before hunting a new vuln.
3. **Shells are landing spots.** SSH/WinRM/RDP are rarely the *entry* — they're where a looted cred lands you.
4. **"Empty"/"decoy" means enumeration isn't done.** Brochure, construction, 403, sparse index → fuzz dirs + **vhosts** + files, read source/`.git`.
5. **Config files are gold.** `db_connect.php`/`web.config`/`config.php` → creds that privesc you.
6. **Windows web → `SeImpersonate` → potato → SYSTEM** is the default escalation.

## ➕ Adding a scenario
New `Scenario NN` note → add its distinctive **signals** as rows here (port, web shape, error, OS tell) so the lookup stays complete.
