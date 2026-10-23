# 🐚 08 — Shells & Payloads (Map of Content)

> Land a shell, upgrade it, move files — and pivot through it to internal networks. Two hubs live here: [[Shells]] and [[Pivoting and Port Forwarding]].

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]].

## Shells
- [x] [[Shells]] — **hub / index** (the reflex on RCE, router)
- [x] [[Reverse & Bind Shells]] — one-liners + listeners
- [x] [[Shell Upgrade & TTY]] — python pty + `stty raw -echo`
- [x] [[msfvenom Payloads]] — exe/elf/php/aspx/war/msi
- [x] [[Web Shells]] — upload/LFI/OUTFILE → `?c=` RCE
- [x] [[File Transfer]] — tools on / loot off (HTTP/SMB/nc/scp)

## Pivoting
- [x] [[Pivoting and Port Forwarding]] — **hub / index** (discover internal net, pick a tunnel)
- [x] [[SSH Tunneling]] — `-L`/`-D`/`-R` (when you have SSH creds)
- [x] [[Chisel]] — reverse SOCKS with just a shell
- [x] [[Ligolo-ng]] — TUN route, no proxychains
- [x] [[Proxychains & SOCKS]] — using a SOCKS proxy (`-sT -Pn`)

## Reflex
On RCE: listener up → reverse shell → **upgrade TTY** → transfer tools → loot → privesc.
Condensed: [[Reverse Shell Cheat Sheet]] · [[File Transfer Cheat Sheet]].

## Run this order after code execution
1. Start the listener before triggering the payload.
2. Use [[Reverse & Bind Shells]] to obtain a shell, then [[Shell Upgrade & TTY]] to stabilise it.
3. Use [[File Transfer]] only for the tools/data needed for the next validated step.
4. Enumerate the host and choose [[Linux Privilege Escalation]], [[Windows Privilege Escalation]], or [[Active Directory]].
5. If the foothold has a second subnet, switch to [[Pivoting and Port Forwarding]].
