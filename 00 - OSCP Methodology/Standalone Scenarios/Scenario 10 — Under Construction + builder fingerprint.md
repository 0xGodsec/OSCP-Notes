# 🚧 Scenario 10 — "Under Construction" + builder fingerprint

> **Given:** a standalone whose web root shows *"This site is in construction"* with a footer credit like **"Kevin Kustom Sites | 2023"** (a named site-builder/CMS). Goal: foothold → root/SYSTEM + proof. Two levers: **the footer is a software fingerprint**, and **"under construction" hides the real app.** Sibling of [[Scenario 02 — Cloud Web Hosting (brochure page)]] — reuse its deep enum. Fill `<placeholders>` from your own run, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]] · [[Web Enumeration]]. Foothold: [[Web Exploitation]] · [[File Upload]] · [[RCE]] · [[Credential Attacks]].

```bash
export IP=<TARGET_IP> ; mkdir -p loot
```

---

## 🧠 TWO LEVERS
1. **The footer credit is a fingerprint.** A builder/CMS name ("Kevin Kustom Sites", a theme, a generator) is a product you can **research**: its default **admin path**, its **source on GitHub**, its **config files**, and any **known CVE**. Treat the name like a `Server:`/generator string.
2. **"Under construction" ≠ empty.** The real app, an admin panel, or a dev build is almost always present but unlinked → **enumerate the hidden surface** (dirs, vhosts, params) exactly as in [[Scenario 02 — Cloud Web Hosting (brochure page)]].

> **Why not just "it's a placeholder"?** Boxes don't ship a dead page — the construction notice is the challenge's *misdirection*. The content is one fuzz (or one `/admin`) away.

---

## 1️⃣ FINGERPRINT THE BUILDER
```bash
whatweb http://$IP/ ; curl -s http://$IP/ | grep -iE 'generator|powered|kustom|<!--|href|src'
searchsploit "<builder name>" ; searchsploit kustom      # research the exact product
```
- Read the **page source + comments + linked JS/CSS paths** — they leak the framework, template dir, and sometimes the admin URL.
- Look the builder name up (its GitHub / docs) for the **default admin path**, default creds, and config file names.

## 2️⃣ ENUMERATE THE HIDDEN SURFACE (reuse Scenario 02's recipe)
```bash
feroxbuster -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,txt,bak,zip,html
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -u http://$IP -H "Host: FUZZ.<domain>" -fs <size>
curl -s http://$IP/robots.txt ; curl -s http://$IP/sitemap.xml
```
Chase: `/admin`, `/login`, `/cms`, `/dashboard`, `/dev`, `/test`, `/backup`, `/uploads/`, `.git/`, and any **vhost** the cert/footer hints at. → [[Web Enumeration]].

## 3️⃣ FOOTHOLD — whatever you uncover
| Found | Route |
|---|---|
| Builder/CMS admin panel | default/weak creds → its upload/template feature → webshell | [[Credential Attacks]] · [[File Upload]] |
| Known builder CVE | `searchsploit -m <poc>` → run (read first) | [[Exploitation Methodology]] |
| A real app on a vhost/subdir | match its inputs to a bug class (SQLi/upload/LFI) | [[Web Exploitation]] |
| `.git/` exposed | `git-dumper` → source → creds/logic/CVE | source review |
| Upload / file manager | filter-bypass → webshell | [[File Upload]] · [[RCE]] |

Land as the web user → loot DB/config creds → privesc (Linux `sudo -l`/SUID, or Windows `SeImpersonate` → GodPotato → SYSTEM). → [[Standalone Boxes — Exam Solve Guide]].

---

## 🗺️ DECISION FLOW
```
"under construction" + footer "<Builder> 2023"
   ├─ fingerprint builder ──► default admin path / GitHub source / CVE ─┐
   └─ fuzz dirs + vhosts + robots/sitemap + /.git ──► hidden app/panel ─┤
                                                                        ▼
                                            admin/CVE/upload ──► webshell/creds
                                                                        ▼
                                           loot config creds ──► privesc ──► ROOT/SYSTEM ✅
```

## 🚧 STUCK?
1. Builder name finds nothing → it's just a theme; pivot fully to **dir/vhost fuzzing** (Scenario 02 recipe).
2. Construction page is all you get → **bigger wordlist + extensions**, read **source/JS**, try `/.git/` and backups.
3. Found an admin panel but no creds → default creds, then the builder's docs for a reset/seed account.
→ [[Scenario 02 — Cloud Web Hosting (brochure page)]] · [[Standalone Boxes — Exam Solve Guide]].

## 🧠 ONE-LINE LESSON
**An "under construction" page is misdirection with a gift: the footer builder name is a fingerprint (→ default admin path / source / CVE), and the real app is one fuzz away. Research the builder and enumerate the hidden surface — don't accept "it's just a placeholder."**
