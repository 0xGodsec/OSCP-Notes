# 🐧 Linux Credential Hunting

> After a shell, the fastest privesc/lateral move is often a **password or key already on disk**. Hunt histories, SSH keys, config files, backups, and readable other-user files, then reuse across `su`/SSH/DB/other hosts.

Part of [[Linux Privilege Escalation]]. Related: [[Credential Attacks]] · [[SSH]]
> One command per block so you can copy-paste each individually.

---

## 🧠 THINK
- Passwords hide in **history, configs, `.env`, backups, DB dumps, cron scripts, web roots**.
- **SSH keys** = direct login as another user/host.
- **`/etc/shadow` readable?** → crack it. **Reused passwords** are everywhere → try every cred with `su` and on other services.

## ⚡ HUNT (each block copy-pastes on its own)
Shell history (passwords typed on the command line):
```bash
cat ~/.bash_history
```
All users' histories (if readable):
```bash
cat /home/*/.bash_history 2>/dev/null
```
SSH private keys (yours + other users):
```bash
find / -name id_rsa -o -name id_dsa -o -name '*.pem' 2>/dev/null
```
Recursive secret grep across common dirs:
```bash
grep -riE 'password|passwd|secret|api[_-]?key|BEGIN.*PRIVATE KEY' /var/www /home /opt /etc 2>/dev/null
```
App/DB config files:
```bash
find / \( -name '*.conf' -o -name '*.config' -o -name '.env' -o -name 'wp-config.php' -o -name 'config.php' \) 2>/dev/null
```
Backups / old files (often cleartext):
```bash
find / -name '*.bak' -o -name '*.old' -o -name '*.sql' -o -name '*.kdbx' 2>/dev/null
```
`/etc/passwd` (users; crackable hashes if unshadowed):
```bash
cat /etc/passwd
```
`/etc/shadow` (if readable → crack):
```bash
cat /etc/shadow
```
Readable other-user home files:
```bash
ls -la /home/*
```

## 💥 USE WHAT YOU FIND
Switch user with a found password:
```bash
su <user>
```
Log in with a recovered key:
```bash
chmod 600 id_rsa ; ssh -i id_rsa <user>@<host>
```
Crack shadow/hashes:
```bash
# on Kali: unshadow passwd shadow > cr ; hashcat -m 1800 cr rockyou.txt   ($6$ = sha512crypt)
```

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| Password in history/config | `su`/ssh/DB → maybe root or lateral |
| SSH private key | `ssh -i` as that user/host → [[SSH]] |
| `/etc/shadow` readable | crack → [[Credential Attacks]] |
| DB/app creds | login to DB + **reuse on SSH** |
| Backup with creds | extract → reuse everywhere |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Nothing in your home | grep `/opt`, `/var/www`, other homes, `/tmp`, mail spools |
| Key is passphrase-protected | `ssh2john key > h; john h` |
| Hashes won't crack | bigger wordlist/rules; try creds you already have |
| No readable creds | pivot to config-based privesc ([[Sudo Abuse]]/[[SUID & SGID]]) |

## 📇 CHEAT SHEET
```bash
grep -riE 'pass|secret|key' /var/www /home /opt /etc 2>/dev/null
```
```bash
find / -name id_rsa 2>/dev/null ; cat ~/.bash_history ; cat /etc/passwd
```
```bash
su <user>        # reuse everything, everywhere ([[Credential Attacks]])
```
**Kill shot:** found password/key → `su`/`ssh` → lateral or root; reuse on every service.
