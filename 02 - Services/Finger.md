# 🔧 Finger — Port 79

> **User-information protocol** (legacy Unix, 79/TCP, no auth). On OSCP, Finger is a pure **username-enumeration** surface: query it to confirm which accounts exist and see login/idle/real-name/shell info. Those usernames feed SSH/credential attacks. Very rare, but a free win when present — and some ancient daemons have a command-injection quirk.

Related: [[Credential Attacks]] · [[SSH]] · [[Linux Privilege Escalation]]

---

## 🧠 PORT 79 → THINK
- **Enumerate usernames** — the whole point.
- `finger user@$IP` → real account details; `finger @$IP` → who's logged in.
- Feed valid users into [[SSH]] brute / [[Credential Attacks]].
- Old daemons: `finger "user@host@$IP"` info leak / command-exec quirk (situational).

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p79 -sV --script finger $IP
```

```bash
finger @$IP            # list logged-in users (if allowed)
```

```bash
finger root@$IP        # probe a specific account
```
**Verdict:** returns user info → enumerate a userlist. Empty/refused → move on.

## ⏱️ ENUMERATE
```bash
finger @$IP                       # currently logged-in users
```

```bash
for u in root admin bin daemon backup user test oracle postgres; do
  echo "== $u =="; finger $u@$IP; done
# Metasploit user enum:
#   use auxiliary/scanner/finger/finger_users   (set RHOSTS, USERS_FILE)
```
**Look for:** valid usernames, real names, home dirs, login times, shells → all useful for targeting.

## 🗡️ EXPLOIT
- 🟢 **Username enumeration** → SSH/credential attacks.
- 🔵 **Legacy daemon command injection / info leak** (`finger "a b c d e f g h@host@$IP"`, `finger "|cmd@$IP"`) — version-dependent, rare.

Finger itself gives no shell. Chain: enumerate users → `users.txt` → derive password guesses from real names/defaults → spray/brute [[SSH]] ([[Credential Attacks]]).

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Valid usernames | Targets | build users.txt | SSH targeting |
| Real names | Guess fuel | craft user/pass variants | possible cred |
| Active/idle users | Live accounts | prioritize for brute | foothold |
| Ancient daemon | Maybe injectable | test known quirk (careful) | info/exec |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `finger` not installed | `sudo apt install finger`; or nmap `finger` script; or `nc $IP 79` + send a username |
| No output for names | Try `@$IP` for logged-in list; try common accounts; Metasploit `finger_users` |
| All refused | Daemon restricted — note and move on |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** not **saving enumerated users** to a reusable list · treating it as an exploit target rather than a **name source**.
**Reuse:** usernames → [[SSH]] brute/spray, [[SMTP]] cross-check, any auth service. See [[Credential Attacks]].
**Don't miss:** `finger @$IP` (logged-in) · probe common accounts → users.txt · Metasploit `finger_users` bulk enum · feed users into SSH/credential attacks.
**Stop when:** userlist gathered (or nothing returned) → move on; the action is in [[SSH]] / [[Credential Attacks]].

## 📇 CHEAT SHEET
```bash
nmap -p79 -sV --script finger $IP
```

```bash
finger @$IP ; finger root@$IP
```

```bash
for u in root admin user test oracle; do finger $u@$IP; done
# msf: auxiliary/scanner/finger/finger_users
```
**Kill shots:** enumerate users → SSH spray/brute.
