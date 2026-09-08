# 🎯 OSCP Playbook — Master Index

> **Purpose:** Rapid-reference field manual + learning resource. When you're stuck on an exam box, open the note for the service you found and work the decision tree top-to-bottom. Never leave an attack surface without exhausting this.

---

## ⚡ How to use this vault under exam pressure

1. Run your port scan → identify every open service.
2. For **each** open port, open its note below.
3. In each note, work in this order: **QUICK TRIAGE → 5-MIN ENUM → decision tree → deeper enum**.
4. Log every finding in your notes. When you find something, jump to that note's **FOUND → NEXT** table.
5. When a service is exhausted (see its **STOP CONDITION**), move to the next port. Do **not** rabbit-hole.

---

## 🗺️ Port → Service Quick Lookup

| Port(s) | Service | Note | Priority |
|---|---|---|---|
| 21 | FTP | [[FTP]] | 🔴 High |
| 22 | SSH | [[SSH]] | 🟡 Medium |
| 23 | Telnet | [[Telnet]] | 🟢 Situational |
| 25/465/587 | SMTP | [[SMTP]] | 🟡 Medium |
| 53 | DNS | [[DNS]] | 🟡 Medium |
| 79 | Finger | [[Finger]] | 🟢 Situational |
| 80/443/8080/8000 | HTTP(S) | [[HTTP]] | 🔴🔴 Critical |
| 88 | Kerberos | [[Kerberos]] → [[Active Directory]] | 🔴 High (AD) |
| 110/995 | POP3 | [[POP3 IMAP]] | 🟢 Situational |
| 111/2049 | RPCbind / NFS | [[NFS]] | 🟡 Medium |
| 135/593 | MSRPC | [[RPC]] | 🟡 Medium |
| 139/445 | SMB / NetBIOS | [[SMB]] | 🔴🔴 Critical |
| 143/993 | IMAP | [[POP3 IMAP]] | 🟢 Situational |
| 161/162 | SNMP (UDP) | [[SNMP]] | 🔴 High |
| 389/636/3268 | LDAP | [[LDAP]] → [[Active Directory]] | 🔴 High (AD) |
| 512/513/514 | R-services | [[R-services]] | 🟢 Situational |
| 1433 | MSSQL | [[MSSQL]] | 🟡 Medium |
| 1521 | Oracle DB | [[Oracle TNS]] | 🟢 Situational |
| 2049 | NFS | [[NFS]] | 🟡 Medium |
| 3306 | MySQL | [[MySQL]] | 🟡 Medium |
| 3389 | RDP | [[RDP]] | 🟡 Medium |
| 5432 | PostgreSQL | [[PostgreSQL]] | 🟢 Situational |
| 5985/5986 | WinRM | [[WinRM]] | 🔴 High |
| 5900+ | VNC | [[VNC]] | 🟢 Situational |
| 6379 | Redis | [[Redis]] | 🟢 Situational |
| 27017 | MongoDB | [[MongoDB]] | 🟢 Situational |

> **Legend:** 🔴🔴 Critical = almost always the way in · 🔴 High · 🟡 Medium · 🟢 Situational (only when hinted).

---

## 🧭 Methodology / Cross-Cutting Hub Notes

These are linked from every service note. They hold the shared techniques so service notes stay lean.

| Note | Folder | Covers |
|---|---|---|
| [[Web Enumeration]] | `01 - Recon` | dir/vhost busting, source/JS, CMS, certs |
| [[Linux Privilege Escalation]] | `04 - Linux PrivEsc` | sudo, SUID, cron, caps, kernel |
| [[Windows Privilege Escalation]] | `05 - Windows PrivEsc` | tokens/potato, services, AlwaysInstallElevated, stored creds |
| [[Active Directory]] | `06 - Active Directory` | AS-REP/Kerberoast, BloodHound, DCSync |
| [[Credential Attacks]] | `07 - Credentials` | brute force, spraying, hash cracking, reuse |
| [[Shells]] | `08 - Shells & Payloads` | reverse/bind shells, upgrades, listeners, file transfer |
| [[Pivoting and Port Forwarding]] | `08 - Shells & Payloads` | tunnelling, chisel/ssh, proxychains |

---

## 🗂️ Vault Structure

```
00 - START HERE (this note)        ← master index + universal first moves
00 - OSCP Methodology/             ← the repeatable process (workflow, recon, enum, exploit, troubleshooting)
01 - Recon/                        ← host discovery + Web Enumeration
02 - Services/                     ← one note per service/port (work these when a port is open)
03 - Initial Access/               ← web/app exploitation techniques (SQLi, LFI, upload, RCE, …)
04 - Linux PrivEsc/
05 - Windows PrivEsc/
06 - Active Directory/
07 - Credentials/                  ← cred attacks, reuse matrix
08 - Shells & Payloads/            ← shells, upgrades, pivoting
09 - Troubleshooting/              ← "it's not working" playbooks
10 - Exam Cheat Sheets/            ← compact, scan-only kill-shot sheets
99 - Attachments/                  ← screenshots / images + Cheatsheets/ PDF library
```

**Flow on a box:** `00 - OSCP Methodology` (process) → `01 - Recon` (scan) → `02 - Services` (per open port) → `03 - Initial Access` (get a shell) → `04/05` PrivEsc (+ `06` if AD) → loop with `07 - Credentials`. `08` and `09` support every stage; `10` is your exam-day quick reference.

## 📚 Reference Library
- [[_MOC (Cheatsheets)|📚 Cheatsheets — PDF reference library]] — 73 third-party study PDFs (Linux/Windows PrivEsc, AD, web, pivoting, methodology, walkthroughs) in `99 - Attachments/Cheetsheets/`, mapped to the vault notes they support.
- [[Misc|🧰 Misc — Quick Jump Index]] — fast landing page linking the cross-cutting basics (file transfer, shells, pivoting, cleanup) + inline file/content search.
- [[Validation Register|✅ Validation Register]] — command/test status, review dates, and the time-sensitive exam-policy source.

> Each folder that isn't yet filled has a **`_MOC` map-of-content note** listing the planned notes so nothing gets forgotten.

---

## 📐 The Standard Note Format (every service note follows this)

Every service note is structured identically so muscle memory carries you through the exam:

```
PORT X → THINK          (instant associations on discovery)
QUICK TRIAGE            (is it worth time? what's the 1-line verdict?)
5-MINUTE ENUMERATION    (rapid triage commands)
15–30 MIN DEEP ENUM     (comprehensive)
WHAT                    (service theory, ports, auth, attack surface)
WHY                     (why it matters in OSCP)
HOW: MANUAL ENUM
HOW: AUTOMATED ENUM
AUTHENTICATION
USER ENUMERATION
RESOURCE / FILE ENUM
CONFIGURATION ENUM
VULNERABILITY IDENTIFICATION
ATTACK VECTORS          (labelled High/Med/Situational probability)
CREDENTIAL HUNTING
EXPLOITATION → INITIAL ACCESS
POST-EXPLOITATION
PRIVILEGE ESCALATION CONNECTIONS
FOUND → NEXT            (decision table: finding → meaning → next)
FAILED → NEXT           (what to do when things return nothing)
TROUBLESHOOTING
COMMON MISTAKES
CREDENTIAL REUSE
CROSS-SERVICE ATTACKS
OSCP EXAM MINDSET
DON'T MISS checklist
STOP CONDITION
EXAM CHEAT SHEET        (compact, scan-only)
```

**Probability labels used everywhere:**
- 🟢 **HIGH PROB** — try first, common on exam.
- 🟡 **MED PROB** — try if high-prob fails.
- 🔵 **SITUATIONAL** — only when a specific hint points here.

---

## 🏁 Universal First Moves (any box, any exam)

```bash
# Set target once, reuse everywhere
export IP=10.10.10.10
```

```bash
mkdir -p nmap
```

```bash
# 1. Fast full TCP port sweep
sudo nmap -p- --min-rate 5000 -T4 $IP -oN nmap/allports.txt
```

```bash
# 2. Service/version + default scripts on the open ports found above
sudo nmap -sC -sV -p<comma,list> $IP -oN nmap/services.txt
```

```bash
# 3. Top UDP (SNMP/DNS/TFTP/SNMP live here and are easy to miss)
sudo nmap -sU --top-ports 100 $IP -oN nmap/udp.txt
```

> Always add every discovered port to your notes and open the matching service note.

---

## ✅ Global exam discipline

- **Enumerate before exploiting.** 90% of OSCP is enumeration.
- **Two services, one credential.** Every password/hash you find → test on *every* other service ([[Credential Attacks]]).
- **Time-box.** ~20–30 min of true dead-air on a service → move on, come back later.
- **Screenshot as you go** for the report. Command + output in the same frame.
- **Note the OS.** It decides [[Linux Privilege Escalation]] vs [[Windows Privilege Escalation]].
