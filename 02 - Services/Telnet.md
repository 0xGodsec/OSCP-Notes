# 🔧 Telnet — Port 23

> **Cleartext remote shell protocol** (23/TCP; username+password, some devices password-only or no auth). On OSCP, Telnet = "try to log in." It's a **direct interactive shell** if you have (or guess) credentials — default/weak creds, or creds reused from another service. The banner alone often leaks the device type/version (routers/printers/IoT) and points to a known exploit. Everything is cleartext (relevant if you can sniff).

Related: [[Credential Attacks]] · [[SSH]] · [[Linux Privilege Escalation]] · [[Shells]]

---

## 🧠 PORT 23 → THINK
- **Grab the banner** — device type, OS, product/version → known creds/CVE.
- **Try default & reused creds** immediately (`admin/admin`, `root/root`, anything found elsewhere).
- Success = **interactive shell**, no upgrade needed.
- Cleartext → sniffable if you have a MITM position (situational).
- Embedded/legacy device banners often map to a specific exploit.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p23 -sV --script telnet-ntlm-info,telnet-encryption $IP
```

```bash
telnet $IP 23          # read the banner; try a login
```
**Verdict:** banner + login prompt → try creds. Named product/version → search a known exploit.

## ⏱️ ENUMERATE
```bash
nmap -p23 -sV --script "telnet-*" $IP           # banner, ntlm-info, encryption
```

```bash
telnet $IP                                       # manual: note prompt, try creds
```

```bash
nc -nv $IP 23                                     # alt banner grab
```

```bash
# Credential brute (only if lockout isn't a concern) — try smart combos manually first
hydra -L users.txt -P passwords.txt telnet://$IP -t 4 -f
```
**Look for:** product/OS/version, whether it prompts for username+password or password-only, any pre-login banner leaking info, failed-vs-success message differences (user enum).

## 🗡️ EXPLOIT
- 🟢 **Default/weak/reused creds → shell** (the main path).
- 🟡 **Credential brute** (watch lockout).
- 🔵 **Banner-identified device CVE** (verify product + version).
- 🔵 **Cleartext credential sniffing** (needs MITM position).

```bash
telnet $IP
# login: admin  /  password: admin   (or reused creds)
# -> shell. Identify OS: uname -a  (Linux) or ver (Windows) -> pick privesc path.
```
**After access:** `id`/`whoami`, sudo rights, OS version, hunt creds/keys; stabilize ([[Shells]]) → [[Linux Privilege Escalation]] / [[Windows Privilege Escalation]]. Reuse the working password everywhere ([[Credential Attacks]]).

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Banner: product/version | Fingerprint | search known creds/exploit | targeted attack |
| Login prompt | Auth surface | try default/reused creds | shell |
| Creds work | Foothold | enumerate OS → privesc | escalation |
| Password-only device | Appliance | default device password | admin |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No banner | `nc -nv $IP 23`; nmap `telnet-*` scripts; note and de-prioritize |
| Creds all fail | Try reused creds from other services; limited brute; then move on |
| Connection resets | Some devices rate-limit; slow down; try again later |
| Prompt but no echo/garbled | Terminal negotiation quirk — try a different client or `nc` |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** not **reading the banner** (it often names the exploit) · skipping **reused creds** from other services · brute-forcing hard and locking accounts instead of trying a few smart combos first.
**Reuse:** any password that works here → test on [[SSH]], [[SMB]], web, DBs; banner OS/version informs privesc. See [[Credential Attacks]].
**Don't miss:** banner grab (device/OS/version) · default creds for the identified device · reused creds · note version for a known exploit · reuse any working password elsewhere.
**Stop when:** no banner-driven exploit and no working creds after trying defaults + reused sets → move on; return with creds discovered elsewhere. A shell → work shifts to privesc.

## 📇 CHEAT SHEET
```bash
nmap -p23 -sV --script "telnet-*" $IP
```

```bash
telnet $IP          # read banner, try admin/admin + reused creds
```

```bash
nc -nv $IP 23       # banner grab
```

```bash
hydra -L users.txt -P pass.txt telnet://$IP -t 4 -f     # only if lockout not a concern
```
**Kill shots:** default/reused creds → interactive shell.
