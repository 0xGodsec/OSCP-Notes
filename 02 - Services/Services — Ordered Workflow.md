# 🔌 Services — Ordered Workflow

> Open this after recon has identified ports. Enumerate breadth-first: take the quick win checks on **every** open service before spending 20–30 minutes on one deep-dive.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]]. Related: [[Enumeration Methodology]] · [[Credential Attacks]]

---

## 🧭 FROM OPEN PORT → NEXT NOTE

| Priority | What you see | Start here | Common handoff |
|---|---|---|---|
| 1 | 80/443/alternate HTTP | [[HTTP]] / [[HTTPS]] → [[Web Enumeration]] | [[Web Exploitation]] → [[Shells]] |
| 2 | 139/445 | [[SMB]] | files/users/creds → [[Credential Attacks]] or shell |
| 3 | 88 + 389/636 + 135/445 | [[Kerberos]] / [[LDAP]] / [[RPC]] | [[Active Directory]] |
| 4 | 21/22/23/3389/5985 | [[FTP]] / [[SSH]] / [[Telnet]] / [[RDP]] / [[WinRM]] | valid access → [[Shells]] |
| 5 | 161/UDP | [[SNMP]] | users/config/hosts → service or cred workflow |
| 6 | 1433/1521/3306/5432/27017/6379 | [[MSSQL]] / [[Oracle TNS]] / [[MySQL]] / [[PostgreSQL]] / [[MongoDB]] / [[Redis]] | data/command execution → [[Shells]] |
| 7 | 53/111/2049 | [[DNS]] / [[NFS]] | names/files → re-enumerate or credential workflow |
| 8 | Everything else | matching service note; use version + auth + anonymous checks first | [[Enumeration Methodology]] |

## 🔁 RUN THIS ORDER ON EVERY SERVICE

1. Record port, service, version, hostname, and authentication state.
2. Try safe fast wins: anonymous/null/guest/default access and listable resources.
3. Search the exact version and inspect exposed data/configuration.
4. Record users, credentials, shares/files, hostnames, and internal addresses.
5. Send each finding to its next workflow: credentials → [[Credential Attacks]]; web input → [[Web Exploitation]]; shell → [[Shells]]; domain evidence → [[Active Directory]].
6. If there is no credible route after the note’s stop condition, move to the next service and return later with new credentials.

## ✅ BROAD-FIRST CHECKLIST
- [ ] Every TCP port from the full scan has its service note opened.
- [ ] UDP results are reviewed, especially DNS and SNMP.
- [ ] Every service has an exact version, auth check, and anonymous/default check recorded.
- [ ] Every hostname or credential caused a re-enumeration.
- [ ] No single service has consumed the whole time-box without evidence.

**Kill flow:** open port → service note → quick enum across all ports → deepen promising evidence → shell/credential → next workflow.
