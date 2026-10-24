# 🪟 Scenario 04 — Windows Web + RDP (web is the only way in)

> **Given:** a standalone with `80, 443, 3389` open. Goal: foothold → SYSTEM + proof. Branching methodology — give me the **web stack/versions** and I'll collapse it to one route; for now, fill `<placeholders>` from your own run, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]] · [[Web Enumeration]]. Foothold: [[Web Exploitation]] · [[File Upload]] · [[SQL Injection]] · [[RCE]]. Access/escalate: [[RDP]] · [[Windows Privilege Escalation]] · [[Credential Attacks]] · [[Shells]].

```bash
export IP=<TARGET_IP> ; mkdir -p nmap loot
```

---

## 🧠 READ THE PORTS (this box names its own rules)
| Port | Meaning here |
|---|---|
| **3389 RDP** | **It's Windows.** Privesc = Windows methodology; webshell type depends on the stack (ASPX vs PHP). Also: RDP is **not an entry** — it's where you land **once you hold a credential**. |
| **80 / 443** | The **only attack surface**. No SMB/RPC/LDAP here, so there's no "other service" fallback — **the web app must give you everything.** |

> **Why this matters:** with just web + RDP, you cannot lean on SMB null sessions or service CVEs. 100% of the foothold effort goes into the web app, and the kill chain is almost always **web RCE as a low-priv Windows account → token-privilege escalation to SYSTEM** (or **creds from the web → RDP → privesc**). No AD here (no 88/389/445) — treat it as a standalone Windows host, not a domain.

---

## 1️⃣ ENUMERATE THE WEB HARD (it's all you've got)
```bash
sudo nmap -sC -sV -p80,443,3389 $IP -oN nmap/services.txt
whatweb http://$IP ; whatweb https://$IP
# 443 cert often leaks the hostname / an internal domain → add to /etc/hosts, enables vhosts:
openssl s_client -connect $IP:443 2>/dev/null | openssl x509 -noout -subject -ext subjectAltName
feroxbuster -k -u https://$IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x aspx,asp,php,txt,config,bak
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -u https://$IP -H "Host: FUZZ.<domain>" -fs <size>
```
**Fingerprint the stack first — it decides your webshell:**
| You see | Stack | Webshell / angle |
|---|---|---|
| `Server: Microsoft-IIS`, `.aspx`, ViewState | **IIS + ASP.NET** | `.aspx` webshell; WebDAV `PUT`; IIS/handler CVEs |
| `X-Powered-By: PHP`, `.php` (XAMPP) | **Apache/PHP on Windows** | `.php` webshell |
| App name + version | any | **`searchsploit` the exact version first** |

## 2️⃣ FOOTHOLD — match the web surface to a bug class
| What the app shows | Route | Note |
|---|---|---|
| Known product + exact version | `searchsploit`/CVE → run PoC (read it first) | [[Web Exploitation]] · [[RCE]] |
| Upload form / file manager | bypass filter → `.aspx`/`.php` webshell in a served dir | [[File Upload]] |
| WebDAV enabled (`OPTIONS` shows `PUT`) | `PUT shell.aspx` → browse it | IIS classic |
| `?id=`/login/search | SQL injection → auth-bypass / dump creds / `xp_cmdshell` if MSSQL | [[SQL Injection]] |
| Admin panel (Tomcat/Jenkins/etc. on 80/443) | default creds → deploy/exec | [[HTTP]] |
| `?page=`/`?file=` | LFI → log/session poison → RCE | [[Web Exploitation]] |
| Template/`{{7*7}}`, ping/convert field | SSTI / command injection | [[Web Exploitation]] |

**Two outcomes:**
- **Webshell/RCE** → you're a low-priv Windows account (often `iis apppool\<site>` or a service user) → go to §3.
- **Credentials** (from SQLi dump, a config, source) → **RDP in** and privesc from a GUI session:
```bash
xfreerdp /u:<user> /p:'<pass>' /v:$IP /cert:ignore /dynamic-resolution      # reuse every cred ([[Credential Attacks]])
```

## 3️⃣ ESCALATE TO SYSTEM (the Windows web classic)
```cmd
whoami /priv & whoami /all & systeminfo
```
**The money check:** a web/service account almost always has **`SeImpersonatePrivilege`** →
```cmd
REM pick one; GodPotato covers modern Windows:
GodPotato.exe -cmd "cmd /c whoami"
PrintSpoofer.exe -i -c cmd         REM (JuicyPotato on older builds)
```
→ **SYSTEM**. If no SeImpersonate, run the rest ([[Windows Privilege Escalation]]):
```powershell
powershell -ep bypass -c ". .\PowerUp.ps1; Invoke-AllChecks"
winPEASany.exe
```
→ unquoted-service paths · weak service perms · **AlwaysInstallElevated** · stored creds (`cmdkey /list`, unattend.xml, PowerShell history, web `web.config`/`connectionStrings`) · `SeBackup`/`SeRestore`. **Harvest web-app DB creds → reuse for RDP/admin.**

---

## 🅱️ RDP-specific notes
- RDP needs creds — get them from the web first; then it's a full GUI foothold (easier privesc, file transfer, screenshots).
- **BlueKeep (CVE-2019-0708)** only affects **Win7/2008 R2 and older**; on a modern target it won't apply and is risky/unreliable — don't burn exam time on it unless `systeminfo` shows an ancient build. NLA on usually means you need valid creds anyway.

## 🗺️ DECISION FLOW
```
80/443 + 3389 ──► it's Windows, web is the only door
      ▼
fingerprint stack (IIS/ASPX vs Apache/PHP) + fuzz dirs/vhosts + read 443 cert
      ▼
web foothold:
   ├─ version CVE / upload / WebDAV / SSTI / cmdi ──► webshell (low-priv) ──┐
   └─ SQLi / config / source ──► CREDS ──► RDP (xfreerdp) ──────────────────┤
                                                                            ▼
                                                        whoami /priv
                                                   ├─ SeImpersonate ──► GodPotato/PrintSpoofer ──► SYSTEM ✅
                                                   └─ else ──► PowerUp/winPEAS ──► service/AIE/creds ──► SYSTEM ✅
```

## 🚧 STUCK?
1. Re-fuzz web with **extensions matching the stack** (`.aspx`/`.asp`/`.config` on IIS, `.php` on XAMPP) + **vhost-fuzz** with the cert hostname.
2. Check **both** 80 and 443 — they may serve **different** apps.
3. `OPTIONS` on the web root → is **WebDAV/PUT** allowed?
4. Found any cred → try it on **RDP** immediately (cred reuse wins Windows boxes).
→ [[Standalone Boxes — Exam Solve Guide]] (Stuck section).

## 🧠 ONE-LINE LESSON
**3389 means Windows and web-only means the app is the sole door: get web RCE (→ low-priv account → `SeImpersonate` → GodPotato → SYSTEM) or pull creds from the app and RDP in — then escalate with token privileges or stored creds.**
