# 🎯 Standalone Boxes — Exam Solve Guide

> The 3 standalone machines are **60 of the 100 points** — each is an independent `recon → foothold → local privesc → proof` loop with no AD chaining. This is the repeatable workflow and the common routes that actually land them. Generalized methodology; fill box-specific values from your own run.

Related: [[Exam Workflow]] · [[Recon Methodology]] · [[Enumeration Methodology]] · [[Web Exploitation]] · [[Shells]] · [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]]. AD set: [[Exam AD Set — Solve Overview]].

```bash
export IP=<TARGET_IP> ; mkdir -p nmap loot
```

---

## 1. RECON — never skip a port
```bash
sudo nmap -p- --min-rate 5000 -T4 $IP -oN nmap/allports.txt
sudo nmap -sC -sV -p<open,ports> $IP -oN nmap/services.txt
sudo nmap -sU --top-ports 100 $IP -oN nmap/udp.txt
```
Missed port = missed box. ([[Port Scanning]]) → OS guess from ports: `.php`/22/Apache = Linux; 445/3389/5985/`.aspx` = Windows.

## 2. ENUMERATE every service breadth-first
Work **every** open service shallowly before going deep on one ([[Services — Ordered Workflow]]):
- **Version → `searchsploit`** for each service — a known-version CVE is the fastest foothold.
- **Anonymous / default / weak creds** everywhere (FTP anon, SMB null, default app logins).
- **Web (80/443/alt ports)** gets the most time → [[Web Enumeration]]: `whatweb`, dir/vhost brute, read source/JS, check the cert, CMS scan.

## 3. FOOTHOLD — pick the route the surface hands you
| What you see | Route | Note |
|---|---|---|
| Known product + exact version | `searchsploit`/`nuclei` → run the PoC (read it first) | [[RCE]] · [[Exploitation Methodology]] |
| Upload form | bypass filter → webshell | [[File Upload]] |
| `?id=`/login/search | SQL injection (auth bypass / dump / `--os-shell`) | [[SQL Injection]] |
| `?page=`/`?file=` | LFI → log/session poison → RCE | [[LFI]] |
| ping/convert/"utility" field | command injection | [[Command Injection]] |
| `{{7*7}}`→49 | SSTI → RCE | [[SSTI]] |
| CMS (WordPress/Drupal/Joomla) | scanner → plugin/theme CVE | [[Web Enumeration]] |
| Default-cred admin panel (Tomcat/Jenkins/phpMyAdmin) | log in → deploy/exec | [[HTTP]] |
| Anonymous files (FTP/SMB/NFS) | loot → creds/keys → SSH/WinRM | [[FTP]] · [[SMB]] · [[NFS]] |
| DB reachable | weak creds → `xp_cmdshell`/`COPY FROM PROGRAM`/`INTO OUTFILE` | [[MSSQL]] · [[PostgreSQL]] · [[MySQL]] |

**Rule:** known software → `searchsploit` **before** hand-rolling; custom app → match each input to its bug class.

## 4. STABILISE the shell (immediately)
```bash
python3 -c 'import pty;pty.spawn("/bin/bash")'      # then: Ctrl+Z ; stty raw -echo; fg ; export TERM=xterm
```
Windows → prefer `evil-winrm` / a Meterpreter session. ([[Shell Upgrade & TTY]] · [[Shells]]) Grab `local.txt` + screenshot now.

## 5. LOCAL PRIVESC — OS decides the path
Run the automated enum **and** the manual quick-wins.

**Linux** ([[Linux Privilege Escalation]]):
```bash
id; sudo -l; uname -a
find / -perm -4000 -type f 2>/dev/null ; getcap -r / 2>/dev/null
cat /etc/crontab; ls -la /etc/cron.* ; ./linpeas.sh | tee loot/linpeas.txt
```
→ `sudo -l` (GTFOBins) · SUID · cron (`pspy`) · PwnKit/kernel · creds on disk · caps · writable files · docker/lxd.

**Windows** ([[Windows Privilege Escalation]]):
```cmd
whoami /priv & whoami /all & systeminfo
powershell -ep bypass -c ". .\PowerUp.ps1; Invoke-AllChecks"
```
→ `SeImpersonate` → PrintSpoofer/GodPotato · weak/unquoted services · AlwaysInstallElevated · stored creds (`cmdkey`/unattend/PS history) · WES-NG patches.

## 6. PROOF + loot
```bash
# Linux:  cat /root/proof.txt ; cat /home/*/local.txt
# Windows: type C:\Users\Administrator\Desktop\proof.txt
```
Screenshot each flag **with the target IP** (`ip a` / `ipconfig`) + `id`/`whoami` in frame, and **submit in the control panel** ([[Exam Workflow]]). Save every cred/key — even on a standalone, it may unlock another target.

---

## ⏱️ Time discipline (the real exam killer)
- **Rotate on ~20–30 min of dead air** — move to another target, come back fresh ([[Troubleshooting Methodology]]).
- One MSF target only — spend it on the box that most needs it.
- Enumerate **all 3 standalones in parallel** early (launch `nmap` on every target first).

## 🚧 Stuck on a standalone?
1. Re-scan: full `-p-` + **UDP** + `-Pn` — did you miss a port?
2. Web: re-fuzz dirs **and** params, read JS/source, **vhost-fuzz**, check alt HTTP ports.
3. Every service **version → searchsploit**; every **anonymous/default** path tried?
4. Found creds anywhere → reuse on every service on this box.
5. Have a shell but no root → re-run linPEAS/winPEAS fully; check **other users'** files; `pspy` for hidden cron; `whoami /priv`.
→ full checklist: [[Stuck — What Now]].

## 🧠 The one-line rule
**Scan everything → enumerate every service shallow → version/CVE or input→bug-class for the foothold → stabilise → config-privesc before kernel → proof + screenshot.** Don't marry one box; rotate.
