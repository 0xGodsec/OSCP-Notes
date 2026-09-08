# 🔬 Enumeration Methodology

> "Enumerate before you exploit" — 90% of OSCP is enumeration. This note is the **discipline**: how to work a service to exhaustion, tell MUST-CHECK from optional, recognise attack chains, and know when a service is truly done vs when you're rabbit-holing.

Related: [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]] · [[Recon Methodology]] · [[Exploitation Methodology]] · [[Credential Attacks]]

---

## 🧠 CORE PRINCIPLES
- **Breadth before depth.** Enumerate *all* services shallowly, *then* go deep on the promising ones. Don't tunnel on port 80 while 445 has a null session.
- **Every service note has a decision tree** — open it and work top-to-bottom (QUICK TRIAGE → 5-MIN → deep).
- **Every finding answers "so what → what next?"** Use each note's **FOUND → NEXT** table.
- **Two services, one credential.** Any username/password/hash/key → test on **every** other service.
- **Enumeration is a loop:** new info (hostname, cred, internal port) → re-enumerate.

## 🔁 PER-SERVICE LOOP
```
1. Open the 02 - Services note for the port
2. QUICK TRIAGE (60s): is there an obvious win? (anon access, null session, default creds)
3. 5-MIN ENUM: banner/version, auth options, anonymous/guest, listable resources
4. Record findings → FOUND → NEXT table decides the next action
5. Deep enum only if the service is promising
6. STOP CONDITION met? → move on. Rabbit-holing? → move on, come back
```

## 🥇 MUST-CHECK (every service, every time)
- **Version** → `searchsploit` it.
- **Anonymous / null / guest / default creds** — the fastest wins.
- **Anything listable without auth** (shares, dirs, users, DBs, exports).
- **Info disclosure** (banners, error pages, certs, SNMP, LDAP descriptions).
- **Credential reuse** of anything you've already found.

## 🔵 OPTIONAL / ADVANCED (only when hinted)
- Deep protocol-specific attacks, obscure NSE scripts, brute force (mind lockout), niche CVEs.
- Situational services (VNC/Redis/Mongo/Oracle) — deep-dive only when the box points there.

## 🎯 WHAT YOU'RE HUNTING (value ranking)
| Prize | Why it matters |
|---|---|
| A credential/hash/key | Reuse → shells everywhere ([[Credential Attacks]]) |
| Anonymous file access | Configs/keys/source → more creds |
| A version with a public exploit | Direct foothold ([[Exploitation Methodology]]) |
| A username list | Spray / AS-REP / brute |
| Internal hostnames/domains | New vhosts / AD surface |
| An input that "does something" | Injection/upload/RCE → [[Web Exploitation]] |

## 🧷 RECOGNISING CHAINS (think two moves ahead)
- SMB null → users + shares → creds in a share → WinRM shell → privesc.
- Web version → CVE → shell → config creds → DB → reuse → another host.
- LFI → config creds → SSH; or LFI → log poison → RCE.
- SNMP/LDAP → usernames + info → spray → foothold.
- Any cred → **the reuse matrix** ([[Credential Attacks]]).

## 🚧 FAILED → NEXT (a service returns nothing)
1. Re-read the note's **FAILED → NEXT** table — you probably skipped a method.
2. Try the **anonymous/guest/null** variant you didn't try.
3. **Version unknown?** banner-grab manually (`nc`, `openssl s_client`, NSE).
4. Still nothing after ~20–30 min → **note it and move on**; return with creds found elsewhere.

## ⚠️ COMMON MISTAKES
- Going **deep on one service** before enumerating the rest.
- Skipping **version → searchsploit**.
- Not trying **anonymous/default** access.
- Not maintaining a **running creds/users list** and reusing it.
- Ignoring a service's **STOP CONDITION** (rabbit-holing) — or leaving too early (under-enumerating).

## ✅ DON'T MISS (universal)
- [ ] Version of every service → searchsploit
- [ ] Anonymous / null / guest / default creds everywhere
- [ ] Everything listable without auth
- [ ] Info disclosure (banners/certs/SNMP/LDAP)
- [ ] Reuse every credential on every service
- [ ] Re-enumerate after any new hostname/cred/foothold

## 🛑 WHEN IS A SERVICE "DONE"?
When you've hit its **STOP CONDITION**: anonymous/default tried, version checked, resources enumerated & looted, creds (if any) reused, and no realistic vector remains. Then move on — but keep the notes; a credential from another box may reopen it.
