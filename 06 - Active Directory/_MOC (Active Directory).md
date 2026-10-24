# 🏰 06 — Active Directory (Map of Content)

> The AD set / any domain. Start at the hub for setup (/etc/hosts + clock) and the chain, then dive into a stage.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]]. Working hub: [[Active Directory]].

## Notes in this folder
- [x] [[Active Directory]] — **hub / index** (setup, the chain, router)
- [x] [[AD Attack Framework]] — the 9-position anti-stuck model (where am I → what's my move)
- [x] [[Which AD Attack, When]] — attack → precondition decision table (with commands)
- [x] [[AD Enumeration]] — unauth users + authed dump (SMB/LDAP/RPC/kerbrute)
- [x] [[AS-REP Roasting]] — no-creds roast → `-m 18200`
- [x] [[Kerberoasting]] — 1 cred → SPN roast → `-m 13100`
- [x] [[BloodHound]] — collect + shortest path to Domain Admin
- [x] [[BloodHound — Master Reference]] — deep dive: all collection methods, `DCOnly` fast path, Cypher query library, edge→abuse catalog
- [x] [[BloodHound — Custom Cypher Queries (CE)]] — 15 pre-loadable one-click CE queries + bulk-import loader (exam accelerator)
- [x] [[AD Lateral Movement]] — psexec/wmiexec/evil-winrm/PtH
- [x] [[AD ACL Abuse]] — GenericAll/WriteDACL/ForceChangePassword/AddMember
- [x] [[DCSync & Domain Dominance]] — DCSync/NTDS/Golden Ticket
- [x] [[ADCS (Certipy)]] — certificate template abuse (ESC1/ESC8…) → cert → NT hash

## 🖥️ Machine notes (lab runbooks)
Per-machine command playbooks for the AD set, keyed to the Landscape checklist. Placeholders (`<IP>`, `<cred>`, `# paste output`, `![[…png]]`) are filled from your own verified run — nothing pre-populated.
- [[AD Attack Path — MS01 to DC01]] — **combined overview** (chain + credential-flow map)
- [[MS01 — Initial Foothold]] — recon → foothold → local SYSTEM → loot
- [[MS02 — Lateral Movement]] — reuse MS01 loot → PtH → harvest domain creds
- [[DC01 — Domain Controller]] — DCSync → NTDS → domain owned

## 🎓 Exam solve guides (how to solve it)
Realistic "how to solve it in the exam" playbooks distilled from real solves — generalized methodology, no box-specific secrets.
- [[Exam AD Set — Solve Overview]] — the recurring 3-machine chain + credential flow
- [[MS01 — Exam Solve Guide (Foothold)]] — given cred → SeImpersonate/GodPotato → Kerberoast
- [[MS02 — Exam Solve Guide (Lateral)]] — service cred → xp_cmdshell → DA hash (lsassy)
- [[DC01 — Exam Solve Guide (Domain)]] — PtH DA → DCSync → proof

## Order
identify DC → /etc/hosts + clock → user enum → AS-REP/spray → foothold cred → Kerberoast + BloodHound → lateral/local admin → DCSync → Golden Ticket.
Condensed commands: [[Active Directory Cheat Sheet]]. Related: [[Kerberos]] · [[LDAP]] · [[SMB]].

## Domain foothold → domain control
1. Confirm the DC, configure DNS/name resolution, and fix clock skew.
2. Enumerate users and domain data; only then test the appropriate unauthenticated or credentialed route.
3. Obtain one domain credential, then immediately run [[Kerberoasting]] and [[BloodHound]] in parallel.
4. Use the shortest evidenced lateral/ACL route—not every technique—until privileged control is reached.
5. Capture proof, then re-test recovered credentials across hosts with [[Credential Attacks]].
