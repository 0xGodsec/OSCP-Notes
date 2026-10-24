# ☁️ Scenario 02 — Cloud Web Hosting (brochure page, recon from zero)

> **Given:** a standalone whose web root is a polished static marketing template — *"Cloud — Unlimited Web Hosting"*, nav of HOME / FEATURES / SERVICES / ABOUT / PRICING / TEAM / CONTACT, a "Start Now" button. **No other details known yet.** This is the common exam start: you have a brochure and must *enumerate your way to the real surface.* Branching methodology; fill `<placeholders>` from your own run, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]] · [[Web Enumeration]]. Services: [[HTTP]] · [[FTP]] · [[SSH]]. Foothold: [[File Upload]] · [[Web Exploitation]] · [[RCE]]. Then: [[Linux Privilege Escalation]] · [[Credential Attacks]].

```bash
export IP=<TARGET_IP> ; mkdir -p nmap loot
```

---

## 🧠 THE ONE INSIGHT
**A static, good-looking template is a decoy, not the vulnerability.** There is no input to attack on a brochure page — so the box is won in **enumeration**, by finding what's *behind* it: another vhost, a hidden directory, a control panel, or a second service. If you start trying to "exploit" the landing page, you're already rabbit-holing.

> **Why this theme matters:** "web hosting" implies **shared hosting** → expect a **control panel** (cPanel, CyberPanel, Webmin, Plesk) and/or a **client portal** (WHMCS), and multiple **virtual hosts**. That shapes every enumeration choice below.

---

## 1️⃣ RECON — full surface, never trust the obvious port
```bash
sudo nmap -p- --min-rate 5000 -T4 $IP -oN nmap/allports.txt
sudo nmap -sC -sV -p<open> $IP -oN nmap/services.txt
sudo nmap -sU --top-ports 100 $IP -oN nmap/udp.txt
```
**Specifically look for panel ports** — their presence *is* the attack path:
| Port(s) | Likely panel | 
|---|---|
| 2082/2083/2086/2087 | cPanel / WHM |
| 8083 / 8888 | aaPanel |
| 8090 | CyberPanel |
| 10000 | Webmin / Virtualmin |
| 8443 | Plesk |
| 21 | FTP (per-site accounts — see Route C) |

## 2️⃣ MINE THE PAGE (it's a loot map, not décor)
| Nav item | What to extract | Feeds |
|---|---|---|
| **TEAM** | real people's names → build `jsmith / j.smith / smith` userlist | SSH/FTP/panel login, spray ([[Credential Attacks]]) |
| **CONTACT** | the email **domain** (`@cloud.xyz`) | completes usernames + vhost guesses |
| **PRICING / SERVICES** | confirms shared-hosting → panel exists | which panel to hunt |
| page source / JS / comments | hidden paths, API endpoints, dev notes | directory list |
```bash
whatweb http://$IP ; curl -s http://$IP | grep -iE 'href|src|TODO|<!--'   # read the source
openssl s_client -connect $IP:443 2>/dev/null | openssl x509 -noout -subject -email   # domain from cert
```

## 3️⃣ ENUMERATE THE HIDDEN SURFACE (where the box actually is)
```bash
# add the domain to /etc/hosts first (from cert/CONTACT): e.g.  echo "$IP cloud.xyz" | sudo tee -a /etc/hosts
feroxbuster -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,txt,html,bak,zip
# VHOST / subdomain fuzzing — hosting boxes hide the real app here:
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
     -u http://$IP -H "Host: FUZZ.cloud.xyz" -fs <default_page_size>
```
Chase: `portal.` · `client.` · `webmail.` · `panel.` · `admin.` · `dev.` · `/panel` · `/admin` · `/webmail` · `/filemanager` · `/uploads`.

> **Why both dir AND vhost fuzzing:** the intended app is frequently served **only** on a non-default `Host:` header. Skip vhost fuzzing and the box looks "empty" when the whole challenge is sitting one header away.

---

## 🌿 BRANCH — match what you find to the route

### Route A — a hosting control panel appears
Panel + version → `searchsploit` / known CVE (**read the PoC, confirm preconditions**):
| Panel | Classic issue (verify version!) | Result |
|---|---|---|
| **Webmin** (10000) | CVE-2019-15107 pre-auth RCE in `password_change.cgi` | **root** RCE |
| **CyberPanel** (8090) | known pre-auth RCE chains | shell |
| **aaPanel / others** | version-specific CVEs | shell |
| **cPanel/WHM/Plesk** | usually **weak creds**, not a clean CVE → log in → shell/file-manager | foothold |
→ [[Exploitation Methodology]]. Default/weak panel creds are as common as CVEs — always try them.

### Route B — a CMS / app on a vhost
WordPress/Drupal/Joomla/custom app on the real vhost → scanner → plugin/theme/core CVE → webshell. → [[Web Exploitation]].

### Route C — FTP (21) per-site accounts
Shared hosting = FTP users whose home **is a web docroot**. Weak/anon creds → **upload a webshell into the served directory** → browse to it for RCE:
```bash
ftp $IP            # try anonymous; then weak creds from the TEAM userlist
# once in a web-served dir:  put shell.php   → http://$IP/.../shell.php
```
→ [[FTP]] · [[File Upload]].

### Route D — an upload / file-manager feature
Any upload (avatar, "upload site files", panel file-manager) → bypass the filter → webshell. → [[File Upload]].

### Route E — SSH (22)
Not the way in; it's where creds from A–D land you. Reuse every credential here ([[Credential Attacks]]).

---

## 4️⃣ FOOTHOLD → PRIVESC
Once you have a web-user shell (`www-data`/`nobody`) or a panel/FTP cred:
```bash
python3 -c 'import pty;pty.spawn("/bin/bash")'   # stabilise ([[Standalone Boxes — Exam Solve Guide]])
id; sudo -l; find / -perm -4000 -type f 2>/dev/null
# hosting boxes: read other sites' config files for DB/user creds → reuse
grep -riE 'password|db_pass|DB_PASSWORD' /var/www /home 2>/dev/null | head
./linpeas.sh | tee loot/linpeas.txt
```
Panels store **customer/site creds** in config and DBs → harvest and **reuse everywhere**. → [[Linux Privilege Escalation]] · [[Credential Attacks]].

---

## 🗺️ DECISION FLOW
```
brochure page ──► DON'T attack it ──► full nmap (-p- + panel ports + UDP)
      │
      ├─ mine TEAM→users, CONTACT→domain, source→paths
      ▼
dir-fuzz + VHOST-fuzz ──► found what?
      ├─ control panel ──► version→CVE / weak creds  ──► shell/root
      ├─ CMS on vhost  ──► scanner→CVE               ──► webshell
      ├─ FTP docroot   ──► creds→upload webshell     ──► RCE
      ├─ upload/filemgr ─► filter bypass→webshell    ──► RCE
      └─ nothing yet   ──► re-fuzz (bigger list, extensions, other vhosts, UDP)
                              ▼
                       foothold ──► loot site configs/creds ──► privesc ──► ROOT ✅
```

## 🚧 "THE BOX LOOKS EMPTY"
That feeling means **enumeration isn't done**, not that there's no path:
1. Bigger wordlist + more **extensions** (`.php .bak .zip .txt .old`).
2. **Vhost-fuzz** again with the real domain; try nested subdomains.
3. Re-scan **all** TCP + **UDP**; check every **panel port**.
4. Read **page source / JS / robots.txt / sitemap** for leaked paths.
5. Try **weak/default creds** on every login you found.
→ [[Standalone Boxes — Exam Solve Guide]] (Stuck section).

## 🧠 ONE-LINE LESSON
**A pretty hosting brochure is a signpost, not a target: enumerate the hidden surface (dirs + vhosts + panel ports), mine TEAM/CONTACT for users and the domain, then let whatever you uncover — panel CVE, weak panel/FTP creds, or an upload — be the foothold.**
