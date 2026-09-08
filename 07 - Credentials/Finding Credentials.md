# 🔑 Finding Credentials & Username Enumeration

> Before you can spray, crack, or reuse, you need **names and secrets**. This note is the catalogue of *where* credentials and usernames hide across services and post-exploitation, and how to build the `users.txt`/`creds.txt` that power everything else.

Part of [[Credential Attacks]]. Related: [[Password Spraying]] · [[Hash Cracking]] · [[Credential Reuse]]

---

## 🧠 THINK
- Build **`users.txt`** (every username seen) and **`creds.txt`** (every pair) and keep appending.
- Passwords hide in configs, shares, DBs, source, history, and post-exploit dumps.
- Usernames come from many services — convert real names into username formats.

## 📥 WHERE CREDENTIALS COME FROM
| Source | Examples | Note |
|---|---|---|
| Config files | `web.config`, `wp-config.php`, `.env`, `config.php`, connection strings | [[HTTP]] / [[LFI]] |
| Shares / FTP | `unattend.xml`, `Groups.xml` (GPP), `.kdbx`, scripts, backups | [[SMB]] / [[FTP]] |
| Databases | dumped user tables, `mysql.user` | [[SQL Injection]] / [[MySQL]] |
| Source leaks | `.git`, `.bak`, php-filter/LFI source | [[Web Enumeration]] |
| History / keys | `.bash_history`, `.ssh/id_rsa`, PS history | [[Linux Credential Hunting]] / [[Windows Stored Credentials]] |
| Post-exploit | SAM/LSA/NTDS, LSASS | [[Dumping Windows Hashes]] |
| Enumeration | SNMP communities, SMTP VRFY, default creds | [[SNMP]] / [[SMTP]] |

Decrypt a GPP `cpassword`:
```bash
gpp-decrypt <cpassword>
```

## 👥 USERNAME ENUMERATION SOURCES
| Service | How | Note |
|---|---|---|
| SMB | `--users`, `--rid-brute` | [[SMB]] / [[RPC]] |
| Web | author enum, login/registration error diffs | [[HTTP]] |
| SMTP | `VRFY` / `RCPT TO` | [[SMTP]] |
| Kerberos | `kerbrute userenum` | [[Kerberos]] |
| LDAP | anonymous bind `sAMAccountName` | [[LDAP]] |
| Finger | `finger @$IP` | [[Finger]] |
| Certs / LFI | emails in certs, `/etc/passwd` | [[HTTPS]] / [[LFI]] |

Generate username permutations from real names:
```bash
username-anarchy -i names.txt > users.txt
```

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| Password in a file/DB | [[Credential Reuse]] |
| Hash | [[Hash Cracking]] / [[Pass-the-Hash]] |
| Username list | [[Password Spraying]] |
| SSH key / KeePass | crack/open → harvest more |
| GPP cpassword | `gpp-decrypt` → spray |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No creds anywhere | grep harder (`/opt`,`/var/www`,shares,mail); dump DBs; check history/keys |
| No usernames | RID-brute, kerbrute, SMTP VRFY, cert emails; permute real names |
| Only hashes | [[Hash Cracking]]; or pass NT hashes directly |

## 📇 CHEAT SHEET
```bash
grep -riE 'pass|secret|key|connectionstring' /var/www /home /opt /etc 2>/dev/null
```
```bash
netexec smb $IP -u '' -p '' --rid-brute        # usernames
```
```bash
username-anarchy -i names.txt > users.txt ; gpp-decrypt <cpassword>
```
**Kill flow:** harvest names + secrets → `users.txt`/`creds.txt` → spray/crack/reuse.
