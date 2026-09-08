# 🏰 06 — Active Directory (Map of Content)

> The AD set / any domain. Start at the hub for setup (/etc/hosts + clock) and the chain, then dive into a stage.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]]. Working hub: [[Active Directory]].

## Notes in this folder
- [x] [[Active Directory]] — **hub / index** (setup, the chain, router)
- [x] [[AD Enumeration]] — unauth users + authed dump (SMB/LDAP/RPC/kerbrute)
- [x] [[AS-REP Roasting]] — no-creds roast → `-m 18200`
- [x] [[Kerberoasting]] — 1 cred → SPN roast → `-m 13100`
- [x] [[BloodHound]] — collect + shortest path to Domain Admin
- [x] [[AD Lateral Movement]] — psexec/wmiexec/evil-winrm/PtH
- [x] [[AD ACL Abuse]] — GenericAll/WriteDACL/ForceChangePassword/AddMember
- [x] [[DCSync & Domain Dominance]] — DCSync/NTDS/Golden Ticket

## Order
identify DC → /etc/hosts + clock → user enum → AS-REP/spray → foothold cred → Kerberoast + BloodHound → lateral/local admin → DCSync → Golden Ticket.
Condensed commands: [[Active Directory Cheat Sheet]]. Related: [[Kerberos]] · [[LDAP]] · [[SMB]].
