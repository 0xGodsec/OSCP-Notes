# 🔧 HTTPS — Port 443 (+ 8443)

> **HTTP over TLS.** Same web server and app as [[HTTP]], wrapped in TLS (443 default; 8443/4443/8834/10000 = common alt-HTTPS admin panels). Everything in [[HTTP]] applies — this note covers only the **TLS/certificate-specific** surface HTTP-on-80 doesn't have: certificate intel (X.509 CN/SAN → hostnames/vhosts, OU/email → usernames), TLS protocol/cipher config, SNI-based virtual hosting. **For all app-layer enumeration and exploitation, work [[HTTP]] and [[Web Enumeration]].** TLS version/cipher issues are usually report findings, rarely the way in on OSCP.

Related: [[HTTP]] · [[Web Enumeration]] · [[Credential Attacks]]

---

## 🧠 PORT 443 → THINK
- **Read the certificate first** — CN/SAN leak **hostnames & vhosts**; org unit/email leak **usernames**.
- Then treat it exactly like [[HTTP]] (add `-k`/`https://` everywhere).
- New hostname in the cert → add to `/etc/hosts`, re-run vhost/dir enum.
- `8443`, `4443`, `8834`, `10000` = common alt-HTTPS admin panels.
- TLS version/cipher issues are usually **report findings**, rarely the way in on OSCP.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10
```

```bash
sslscan $IP:443
```

```bash
openssl s_client -connect $IP:443 -showcerts </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -ext subjectAltName
```
**Verdict:** grab hostnames/emails from the cert → add to `/etc/hosts` → then pivot to [[HTTP]] for the real enumeration.

## ⏱️ ENUMERATE (TLS-specific)
```bash
# Full certificate (CN, SAN, org, email — the intel that matters)
openssl s_client -connect $IP:443 </dev/null 2>/dev/null | openssl x509 -noout -text
```

```bash
# Full TLS posture + cert + weak ciphers + Heartbleed check
sslscan $IP:443
```

```bash
nmap -p443 --script ssl-cert,ssl-enum-ciphers,ssl-heartbleed -sV $IP
```
**Look for:** extra hostnames in **SAN** (→ vhosts), **emails/OU** (→ usernames for [[Credential Attacks]]), wildcard/internal names, expired/self-signed (dev box hint). SNI/vhost routing means the IP may serve a different site per Host header/SNI — the cert tells you which names to try. Then run the **full [[HTTP]] methodology** with `-k`.

## 🗡️ EXPLOIT
- 🟢 **Cert-driven vhost/username discovery** → feeds [[HTTP]] vhost fuzzing + [[Credential Attacks]].
- 🟡 **Alt HTTPS admin panels** (8443, 10000/Webmin, etc.) → default creds / known CVEs (verify version).
- 🔵 **Heartbleed (CVE-2014-0160)** memory leak — only if `ssl-heartbleed` flags it and the version matches; can leak keys/creds.
- 🔵 **Weak TLS / expired / self-signed** — report-only unless it enables something concrete.
- ➡️ **All app-layer vectors** (SQLi, LFI, upload, RCE, auth bypass): see [[HTTP]] / [[_MOC (Initial Access)|03 - Initial Access]].

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| Hostname in CN/SAN | Vhost hint | add to `/etc/hosts` → vhost + dir enum ([[HTTP]]) | new site |
| Email / OU in cert | Usernames | build `users.txt` → [[Credential Attacks]] | spray/roast fuel |
| Alt HTTPS port (8443…) | Admin UI | fingerprint → default creds / CVE | admin access |
| `ssl-heartbleed` VULNERABLE | Memory leak | validated Heartbleed PoC | keys/creds |
| Self-signed / dev CN | Non-prod box | expect debug endpoints; enum harder | more surface |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Cert cURL errors | Add `-k` (ignore cert) to every request |
| Site differs by hostname | It's SNI/vhost-based — request with the cert's hostname (`curl -k -H "Host: name" https://$IP`) |
| Nothing in the cert | Fall straight through to [[HTTP]] enumeration on 443 |
| Only weak-cipher/expired findings | Note for the report; don't rabbit-hole — pivot to app layer |
| Tools reject old TLS | `openssl s_client` with explicit `-tls1_1` etc.; use `sslscan` |

## 📋 REFERENCE — don't-miss · stop
**Don't miss:** dump the cert (`ssl-cert` / `openssl x509 -text`) → CN, **SAN**, OU, email · add every cert hostname to `/etc/hosts`, re-enumerate vhosts ([[HTTP]]) · harvest emails/OU → `users.txt` ([[Credential Attacks]]) · check alt HTTPS ports (8443/4443/10000) · `ssl-heartbleed` / `ssl-enum-ciphers` (validate before trusting) · then run the **full [[HTTP]] methodology** with `-k`.
**Mindset:** 443 is HTTP with a free intel gift — read the certificate before anything, add names to `/etc/hosts`, then stop treating it as "HTTPS" and run your full [[HTTP]] / [[Web Enumeration]] methodology. TLS vulns are usually report material, not the door.
**Stop when:** cert intel harvested, hostnames added, alt ports checked, and the full [[HTTP]] methodology worked → HTTPS is exhausted as a distinct surface. Everything further is app-layer (→ [[HTTP]] / [[_MOC (Initial Access)|03 - Initial Access]]) or a report-only TLS finding.

## 📇 CHEAT SHEET
```bash
openssl s_client -connect $IP:443 </dev/null 2>/dev/null | openssl x509 -noout -text   # cert (CN/SAN/OU/email)
```

```bash
nmap -p443 --script ssl-cert,ssl-enum-ciphers,ssl-heartbleed -sV $IP
```

```bash
sslscan $IP:443
```
**Kill shots:** cert SAN → hidden vhost → [[HTTP]] foothold · cert emails → usernames → [[Credential Attacks]].
