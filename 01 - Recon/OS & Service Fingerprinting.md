# 🔎 OS & Service Fingerprinting

> Turning open ports into **exact identities**: which OS, which product, which **version** — because *version → `searchsploit` → exploit* is the fastest OSCP foothold, and OS decides your privesc path ([[Linux Privilege Escalation]] vs [[Windows Privilege Escalation]]). When nmap can't name a version, banner-grab it by hand.

Related: [[Port Scanning]] · [[Recon Methodology]] · [[Exploitation Methodology]] · [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]]

---

## 🧠 FINGERPRINTING → THINK
- **Get the exact version string** — "Apache 2.4.49" beats "a web server" (that specific one has a path-traversal RCE, for instance — verify per target).
- **OS first-guess** from ports: 135/139/445/3389/5985 = Windows; 22 + typical Linux services = Linux.
- **nmap version blank?** → banner-grab manually (`nc`, `curl -I`, `openssl s_client`).
- Feed every version into `searchsploit` and note it for the report.

## ⚡ NMAP FINGERPRINTING
Version + default scripts (your main source):
```bash
sudo nmap -sC -sV -p<list> $IP -oN nmap/services.txt
```
Try harder on stubborn versions:
```bash
sudo nmap -sV --version-intensity 9 -p<port> $IP
```
OS detection (needs raw sockets; often approximate):
```bash
sudo nmap -O $IP
```

## 🧪 MANUAL BANNER GRABBING (when nmap is vague)
Generic TCP banner:
```bash
nc -nv $IP <port>
```
HTTP server header:
```bash
curl -I http://$IP
```
```bash
whatweb http://$IP
```
TLS service + cert (also reveals hostnames — see [[HTTPS]]):
```bash
openssl s_client -connect $IP:443 </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer
```
SMB/OS details:
```bash
nmap -p445 --script smb-os-discovery $IP
```
SSH/FTP/SMTP just print a banner on connect (`nc`), often naming the exact daemon/version.

## 🧭 OS TELLS
| Signal | Likely OS |
|---|---|
| 135/139/445, 3389, 5985 open | Windows |
| 22 + apache/nginx/postfix, `/etc/*` LFI works | Linux |
| TTL ~128 (ping/nmap) | Windows |
| TTL ~64 | Linux/Unix |
| SMB `smb-os-discovery` string | exact Windows build |
| HTTP `Server:` / `X-Powered-By:` | web stack + sometimes OS |
| SSH banner (`OpenSSH ... Debian/Ubuntu`) | Linux distro hint |

> TTL is a hint, not proof (routers/tuning change it) — corroborate with services.

## 🔗 VERSION → ACTION
```bash
searchsploit <product> <version>
```
```bash
nuclei -u http://$IP -t http/          # for web stacks
```
- Match found? → read/adapt the PoC ([[Exploitation Methodology]]).
- Web product? → also fingerprint CMS/framework ([[Web Enumeration]]).
- OS known? → pre-stage the right privesc tooling (linPEAS / winPEAS).

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| nmap version blank | `--version-intensity 9`; manual `nc`/`curl -I`/`openssl s_client` |
| Custom/obscured banner | Compare responses; check error pages, HTTP headers, favicon hash, JS paths |
| OS unclear | Correlate ports + TTL + SMB/HTTP strings; try an LFI file test (`/etc/passwd` vs `win.ini`) |
| Version but no exploit | Enumerate deeper / look for logic bugs; it may not be the intended path |
| Multiple services, unsure which | Prioritise the one with a known-version public exploit |

## ⚠️ COMMON MISTAKES
- Settling for "a web server" instead of the **exact version**.
- Not **manually banner-grabbing** when nmap is vague.
- Trusting **TTL alone** for OS.
- Not running the version through `searchsploit`.
- Ignoring the **cert/HTTP headers** as identity + hostname sources.

## ✅ DON'T MISS
- [ ] `-sC -sV` on every open port
- [ ] Manual banner grab where version is unknown
- [ ] OS guess from ports + SMB/HTTP strings (+ TTL as hint)
- [ ] Every version → `searchsploit`
- [ ] Web → `whatweb`/`nuclei` + CMS fingerprint ([[Web Enumeration]])
- [ ] Record versions + OS for report and privesc choice

## 📇 CHEAT SHEET
```bash
sudo nmap -sC -sV -p<list> $IP -oN nmap/services.txt
```
```bash
nc -nv $IP <port>      ;   curl -I http://$IP   ;   whatweb http://$IP
```
```bash
nmap -p445 --script smb-os-discovery $IP
```
```bash
searchsploit <product> <version>
```
**Kill flow:** exact version + OS → searchsploit → exploit; OS → pick the right privesc path.
