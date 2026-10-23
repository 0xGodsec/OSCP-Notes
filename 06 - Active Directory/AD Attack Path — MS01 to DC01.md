# 🗺️ AD Attack Path — MS01 → MS02 → DC01

> Combined overview of the AD set: how the three machines chain into a full domain compromise. Per-machine command runbooks: [[MS01 — Initial Foothold]] · [[MS02 — Lateral Movement]] · [[DC01 — Domain Controller]]. This note is the **map**; those are the **steps**. Structure follows your Landscape; **all IPs/creds/outputs are placeholders** until you fill them from your lab — never record a guessed value.

Part of [[Active Directory]]. Framework lens: the 9 positions of AD attack (see the AD hub). Reuse rule: [[Credential Reuse]].

---

## 🎯 THE THREE HOSTS (fill from your lab)
| Host | Role | IP | Hostname | Owned via | Proof |
|---|---|---|---|---|---|
| **MS01** | Initial foothold | `<MS01_IP>` | `<MS01_HOST>` | `<foothold method>` | `<local.txt>` |
| **MS02** | Lateral movement | `<MS02_IP>` | `<MS02_HOST>` | `<cred/hash reused>` | `<proof.txt>` |
| **DC01** | Domain controller | `<DC_IP>` | `<DC_HOST>` | `<DA/DCSync cred>` | `<proof.txt>` |

Domain (FQDN): `<DOMAIN>` · Base DN: `<BASE_DN>` · Domain SID: `<SID>`

---

## 🔗 THE CHAIN
```
[ MS01 ] Initial Foothold
   recon → anon SMB/LDAP + RID users → AS-REP/spray → foothold shell
   → PrivEsc (SeImpersonate/GodPotato → SYSTEM) → dump SAM/LSASS
        │
        ├─ loot: local admin hash + any cached DOMAIN creds  ─┐
        ▼                                                      │ reuse
[ MS02 ] Lateral Movement                                      │
   BloodHound path → spray MS01 creds/hashes → PtH/OpTH shell  │
   → PrivEsc → dump LSASS/DPAPI  ── cached HIGH-PRIV cred ──────┤
        │                                                      │
        ▼                                                      ▼
[ DC01 ] Domain Controller
   confirm DC → check DCSync on owned → (ACL abuse if needed)
   → authenticate with DA/priv cred → DCSync Administrator + krbtgt
   → dump NTDS.dit → Golden Ticket (optional) → proof
        │
        ▼
   DOMAIN OWNED → reuse NTDS hashes range-wide → all proofs captured
```

## 🔑 CREDENTIAL FLOW (what unlocks what — fill as you go)
| # | Credential / hash | Found on (step) | Used against | Result |
|---|---|---|---|---|
| 1 | `<asrep/sprayed cred>` | MS01 (9/11) | MS01 | foothold shell |
| 2 | `<local admin NT hash>` | MS01 (19) | MS02 (3/6) | lateral PtH |
| 3 | `<cached domain cred>` | MS02 (11) | DC01 (7/8) | DA / DCSync |
| 4 | `<krbtgt hash>` | DC01 (8) | whole domain | Golden Ticket |
> Keep this table current — it *is* the attack path. Every new cred → test on every host first ([[Credential Reuse]]).

## 🧭 STAGE → NOTE ROUTER
| Stage | Technique note | Machine step |
|---|---|---|
| User enum (no creds) | [[AD Enumeration]] · [[RPC]] · [[LDAP]] | MS01 4–6 |
| No-cred roast | [[AS-REP Roasting]] | MS01 9 |
| Spray (lockout-aware) | [[Password Spraying]] | MS01 11 |
| Foothold shell | [[WinRM]] · [[AD Lateral Movement]] | MS01 12 |
| Local → SYSTEM | [[Windows Privilege Escalation]] · [[Token Privileges & Potato]] | MS01 13–18 · MS02 9–10 |
| Harvest creds | [[Dumping Windows Hashes]] | MS01 19–20 · MS02 11–12 |
| Reuse / PtH | [[Pass-the-Hash]] · [[Credential Reuse]] | MS02 3–6 |
| Map the graph | [[BloodHound]] | MS01 21 · MS02 13 |
| SPN roast (1 cred) | [[Kerberoasting]] | MS02 7 · DC01 5 |
| ACL → DCSync | [[AD ACL Abuse]] | DC01 3–6 |
| Own the domain | [[DCSync & Domain Dominance]] | DC01 8–10 |

## ⚠️ PATH-LEVEL REMINDERS
- **One network, not three boxes** — reuse every MS01/MS02 cred against every host before calling a machine "stuck".
- **Check lockout (`getdompwinfo`) before any spray** — locking a domain account stalls all three.
- **Clock + `/etc/hosts`** for every host, or Kerberos/`-k` auth fails.
- **Pass hashes, don't crack them** where possible ([[Pass-the-Hash]]).
- **Capture proof the moment you own each host** — flag + target IP + `whoami` in one frame ([[Exam Workflow]]).

## ✅ COMPLETION CHECK
- [ ] MS01 `local.txt` captured + submitted
- [ ] MS02 `proof.txt` captured + submitted
- [ ] DC01 `proof.txt` captured + submitted
- [ ] NTDS dumped; krbtgt + Administrator hashes recorded
- [ ] Every recovered hash reused across all hosts (no un-owned host left)
- [ ] Changes tracked for [[Post-Engagement Cleanup]]
