# 🌐 DNS — Port 53

> **Domain Name System** (53/udp queries, 53/tcp zone transfers & large responses; BIND/Microsoft DNS/dnsmasq/PowerDNS). On OSCP, DNS matters when the box is a **name server** (often a Domain Controller): a **zone transfer (AXFR)** can dump every hostname in the domain, reverse lookups + subdomain brute expand your target map, and SRV records (`_ldap._tcp`, `_kerberos._tcp`) confirm AD.

Related: [[Active Directory]] · [[HTTP]] · [[SMB]]

---

## 🧠 PORT 53 → THINK
- **Zone transfer (AXFR)** — can I dump all records? Huge win: every internal hostname.
- **Is this a DC?** 53 + 88 + 389 + 445 → [[Active Directory]].
- **Get the domain name** (from PTR, cert, SMB) → then brute subdomains / vhosts ([[HTTP]]).
- **Reverse lookups** across the subnet → hostnames.
- Add discovered names to `/etc/hosts`.

## ⚡ QUICK TRIAGE (60 sec)
```bash
export IP=10.10.10.10 DOMAIN=corp.local
```

```bash
nmap -p53 -sV -sC $IP
```

```bash
dig axfr @$IP $DOMAIN                 # zone transfer attempt
```

```bash
dig @$IP $DOMAIN any
```
**Verdict:** AXFR succeeds → dump + map everything. Fails → brute subdomains, reverse-lookup, note the domain.

## ⏱️ ENUMERATE
```bash
# Zone transfer (the big one, TCP 53) — try the domain from cert/SMB/PTR
dig axfr @$IP $DOMAIN
```

```bash
host -l $DOMAIN $IP
```

```bash
fierce --domain $DOMAIN --dns-servers $IP
```

```bash
# Basic records + reverse + find the domain
dig @$IP $DOMAIN ns ; dig @$IP $DOMAIN mx ; dig @$IP $DOMAIN txt
```

```bash
dig @$IP -x $IP                       # reverse (PTR) for this host
```

```bash
nmap -p53 --script dns-nsid $IP
```

```bash
# Subdomain brute (when AXFR is refused)
dnsenum --dnsserver $IP $DOMAIN
```

```bash
gobuster dns -d $DOMAIN -r $IP -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt
```

```bash
# Reverse-sweep the subnet through this DNS server
for i in $(seq 1 254); do dig @$IP -x 10.10.10.$i +short | grep -v '^$' | sed "s/^/10.10.10.$i /"; done
```

```bash
nmap -p53 --script "dns-*" $IP
```
**Look for:** AXFR success (full record dump), hostnames, subdomains, mail servers, internal IPs, SRV records (→ AD).

## 🗡️ EXPLOIT
- 🟢 **Zone transfer (AXFR)** → dump all hostnames.
- 🟡 **Subdomain/vhost brute** → new web targets.
- 🟡 **Reverse lookups** → host discovery.
- 🔵 **DNS server CVEs** (rare) — `searchsploit bind` if a version shows.

DNS is a **map expander**, rarely the shell: AXFR = the entire internal namespace in one command → new hosts/apps to attack; expands vhosts for web enum; confirms AD and reveals service locations.

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| AXFR succeeds | Full record dump | add all names to /etc/hosts | new targets |
| Subdomains found | More apps | vhost enum on each | new web surface |
| SRV records (`_ldap`) | It's AD | [[Active Directory]] | domain attack |
| MX/mail host | SMTP target | enumerate that host | userlist |
| Internal IPs in records | Hidden hosts | scan them (pivot?) | more surface |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| AXFR refused | Brute subdomains (`dnsenum`/`gobuster dns`), reverse-lookup sweep |
| Don't know the domain | Get it from cert (443), SMB (`netexec smb`), PTR (`dig -x`), or the website |
| No records at all | DNS may just be resolving for the box; grab the domain and move on |
| TCP 53 filtered | Zone transfer needs TCP — retry `dig +tcp axfr` |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** not knowing the **domain name** to request AXFR (get it from cert/SMB first) · forgetting AXFR uses **TCP 53** · not adding discovered hostnames to **/etc/hosts** (breaks vhost/AD access) · ignoring **SRV records** that scream "AD".
**Cross-service:** hostnames → [[HTTP]] vhosts · domain + SRV → [[Active Directory]] · new IPs → additional targets / [[Pivoting and Port Forwarding]].
**Don't miss:** get the **domain name** (cert/SMB/PTR) · `dig axfr @IP domain` (TCP) · subdomain brute if AXFR fails · reverse-lookup sweep · add all names to **/etc/hosts** · note SRV records → AD.
**Stop when:** AXFR tried, subdomains brute-forced, names added to hosts → move on. DNS is rarely the shell, it's the map.

## 📇 CHEAT SHEET
```bash
dig axfr @$IP $DOMAIN                 # zone transfer
```

```bash
dnsenum --dnsserver $IP $DOMAIN
```

```bash
gobuster dns -d $DOMAIN -r $IP -w .../subdomains-top1million-5000.txt
```

```bash
dig @$IP -x $IP                       # reverse
```

```bash
nmap -p53 --script "dns-*" $IP
```

```bash
echo "$IP host.$DOMAIN $DOMAIN" | sudo tee -a /etc/hosts
```
**Kill shots:** AXFR dump → full namespace · subdomains → new web apps · SRV → AD.
