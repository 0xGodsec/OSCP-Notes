# ✅ Validation Register

> A lightweight maintenance system for this vault. It distinguishes **source-reviewed information** from commands that still need to be reproduced in an authorised lab. Do not treat any command as safe or current solely because it appears here.

Related: [[Exam Workflow]] · [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]] · [[Troubleshooting Methodology]]

---

## Status key

| Status | Meaning | Action before relying on it |
|---|---|---|
| ✅ Source reviewed | Time-sensitive factual guidance checked against its authoritative source on the listed date. | Re-check the source immediately before an exam or engagement. |
| 🧪 Lab verify | Command/payload needs a successful run in an authorised lab matching your Kali/tool version. | Record tool version, target OS, command, result, and any correction. |
| ⚠️ Context required | Technique depends on target configuration, privileges, egress, or scope. | Confirm prerequisites and authorisation first. |

## Reviewed facts

| Area | Status | Reviewed | Source / scope |
|---|---|---:|---|
| OSCP+ timing, scoring, proof submission, reporting, and Metasploit restrictions | ✅ | 2026-09-07 | [Official OffSec OSCP+ Exam Guide](https://help.offsec.com/hc/en-us/articles/360040165632-OSCP-Exam-Guide) |
| Current exam FAQs, including AI/chatbot restriction and AD pivoting possibility | ✅ | 2026-09-07 | [Official OffSec OSCP+ Exam FAQ](https://help.offsec.com/hc/en-us/articles/4412170923924-OSCP-Exam-FAQ) |

## Lab-validation queue

Work these before exam day, in your own authorised environment. Mark results in your personal lab log; do not mark a technique validated merely because a tool accepts the syntax.

| Priority | Notes / commands | What “validated” means |
|---|---|---|
| P0 | [[Port Scanning]], [[Nmap Cheat Sheet]] | Full TCP, targeted service scan, UDP scan, output paths, and port extraction work on your current Kali. |
| P0 | [[Reverse Shell Cheat Sheet]], [[Shell Upgrade & TTY]], [[File Transfer Cheat Sheet]] | Catch at least one Linux and one Windows shell; complete a TTY upgrade and bidirectional file transfer. |
| P0 | [[Active Directory Cheat Sheet]], [[Credential Attacks Cheat Sheet]] | Confirm installed tools, authentication formats, clock handling, and a safe lockout-aware test workflow. |
| P1 | [[SMB]], [[LDAP]], [[Kerberos]], [[WinRM]], [[MSSQL]] | Reproduce anonymous/authenticated enumeration and one permitted remote-access route per service. |
| P1 | [[Chisel]], [[Ligolo-ng]], [[Proxychains & SOCKS]], [[SSH Tunneling]] | Establish a pivot and prove both name resolution and a constrained scan behave as expected. |
| P2 | [[Linux Privilege Escalation]], [[Windows Privilege Escalation]] | Validate enumeration tooling and triage commands; test exploits only against intentionally vulnerable lab targets. |

## Per-note maintenance rule

When you change a note with commands or claims:

1. Add a short `## 🔄 VALIDATION` section only when the change is time-sensitive or has been lab-tested.
2. State the date, tool/version or authoritative source, and the result.
3. Keep untested payloads labelled **🧪 Lab verify** and target-dependent methods labelled **⚠️ Context required**.
4. Update [[Exam Workflow]] rather than copying exam-policy facts into technique notes.

## Lab-log template

```markdown
### YYYY-MM-DD — <note / technique>
- Status: ✅ / 🧪 / ⚠️
- Environment: Kali <version>; target <authorised lab + OS/service/version>
- Command: `<exact command>`
- Result: <worked / failed and observable output>
- Adjustment: <what changed, if anything>
```

## Safety and scope

Only validate against systems you own or are explicitly authorised to test. Many notes describe techniques whose applicability depends on the target and engagement rules; this register records readiness, not permission.
