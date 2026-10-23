# 🧰 11 — Tools (Map of Content)

> One note per **cross-cutting tool** — the utilities you reach for on almost every box, that don't belong to a single service or phase. Deep tool usage lives here; the topic notes just link out.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]].

## Notes in this folder
- [x] [[Impacket]] — exec (psexec/wmiexec), secretsdump, Kerberos roasting, relay
- [x] [[Mimikatz]] — on-box LSASS/LSA dump, PtH, tickets, DCSync/golden (+ pypykatz offline)

## When to reach for which
| Goal | Tool | Note |
|---|---|---|
| Code exec with cred/hash/ticket | Impacket | [[Impacket]] |
| Dump hashes remotely / from hives | Impacket (`secretsdump`) | [[Dumping Windows Hashes]] |
| Kerberoast / AS-REP roast | Impacket (`GetUserSPNs`/`GetNPUsers`) | [[Kerberoasting]] · [[AS-REP Roasting]] |
| Read LSASS on-box (cleartext/NT/tickets) | Mimikatz / pypykatz | [[Mimikatz]] |
| Golden/silver ticket, DCSync | Mimikatz | [[DCSync & Domain Dominance]] |

## Order
Land a shell → dump creds ([[Mimikatz]] on-box, or [[Impacket]]-`secretsdump` remote) → pass/reuse ([[Pass-the-Hash]] · [[Credential Reuse]]) → exec on the next host ([[Impacket]]) → domain ([[Active Directory]]).
