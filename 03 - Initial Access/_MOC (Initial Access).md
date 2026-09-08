# 💥 03 — Initial Access (Map of Content)

> How a discovered surface (usually web, from [[HTTP]] / [[Web Enumeration]]) turns into a **shell or credentials**. Service notes point *here* for the deep technique; this folder holds the reusable exploitation playbooks.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]].

## Notes in this folder
- [x] [[Web Exploitation]] — umbrella: methodology for turning a web app into RCE; routes to the notes below.
- [x] [[File Upload]] — extension/MIME/magic-byte bypasses, double extensions, `.htaccess`, webshell → reverse shell.
- [x] [[Command Injection]] — detection, blind/OOB, filter bypass, chaining to a reverse shell.
- [x] [[SQL Injection]] — union/error/blind/boolean/time, `sqlmap` workflow, auth bypass, `--os-shell`, file read/write.
- [x] [[SSTI]] — template-engine detection (`{{7*7}}`), Jinja2/Twig/Freemarker → RCE.
- [x] [[LFI]] — path traversal, PHP wrappers/filters, log poisoning, `/proc/self/environ` → RCE.
- [x] [[RFI]] — remote include prerequisites, hosting the payload, PHP settings that enable it.
- [x] [[SSRF]] — internal port scan, cloud metadata, gopher/redis, filter bypass.
- [x] [[RCE]] — deserialization, known-CVE PoCs, upload/injection endpoints → stable shell → [[Shells]].

## Handoff
Every success here → get a proper reverse shell ([[Shells]]) → identify OS → [[Linux Privilege Escalation]] / [[Windows Privilege Escalation]]; loot creds → [[Credential Attacks]].
