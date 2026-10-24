# 🗃️ Scenario 12 — Anonymous FTP document & DB loot (mine the files)

> **Given:** anonymous FTP is open and the share holds **business files** — e.g. `contractors.db`, `Report.pdf`, `values_2022.csv`, scattered PDFs. Goal: mine those files for credentials/usernames → foothold → root. Unlike [[Scenario 08 — Anonymous FTP leaks db_connect.php]] (one config file) or [[Scenario 03 — FTP + Apache Index (vsftpd 3.0.5)]] (FTP **write** → webshell), **here the loot is inside the documents.** Fill `<placeholders>` from your own run, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]]. Then: [[Credential Attacks]] · [[Hash Cracking]] · [[SSH]] · [[SMB]] · [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]].

```bash
export IP=<TARGET_IP> ; mkdir -p loot/ftp ; cd loot/ftp
```

---

## 🧠 THE IDEA
Anon FTP file access is a **loot goldmine**, and the box's secret is *inside the files*, not in the service. The whole game is **methodical file triage**: pull everything, open each by type, extract **creds, usernames, hashes, PII, and hints**, then reuse. A `.db` is a database you can just open.

> **Why triage matters:** a single `contractors.db` can hold a users table with hashes; a PDF's **metadata** leaks usernames and the software stack; a CSV can carry a password column. Miss a file type and you miss the foothold.

---

## 1️⃣ PULL EVERYTHING
```bash
ftp $IP            # anonymous : anonymous
#   binary ; prompt off ; mget *        (recurse subdirs too: ls -R first)
# or mirror in one shot:
wget -m --no-passive ftp://anonymous:anonymous@$IP/ -P ./mirror
ls -la ; file *    # identify each type before opening
```

## 2️⃣ TRIAGE BY FILE TYPE
**Databases (`.db`, `.sqlite`, `.mdb`, `.sql`):**
```bash
file contractors.db
sqlite3 contractors.db '.tables'                     # then: .dump  /  SELECT * FROM users;
# not SQLite? -> strings/mdbtools; a .sql dump -> grep -i 'insert into users'
```
→ usernames + password **hashes** → [[Hash Cracking]].

**PDFs:**
```bash
exiftool *.pdf | grep -iE 'Author|Creator|Producer|Title'   # usernames + software/versions
pdftotext Report.pdf - | less                                # read content for creds/notes
strings -n 6 *.pdf | grep -iE 'pass|pwd|user|key'
pdfdetach -saveall *.pdf 2>/dev/null                         # embedded files
# password-protected? crack it:
pdf2john Duplicate.pdf > h ; john h --wordlist=/usr/share/wordlists/rockyou.txt
```

**Office (`.docx/.xlsx/.pptx`) & CSV:**
```bash
unzip -o doc.docx -d doc_x ; grep -riE 'pass|pwd|user' doc_x    # OOXML is a zip
exiftool *.docx *.xlsx | grep -iE 'Author|Creator|Last'
office2john protected.xlsx > h ; john h --wordlist=rockyou.txt  # if protected
grep -iE 'pass|pwd|user|email|key' *.csv
```

## 3️⃣ HARVEST → REUSE
From the above, build:
- **`loot/users.txt`** — every name from file metadata, DB rows, document authors.
- **`loot/creds.txt`** — every password/hash found (crack hashes).

Then find where they work:
```bash
sudo nmap -sC -sV -p- $IP -oN nmap/services.txt     # SSH? SMB? web? DB? WinRM/RDP?
# reuse:
ssh <user>@$IP ; nxc smb $IP -u users.txt -p creds.txt --continue-on-success
```
→ [[Credential Attacks]]. One hit = foothold. (Also test **FTP write** — writable share + a web root = webshell, see [[Scenario 03 — FTP + Apache Index (vsftpd 3.0.5)]].)

## 4️⃣ FOOTHOLD → PRIVESC
```bash
# Linux: id; sudo -l; find / -perm -4000 -type f 2>/dev/null; ./linpeas.sh
# Windows: whoami /priv  (SeImpersonate -> GodPotato -> SYSTEM)
```
→ [[Linux Privilege Escalation]] / [[Windows Privilege Escalation]]. Re-test looted passwords for `sudo`/`su`.

---

## 🗺️ DECISION FLOW
```
anon FTP + data files ──► mget * (recurse) ──► file *  (triage by type)
   ├─ .db/.sqlite ──► sqlite3 .dump ──► users + hashes ──► crack ─┐
   ├─ .pdf ──► exiftool (authors) + pdftotext + strings ──────────┤
   ├─ .docx/.xlsx ──► unzip + grep + exiftool ────────────────────┤
   └─ .csv ──► grep pass/user/email ──────────────────────────────┤
                                                                   ▼
                              users.txt + creds.txt ──► nmap ──► reuse (SSH/SMB/web/DB)
                                                                   ▼
                                       foothold ──► privesc ──► ROOT/SYSTEM ✅
```

## 🚧 STUCK?
1. No creds in files → harvest **usernames** from metadata/DB and **spray** a wordlist against SSH/SMB.
2. `.db` isn't SQLite → `file` it; try `mdb-tables` (Access), `strings`, or load a `.sql` dump locally.
3. PDFs look empty → check **metadata** and **embedded files**, not just the text.
4. Nothing reuses → re-list FTP with `ls -laR` for **hidden/nested** files; test **write** access.
→ [[Standalone Boxes — Exam Solve Guide]] (Stuck section).

## 🧠 ONE-LINE LESSON
**When anon FTP hands you documents and a database, the box is a looting exercise: `sqlite3 .dump` the `.db`, `exiftool`/`pdftotext` the PDFs, `unzip`+grep the Office files — harvest usernames and creds, then reuse them across SSH/SMB/web to get in.**
