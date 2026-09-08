# 🔎 01 — Recon (Map of Content)

> Everything before you touch a specific service: find the host, find its ports, find its web surface. Then hand off to the matching note in `02 - Services`.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]].

## Notes in this folder
- [x] [[Web Enumeration]] — dir/vhost busting, source/JS review, CMS scan, certs. *(written)*
- [x] [[Port Scanning]] — full TCP sweep, targeted `-sC -sV`, UDP top-ports, re-scan discipline. (See [[00 - START HERE (OSCP Playbook Index)|Universal First Moves]].)
- [x] [[Host Discovery]] — live-host checks on a subnet, ping sweeps, when to skip host discovery (`-Pn`).
- [x] [[OS & Service Fingerprinting]] — banner grabbing, TTL/OS hints, mapping versions → searchsploit.

## Reminders
- `export IP=...` once; `mkdir nmap` before `-oN`.
- Every new hostname/vhost → add to `/etc/hosts`, re-enumerate.
- A new open port = open its `02 - Services` note and work the decision tree.
