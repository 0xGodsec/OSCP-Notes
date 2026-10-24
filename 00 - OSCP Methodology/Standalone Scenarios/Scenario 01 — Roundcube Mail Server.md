# 📬 Scenario 01 — Roundcube Mail Server

> **Given:** a standalone with `22, 25, 43, 80, 110, 143, 443, 3306` open; web on 80/443 is **Roundcube 1.4.2**. Goal: foothold → root + proof. Generalized methodology — fill box-specific values from your own run; no invented creds/IPs.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]]. Services: [[SMTP]] · [[POP3 IMAP]] · [[HTTP]] · [[MySQL]] · [[SSH]]. Support: [[Web Enumeration]] · [[Credential Attacks]] · [[Linux Privilege Escalation]].

```bash
export IP=<TARGET_IP> ; mkdir -p nmap loot
```

---

## 🧠 READ THE PORTS FIRST (what this box is telling you)
| Port | Service | What it means here |
|---|---|---|
| 25 / 110 / 143 | SMTP / POP3 / IMAP | A **full mail stack**. 25 sends, 110/143 retrieve. |
| 80 / 443 | Roundcube 1.4.2 | **Webmail front-end** to that IMAP server — needs a mailbox login. |
| 3306 | MySQL | Roundcube's **backend DB** (users, sessions, config creds). Big loot if reachable. |
| 22 | SSH | Where you land **once you have a cred** — not the way in. |
| 43 | WHOIS (?) | **Anomaly** — whois on a box is odd. Enumerate separately; could be custom/vulnerable. |

> **Why this matters:** the ports describe the whole kill chain before you touch the box — *get a mail credential → use the webmail/MTA → read mail or get RCE → loot MySQL/config → SSH → privesc.* Two independent routes below; try both in parallel.

---

## 1️⃣ ENUMERATE (breadth-first — don't tunnel on Roundcube)
```bash
sudo nmap -p- --min-rate 5000 -T4 $IP -oN nmap/allports.txt
sudo nmap -sC -sV -p22,25,43,80,110,143,443,3306 $IP -oN nmap/services.txt
```
**Harvest usernames + the mail domain — you can't log in without `user@domain`:**
```bash
openssl s_client -connect $IP:443 2>/dev/null | openssl x509 -noout -subject -email   # CN/emails → domain + users
whatweb http://$IP ; curl -s http://$IP/CHANGELOG.md | head   # confirm Roundcube 1.4.2
```
**SMTP user enumeration (turns the mail domain into a userlist):**
```bash
nc -nv $IP 25                                   # grab the MTA banner (see Route B!)
smtp-user-enum -M RCPT -U users.txt -D <domain> -t $IP   # VRFY/EXPN/RCPT → valid mailboxes
```
**MySQL + the whois anomaly:**
```bash
mysql -h $IP -u root           # try unauth / default; nmap --script 'mysql-*' -p3306 $IP
nc -nv $IP 43                   # banner-grab port 43; then: searchsploit <whatever it is>
```

> **Why:** the TLS cert and SMTP enum hand you the exact `user@domain` strings every other service (IMAP, POP3, Roundcube login) demands. Skipping this is the usual reason people get stuck on mail boxes.

---

## 🅰️ ROUTE A — the webmail/credential chain (most likely intended path)

**Step 1 — get one mailbox credential (the gate).** Roundcube needs valid IMAP creds. Earn them:
```bash
# spray the enumerated users (labs rarely lock out — still check):
hydra -L users.txt -P /usr/share/wordlists/rockyou.txt -f imap://$IP
# also try: weak/default creds, creds leaked on 80/443 or in the port-43 service, any reuse
```
**Step 2 — log into Roundcube → read everything.** The fastest win on a mail box is usually *not* an exploit — it's the inbox:
- Read **every mailbox** (Inbox, Sent, Drafts, other folders). Mail routinely contains **other users' passwords, SSH keys, internal hostnames, reset links** → immediate pivot to [[SSH]].

**Step 3 — Roundcube 1.4.2 known-vuln check** (`searchsploit roundcube`; **read the PoC and confirm preconditions before running**):
| CVE | Class | Note |
|---|---|---|
| CVE-2020-12641 | **Authenticated RCE** via `im_convert_path`/`im_identify_path` arg injection (<1.4.4) | 1.4.2 is in range → `www-data` shell if preconditions met |
| CVE-2020-12640 | Path traversal / LFI via plugin name (<1.4.4) | read local files (e.g. the config below) |
| CVE-2020-35730 | Stored XSS in plaintext mail (<1.4.10) | situational, not a direct shell |

> **Why verify, not trust:** these match the *version* but each has preconditions (auth, config reachability). Confirm with the PoC — don't fire blind. ([[Exploitation Methodology]])

**Step 4 — loot MySQL via Roundcube's config.** With a shell *or* the LFI, read the webmail config:
```bash
cat /var/www/html/roundcube/config/config.inc.php   # path varies; also /etc/roundcube/
#  → $config['db_dsnw']  = MySQL user:pass           (connect to 3306)
#  → $config['des_key']  = key that encrypts session-stored IMAP passwords
mysql -h 127.0.0.1 -u <dbuser> -p<dbpass> roundcubemail -e 'show tables; select * from users;'
```
DB creds often unlock **more app creds / hashes** → crack ([[Hash Cracking]]) → reuse on SSH. (With `des_key` + the `session` table you can decrypt stored IMAP passwords — advanced, situational.)

**Step 5 — SSH + local privesc.** Use any recovered cred/key on `22`, then:
```bash
id; sudo -l; find / -perm -4000 -type f 2>/dev/null; ls -la /var/mail /var/spool/mail
./linpeas.sh | tee loot/linpeas.txt
```
Mail boxes specifically: check `/var/mail/*` and `/var/spool/mail/*` for creds, and any mail-handling SUID/cron. → [[Linux Privilege Escalation]].

---

## 🅱️ ROUTE B — exploit the MTA on 25 directly (don't miss this)
The banner on port 25 names the mail transfer agent. **If it's Exim**, check the version against the big ones — these run **as root**:
```bash
nc -nv $IP 25         # e.g. "220 host ESMTP Exim 4.XX"
```
| If you see | CVE | Result |
|---|---|---|
| **Exim 4.87 – 4.91** | CVE-2019-10149 ("Return of the WIZard") | **direct root RCE** |
| **Exim 4.92 – 4.92.1** | CVE-2019-15846 (TLS SNI) | root RCE |
| Postfix / Sendmail | — | rarely the vector; fall back to Route A |

> **Why first-class, not a footnote:** if the MTA is a vulnerable Exim, it's the **kill shot** — straight to root, no webmail, no cred hunt. Always version the service on 25 before committing to the long Route A chain. ([[SMTP]])

---

## 🧩 WILDCARD — port 43
Whois on a target box is unusual. Banner-grab it, send a test query, identify the daemon, and `searchsploit` it. Treat it like any unknown service: **version → known CVE → PoC**. Don't let it eat time if 80/25 are clearly richer — note it and rotate ([[Standalone Boxes — Exam Solve Guide]]).

---

## 🗺️ DECISION FLOW
```
version 25's MTA ──► vulnerable Exim? ──yes──► CVE-2019-10149 ──► ROOT ✅
        │                               no
        ▼
SMTP user-enum + TLS cert ──► userlist ──► spray IMAP ──► Roundcube login
        │                                                        │
        ├─ read mailboxes → creds / SSH key ──────────► SSH ─────┤
        └─ Roundcube 1.4.2 CVE (authed) → www-data shell          ▼
                      │                                    local privesc → ROOT ✅
                      └─ read config.inc.php → MySQL/des_key → more creds → SSH
```

## ✅ WHAT TO CAPTURE
`local.txt` after the first shell, `proof.txt` after root — each screenshotted with the target IP (`ip a`) + `id` in frame, submitted in the control panel. Save every cred/hash to `loot/creds.txt`. ([[Standalone Boxes — Exam Solve Guide]])

## 🧠 ONE-LINE LESSON
**A mail stack (25/110/143 + webmail) means "get a mailbox cred, then the inbox or the webmail CVE carries you" — but always version the MTA on 25 first, because a vulnerable Exim is a straight shot to root.**
