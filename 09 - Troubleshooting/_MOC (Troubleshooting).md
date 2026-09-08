# 🧯 09 — Troubleshooting (Map of Content)

> "It should work but it doesn't." Fast playbooks for the dead-air moments so you don't burn exam time. Each service note has its own **FAILED → NEXT** table; this folder holds the cross-cutting ones.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]].

## Notes in this folder
- [x] [[No Open Ports]] — everything filtered? `-Pn`, full range, UDP, slow the scan, check VPN/routing.
- [x] [[Reverse Shell Not Connecting]] — listener up? right IP/interface (tun0)? egress port (try 443/53)? payload/OS mismatch? → [[Shells]].
- [x] [[Exploit Fails]] — wrong arch/version, offsets, LHOST, target patched; adapt PoC vs move on.
- [x] [[Credentials Rejected]] — format (`DOMAIN\user`, `user@domain`), clock skew (Kerberos), account not authorised for that service, lockout.
- [x] [[Shell Is Unstable]] — TTY upgrade, `stty`, rlwrap, switch to a better shell/transport → [[Shells]].
- [x] [[Tool Not Working]] — Kali package quirks, Python/impacket versions, missing clients (`rsh-client`, `mongosh`, Instant Client).
- [x] [[Stuck — What Now]] — the meta checklist: re-read enumeration, revisit skipped ports, test cred reuse everywhere, take a break.

## Golden rules
- ~20–30 min of true dead-air on a service → move on, come back later.
- 90% of "stuck" is missed enumeration — re-read your own notes first.
- Every credential → test on **every** other service ([[Credential Attacks]]).
