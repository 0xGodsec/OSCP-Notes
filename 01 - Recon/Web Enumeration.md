# 🕸️ Web Enumeration (Hub)

> Shared web-recon reference used by [[HTTP]] and any app on a high port. This is the *how-to* for content/vhost/parameter discovery and stack fingerprinting; the full attack methodology lives in [[HTTP]].

Related: [[HTTP]] · [[Credential Attacks]] · [[Shells]]

---

## 1. FINGERPRINT THE STACK

```bash
export URL=http://$IP
```

```bash
whatweb -a3 $URL
```

```bash
curl -sI $URL                 # Server, X-Powered-By, Set-Cookie
```

```bash
curl -s $URL | grep -i 'generator\|<!--\|jquery\|bootstrap'
```
| Cookie / header | Stack | Implication |
|---|---|---|
| `PHPSESSID` | PHP | Linux likely; `.php` ext for busting |
| `JSESSIONID` | Java/Tomcat | 8080 manager, WAR deploy |
| `ASP.NET_SessionId` / `Server: IIS` | .NET/Windows | `.aspx`; potato privesc later |
| `connect.sid` | Node/Express | JS endpoints, prototype pollution |
| `Server: nginx/Apache` | reverse proxy | look for backends/vhosts |

## 2. CONTENT DISCOVERY (dirs & files)

```bash
feroxbuster -u $URL -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,txt,html,bak -r -t 50
```

```bash
gobuster dir -u $URL -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -x php,txt,html -t 50
```

```bash
ffuf -w /usr/share/seclists/Discovery/Web-Content/raft-medium-words.txt -u $URL/FUZZ -e .php,.txt,.bak
```
- Match **`-x` extensions to the stack** (php/aspx/jsp/txt/bak/zip).
- Escalate wordlist if empty: `directory-list-2.3-big`, `raft-large-*`.
- **403** = it exists → enumerate inside / try bypass. **301** → follow, often a dir.

## 3. VIRTUAL HOST / SUBDOMAIN DISCOVERY

```bash
# Get a base domain from the cert or a redirect first, then:
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
  -u $URL/ -H "Host: FUZZ.target.htb" -fs <baseline-size>
```

```bash
gobuster vhost -u $URL --domain target.htb -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt --append-domain
```
- Add hits to `/etc/hosts`: `echo "$IP dev.target.htb" | sudo tee -a /etc/hosts`.
- **Filter the default response** with `-fs`/`-fc`/`-fw` or you get all-200 noise.

## 4. PARAMETER DISCOVERY

```bash
ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -u "$URL/page.php?FUZZ=1" -fs <baseline>
```

```bash
# or arjun:
arjun -u "$URL/page.php"
```
Hidden params → injection surface (LFI/SQLi/cmdi).

## 5. ALWAYS-CHECK FILES

```bash
for f in robots.txt sitemap.xml .git/HEAD .env config.php web.config wp-config.php \
         backup.zip phpinfo.php server-status .htaccess .DS_Store; do
  printf "%s -> " $f; curl -s -o /dev/null -w "%{http_code}\n" $URL/$f; done
```
- `.git/HEAD` = 200 → `git-dumper $URL/.git ./loot` → source + secrets.
- `robots.txt` disallow entries = dev's own hidden-path list.

## 6. TLS CERTIFICATE (443)

```bash
echo | openssl s_client -connect $IP:443 2>/dev/null | openssl x509 -noout -text | grep -A1 'Subject:\|DNS:'
```
CN/SAN → hostnames (→ /etc/hosts, vhost fuzz); emails → usernames.

## 7. CMS-SPECIFIC

```bash
wpscan --url $URL --enumerate ap,at,u        # WordPress: plugins, themes, users
```

```bash
droopescan scan drupal -u $URL               # Drupal
```

```bash
joomscan --url $URL                          # Joomla
```

```bash
nuclei -u $URL                               # templated CVE/exposure scan
```

## 8. READ THE APP BY HAND

- **View source**: comments, hidden fields, dev notes, credentials.
- **Pull every JS file**: endpoints, API routes, keys, params.
- Proxy through **Burp**: map every request; use Repeater for testing, Intruder for light fuzzing.

---

## 🔁 FOUND → NEXT

| FINDING | NEXT |
|---|---|
| Product+version | `searchsploit`/`nuclei` → CVE |
| CMS | wpscan/droopescan/joomscan |
| 403 dir | fuzz inside; bypass headers |
| Default page only | **vhost fuzz** + high ports |
| `.git`/backup/.env | dump → source + creds |
| Cert hostname | /etc/hosts → refuzz vhost |
| Hidden param | test LFI/SQLi/cmdi |
| Login page | → [[HTTP]] auth attacks |

## 🚧 FAILED → NEXT

| Stuck | Try |
|---|---|
| Nothing from dir brute | bigger wordlist, add extensions, trailing `/`, recurse, case variants |
| Only default page | vhost fuzz (Host header), scan 8080/8443/3000/5000/8000, re-read JS/source |
| ffuf all-200 noise | set `-fs`/`-fc`/`-fw`/`-ac` from baseline |
| Cert has no names | brute vhosts with a wordlist anyway; check redirects/links for hostnames |

## ⚠️ COMMON MISTAKES

- Not vhost-fuzzing a generic default page.
- Skipping alternate HTTP ports.
- Wrong/no extensions in dir brute.
- Ignoring 403 and JS files.
- Not reading the cert on 443.

## 📇 CHEAT SHEET

```bash
whatweb -a3 $URL ; curl -sI $URL
```

```bash
feroxbuster -u $URL -w .../raft-medium-directories.txt -x php,txt,bak -r
```

```bash
ffuf -w .../subdomains-top1million-5000.txt -u $URL/ -H "Host: FUZZ.dom.tld" -fs <n>
```

```bash
echo | openssl s_client -connect $IP:443 2>/dev/null | openssl x509 -noout -text | grep DNS:
```

```bash
wpscan --url $URL --enumerate ap,u ; nuclei -u $URL
```

```bash
git-dumper $URL/.git ./loot
```
**Order:** fingerprint → dir brute (right ext) → vhost fuzz → cert → always-check files → CMS scan → read source/JS → hand off to [[HTTP]] attacks.
