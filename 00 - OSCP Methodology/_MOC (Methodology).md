# 🧭 00 — OSCP Methodology (Map of Content)

> The repeatable **process** you run on every box, independent of which service is open. Service-specific steps live in [[00 - START HERE (OSCP Playbook Index)|02 - Services]]; this folder is the *how you think*, not the *what you type*.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]].

## Notes in this folder
- [x] [[Exam Workflow]] — end-to-end exam day: time-boxing, box order, note-taking, screenshots, proof files, reporting.
- [x] [[Recon Methodology]] — the scanning game plan (full TCP → targeted `-sC -sV` → UDP → re-scan on new info). Links to [[00 - START HERE (OSCP Playbook Index)|Universal First Moves]] and `01 - Recon`.
- [x] [[Enumeration Methodology]] — per-service enumeration discipline: what "exhausted" means, MUST-CHECK vs OPTIONAL, avoiding rabbit holes.
- [x] [[Exploitation Methodology]] — from vuln → validated → exploited → shell; searchsploit workflow, adapting public PoCs, staying in scope.
- [x] [[Troubleshooting Methodology]] — the meta-note for `09 - Troubleshooting`: how to react when nothing works.
- [x] [[Post-Engagement Cleanup]] — track what you drop and revert it; drop-log, artifact removal (Linux/Windows), report hygiene.
- [x] [[Validation Register]] — authoritative-review dates and lab-validation queue for the vault.

## The loop
```
Recon (01) → per-open-port Service note (02) → Initial Access (03) → shell
   → PrivEsc (04/05, +06 if AD) → loot → Credentials reuse (07) → next host
```
Support at every stage: [[Shells]] · [[Pivoting and Port Forwarding]] · `09 - Troubleshooting`.
