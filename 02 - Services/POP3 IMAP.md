# 🔧 POP3 / IMAP — Ports 110 / 143 (+ 995 / 993 TLS)

> **Mailbox retrieval protocols** (110 POP3, 143 IMAP, 995 POP3S, 993 IMAPS; `USER`/`PASS` or `LOGIN`, APOP/SASL, STARTTLS). On OSCP these are a **credential-validation and information-disclosure** surface: valid mail creds (often reused from other services) let you log in and **read emails**, which frequently contain passwords, internal hostnames, and hints. The banner also fingerprints the mail server for CVEs. POP3 downloads (typically deletes) mail; IMAP keeps it server-side with folders.

Related: [[Credential Attacks]] · [[SMTP]] · [[SSH]] · [[HTTP]]

---

## 🧠 PORT 110/143 → THINK
- **Have any creds/usernames?** → log in and **read the mail** (creds & hints hide there).
- **995 = POP3S, 993 = IMAPS** — same logins over TLS (`openssl s_client`).
- Pairs with [[SMTP]] (user enumeration there → login here).
- Banner → mail product/version → known CVE.
- Cleartext on 110/143 → sniffable (situational).

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p110,143,993,995 -sV --script pop3-capabilities,imap-capabilities $IP
```

```bash
nc -nv $IP 110      # POP3 banner
```
**Verdict:** have a cred → log in and read mail. No cred → get one from SMTP/other services, then return.

## ⏱️ ENUMERATE (manual login)
```bash
# POP3 (110)
nc -nv $IP 110
```

```bash
USER bob
```

```bash
PASS Password1
```

```bash
LIST            # list messages
```

```bash
RETR 1          # read message 1
```

```bash
QUIT
```

```bash
# IMAP (143)
nc -nv $IP 143
```

```bash
a LOGIN bob Password1
```

```bash
a LIST "" "*"          # list mailboxes
```

```bash
a SELECT INBOX
```

```bash
a FETCH 1 BODY[]       # read message 1
```

```bash
a LOGOUT
```

```bash
# TLS variants
openssl s_client -connect $IP:995 -quiet     # POP3S, then USER/PASS
```

```bash
openssl s_client -connect $IP:993 -quiet     # IMAPS, then a LOGIN ...
```

```bash
# Credential brute (mind lockout)
hydra -L users.txt -P passwords.txt pop3://$IP
```

```bash
hydra -L users.txt -P passwords.txt imap://$IP
```
**Look for:** login success, then message contents — **passwords, credentials, internal names, next steps**; which users authenticate; read every mailbox you can access.

## 🗡️ EXPLOIT
- 🟢 **Reused/weak creds → read mail → find more creds/hints.**
- 🟡 **Credential brute** (watch lockout).
- 🔵 **Banner-identified mail server CVE** (verify version).
- 🔵 **Cleartext sniffing** on 110/143 (MITM position).

POP3/IMAP don't give a shell — they give **intel and credentials**: log in with reused creds → read all mail → extract passwords/keys/hostnames → use those against [[SSH]], [[HTTP]], [[SMB]], etc.

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Login works | Mailbox access | `RETR`/`FETCH` all mail | creds/hints |
| Password in an email | Reuse | test on SSH/web/SMB | shell/access |
| Internal hostname in mail | Pivot target | add to /etc/hosts, enum | new surface |
| Banner product/version | Fingerprint | check known CVE | targeted attack |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No creds | Enumerate users via [[SMTP]] (VRFY/RCPT); reuse creds from elsewhere |
| Cleartext port blocked | Use 993/995 with `openssl s_client`; STARTTLS on 143/110 |
| Login rejected | Verify username format (bare user vs `user@domain`); try reused creds |
| Brute locks accounts | Stop; try a few smart combos only; move on |
| Empty mailbox | Note and move on — not every account has useful mail |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** getting a login but **not actually reading the messages** · not trying **TLS ports** when cleartext is filtered · ignoring **internal hostnames** in emails (pivot hints) · not feeding SMTP-enumerated users into POP3/IMAP logins.
**Reuse:** mail creds → [[SSH]], webmail/[[HTTP]], [[SMB]]; contents → creds for everything; users from [[SMTP]] → logins here. See [[Credential Attacks]].
**Don't miss:** banner + capabilities · log in with reused creds · **read all messages** (`RETR`/`FETCH BODY[]`) · TLS ports 993/995 if cleartext blocked · extract creds/hostnames → reuse · cross-reference with SMTP users.
**Stop when:** no creds and none reusable, or mailboxes empty → move on; return when you find a credential elsewhere. Extracted creds/intel → work continues in the target services.

## 📇 CHEAT SHEET
```bash
nmap -p110,143,993,995 -sV --script pop3-capabilities,imap-capabilities $IP
```

```bash
nc -nv $IP 110      # USER x / PASS y / LIST / RETR 1
```

```bash
nc -nv $IP 143      # a LOGIN x y / a SELECT INBOX / a FETCH 1 BODY[]
```

```bash
openssl s_client -connect $IP:993 -quiet    # IMAPS
```

```bash
hydra -L users.txt -P pass.txt pop3://$IP   # if lockout not a concern
```
**Kill shots:** reused creds → read mail → find the next password.
