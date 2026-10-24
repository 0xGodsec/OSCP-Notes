# 🧪 Standalone Scenarios (Map of Content)

> A growing bank of worked **standalone-box scenarios**: given a port/service picture, the route(s) to solve it and *why*. Pattern-matching practice for the exam — recognise the shape of a box fast. Method lives in [[Standalone Boxes — Exam Solve Guide]]; this is applied practice.

Back to [[_MOC (Methodology)]] · [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]].

## Scenarios
- [[Scenario 01 — Roundcube Mail Server]] — `22,25,43,80,110,143,443,3306`, Roundcube 1.4.2. Mail-cred chain vs. direct MTA (Exim) RCE.
- [[Scenario 02 — Cloud Web Hosting (brochure page)]] — static hosting template, nothing else known. Recon-from-zero: brochure is a decoy → enumerate hidden surface (dirs + vhosts + panel ports) → branch to the foothold.
- [[Scenario 03 — FTP + Apache Index (vsftpd 3.0.5)]] — `21,22,80` Ubuntu, `Index of /` on web. Anon FTP → write-to-webroot check → upload PHP shell → trigger over HTTP (no vsftpd CVE — config, not exploit).
- [[Scenario 04 — Windows Web + RDP (80,443,3389)]] — Windows standalone, web is the only door. Web RCE → low-priv → `SeImpersonate`→GodPotato→SYSTEM, or creds→RDP→privesc.
- [[Scenario 05 — Windows Multi-Service (SMB, Postgres, WinRM, RDP)]] — `80,135,139,443,445,3389,5432,5985`. Breadth-first: Postgres default-cred `COPY FROM PROGRAM` RCE / SMB null share → one credential reused across SMB/WinRM/RDP → SeImpersonate→SYSTEM.
- [[Scenario 06 — WBCE CMS (authenticated RCE)]] — WBCE CMS admin login at `/admin/login/`. Two-step: get admin creds (default/looted) → authenticated RCE (Droplets PHP / module upload) → web shell → loot DB config → privesc.
- [[Scenario 07 — 403 Forbidden Directory (IIS bypass)]] — restricted dir returns IIS 403. Bypass the path (slashes/dots/case, `X-Original-URL`, method swap) or fuzz files inside it (+ IIS 8.3 short-name) → hidden content = foothold → SeImpersonate→SYSTEM.
- [[Scenario 08 — Anonymous FTP leaks db_connect.php]] — anon FTP exposes `db_connect.php` with DB creds. Reuse-first: test the password across SSH/WinRM/SMB/web/DB; DB login dumps crackable hashes or gives RCE (`INTO OUTFILE`/`xp_cmdshell`/`COPY PROGRAM`) → privesc.

## How to use
1. Read the **ports** and say out loud what the box probably is before scrolling.
2. Compare your plan to the scenario's **routes** and the **reasoning** for each.
3. On a real box, follow the matching route; fill the `<placeholders>` from your own output.

> New scenario? It gets its own `Scenario NN — <name>` note here and a row above.
