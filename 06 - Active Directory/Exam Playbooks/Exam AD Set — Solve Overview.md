# 🗺️ Exam AD Set — Solve Overview

> The **repeatable shape** of the OSCP AD set, distilled from real solves: a 3‑machine chain (foothold → lateral/support → DC). Use this to orient, then work the per-machine guides. Methodology only — fill box-specific values from your own run.

Part of [[Active Directory]] · framework: [[AD Attack Framework]]. Guides: [[MS01 — Exam Solve Guide (Foothold)|MS01]] · [[MS02 — Exam Solve Guide (Lateral)|MS02]] · [[DC01 — Exam Solve Guide (Domain)|DC01]].

---

## 🔗 The recurring chain
```
Given: a low-priv DOMAIN credential
MS01 (foothold)   SSH/WinRM login → SeImpersonate → GodPotato → SYSTEM → dump SAM
   │              ligolo pivot to the internal /24
   └─ BloodHound + Kerberoast → crack a SERVICE-account password
MS02 (support)    reuse svc cred → MSSQL xp_cmdshell / WinRM → SeImpersonate → SYSTEM
   │              (Defender bypass: SQL excluded dir + certutil; forward channel only)
   └─ mimikatz / remote lsassy → cached DOMAIN ADMIN hash
DC01 (graded)     PtH the DA → DCSync → krbtgt + all hashes → proof.txt
```

## 🔑 Credential flow (the engine)
| Stage | What you gain | Unlocks |
|---|---|---|
| Given cred | first shell on MS01 | local SYSTEM + Kerberoast |
| Kerberoast crack | service-account password | MS02 (MSSQL/SMB) |
| MS02 LSASS | Domain Admin hash | DC01 |
| DCSync | krbtgt + every hash | whole domain |
> Every credential → test on every host before calling a box stuck ([[Credential Reuse]]).

## 🧠 The techniques that actually recur
- **Foothold:** given domain cred over SSH/WinRM; `SeImpersonate` → GodPotato/PrintSpoofer → SYSTEM ([[Token Privileges & Potato]]).
- **Lateral cred:** Kerberoast ([[Kerberoasting]]) and credential reuse ([[Credential Reuse]]) — not brute force.
- **MS02 exec:** MSSQL `-windows-auth` → `xp_cmdshell` ([[MSSQL]]).
- **Defender:** drop tooling in SQL Server's auto-excluded DATA dir, upload over the forward channel with `certutil`; run mimikatz **remotely** (lsassy) when local exec is blocked.
- **DC:** pass-the-hash the DA → `secretsdump -just-dc` ([[DCSync & Domain Dominance]], [[Pass-the-Hash]]).

## ⚠️ Gotchas that cost time
- **Clock skew / `/etc/hosts`** — fix before any Kerberos step.
- **No reverse route** off the inner boxes — use forward channels (MSSQL/SMB upload), not reverse shells.
- **UAC token filtering** — set `LocalAccountTokenFilterPolicy=1` for a created local admin before remote SMB dumps.
- **Lockout** — check policy (`--pass-pol` / `getdompwinfo`) before any spray.
- Capture **proof + target IP + whoami** the moment you own each host ([[Exam Workflow]]).

## 🧭 Stuck? → position yourself
If a machine stalls, drop into [[AD Attack Framework]] and identify which position you're in, then run only that position's moves.
