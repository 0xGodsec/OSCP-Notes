# 📧 SMTP — Ports 25 / 465 / 587

> **Simple Mail Transfer Protocol** (25 relay/MTA — enumerate here, 587 submission+auth, 465 SMTPS; Postfix/Exim/Sendmail/Exchange). Verbs: `HELO/EHLO`, `MAIL FROM`, `RCPT TO`, `DATA`, `VRFY`, `EXPN`. On OSCP its main gift is **username enumeration** (`VRFY`/`EXPN`/`RCPT`) → a userlist for spraying. Occasionally open relay, version CVEs (Exim CVE-2019-10149/15846), or a path to phishing/command injection in a mail-processing app.

Related: [[Credential Attacks]] · [[SMB]] · [[SSH]] · [[HTTP]]

---

## 🧠 PORT 25 → THINK
- **User enumeration** via `VRFY`/`EXPN`/`RCPT TO` → build `users.txt`.
- **Banner/version** → Postfix/Exim/Sendmail → `searchsploit` (Exim RCEs are real).
- **Open relay?** (situational).
- **587** = submission (auth), **465** = SMTPS. **25** = server-to-server (enum here).
- Feeds [[Credential Attacks]] spraying on SMB/SSH/web/POP3/IMAP.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p25,465,587 -sV -sC $IP           # banner + smtp-commands + open-relay script
```

```bash
nc -nv $IP 25                            # read banner; try VRFY root
```
**Verdict:** `VRFY`/`EXPN` accepted → enumerate users. Old Exim/Sendmail → check CVEs. Else note and move on.

## ⏱️ ENUMERATE (user enum is the main event)
```bash
nmap -p25 --script smtp-commands,smtp-open-relay,smtp-enum-users $IP
```

```bash
# Manual verbs (netcat)
nc -nv $IP 25
#   HELO x
#   VRFY root            -> 252/250 = user exists ; 550 = no
#   EXPN admin
#   MAIL FROM: <a@b.c>
#   RCPT TO: <bob@target>  -> 250 = valid, 550 = invalid
```

```bash
# Automated user enumeration — 250/252 = valid, 550 = invalid; if VRFY returns 252 for
# everything it isn't distinguishing → switch to RCPT
smtp-user-enum -M VRFY -U /usr/share/seclists/Usernames/top-usernames-shortlist.txt -t $IP
```

```bash
smtp-user-enum -M RCPT -U users.txt -D target.com -t $IP        # if VRFY disabled
```

```bash
smtp-user-enum -M EXPN -U users.txt -t $IP
```

```bash
# Version -> CVEs; auth brute on 587 (if creds hinted)
searchsploit exim ; searchsploit postfix ; searchsploit sendmail
```

```bash
hydra -L users.txt -P passwords.txt smtp://$IP -s 587
```
**Look for:** which verb the server honors, valid usernames, banner version, open-relay = yes.

## 🗡️ EXPLOIT
- 🟢 **User enumeration** → userlist → spray.
- 🟡 **Exim/Sendmail version RCE** → `searchsploit` → shell.
- 🔵 **Open relay** → send spoofed mail (phishing scenario; rare on exam).
- 🔵 **Auth brute on 587** with a userlist (if creds are in scope).

SMTP is a **username factory**, rarely the shell itself: the userlist feeds spraying everywhere; only an old-Exim/Sendmail banner turns it into direct RCE.

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| VRFY/RCPT valid users | Userlist | spray SMB/SSH/web/POP3 | creds |
| Exim/Sendmail old version | RCE candidate | searchsploit + PoC | shell |
| Open relay | Spoofing | craft mail (if scenario) | phish |
| 587 AUTH | Brute target | hydra with userlist | creds |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| VRFY disabled (all 252/550) | Use `RCPT TO` method; try `EXPN` |
| No users found | Use name-based lists + domain from cert/website; get names from web/SMB |
| Version not shown | `EHLO`/`HELP`; still try known-server CVEs generically |
| Nothing actionable | Take any usernames and move on — SMTP is a userlist source, not usually the shell |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** only trying `VRFY` (use `RCPT` when VRFY is off) · not carrying the **userlist** to spraying · overlooking **Exim** version RCEs · wasting time on open relay when there's no scenario for it.
**Reuse:** usernames → [[SMB]] (`--rid-brute` cross-check), [[SSH]], [[HTTP]] logins, [[POP3 IMAP]], [[Active Directory]] AS-REP roasting. See [[Credential Attacks]].
**Don't miss:** banner/version → `searchsploit` · `VRFY` **and** `RCPT` user enum · combine with names from web/cert · carry userlist to spraying · open relay check (quick).
**Stop when:** verbs tested, users enumerated, version checked for CVEs, userlist exported → move on with the list.

## 📇 CHEAT SHEET
```bash
nmap -p25 --script smtp-commands,smtp-enum-users,smtp-open-relay $IP
```

```bash
smtp-user-enum -M VRFY -U users.txt -t $IP        # or -M RCPT
```

```bash
nc -nv $IP 25   # HELO x; VRFY root; RCPT TO:<bob@dom>
```

```bash
searchsploit exim ; searchsploit sendmail
```
**Kill shots:** userlist → spray everywhere · Exim/Sendmail version → RCE.
