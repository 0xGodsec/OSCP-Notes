# 📟 SNMP — Port 161 (UDP)

> **Simple Network Management Protocol.** A UDP service (161 queries, 162 traps) that is *easy to forget* (not in a default TCP scan) and *very rewarding*: with a guessable **community string** (the "password": RO `public`, RW `private`) it leaks users, processes, running software, network config, and sometimes **plaintext credentials** in process command-line args. v1/v2c = cleartext community string; v3 = username+auth (harder). Always UDP-scan for it.

Related: [[Credential Attacks]] · [[SMB]] · [[SSH]]

---

## 🧠 PORT 161 → THINK

- **It's UDP** — a normal TCP scan misses it. `nmap -sU` or you'll never see it.
- **Community string** = the "password". Try `public`, `private`, `manager`.
- **What leaks?** users (`.4.1.77.1.2.25`), processes, installed software, listening ports, ARP, and **process command lines with passwords in them**.
- **v1/v2c = no encryption**, community string in cleartext. v3 = auth (harder).
- Feeds [[Credential Attacks]] (usernames + sometimes passwords) and [[SMB]] / [[SSH]].

---

## ⚡ QUICK TRIAGE (60 sec)

```bash
export IP=10.10.10.10
```

```bash
sudo nmap -sU -p161 -sV $IP
```

```bash
snmpwalk -v2c -c public $IP | head        # if this returns data → jackpot, walk it fully
```
**Verdict:** data returned on `public`/`private` → 🟢 walk everything. Nothing → brute community strings, else move on.

---

## ⏱️ ENUMERATE

```bash
# Find valid community string(s) — try public, private, manager, community, admin, vendor defaults
onesixtyone -c /usr/share/seclists/Discovery/SNMP/common-snmp-community-strings.txt $IP
```

```bash
hydra -P /usr/share/seclists/Discovery/SNMP/common-snmp-community-strings.txt -u $IP snmp
```

```bash
# Walk the full tree with a found string (v2c is easiest), then grep for secrets
snmpwalk -v2c -c public $IP > snmp_full.txt
```

```bash
grep -iE 'pass|pwd|cred|user|login|key' snmp_full.txt
```

```bash
# snmp-check gives a clean, human-readable summary (best single tool)
snmp-check -c public $IP | tee snmpcheck.txt
```

```bash
sudo nmap -sU -p161 --script "snmp-*" $IP
```
**High-value OIDs:**
| OID | Data |
|---|---|
| `1.3.6.1.2.1.25.1.6.0` | System processes count |
| `1.3.6.1.2.1.25.4.2.1.2` | Running programs |
| `1.3.6.1.2.1.25.4.2.1.4` | Process paths |
| `1.3.6.1.2.1.25.4.2.1.5` | **Process command-line args (creds!)** |
| `1.3.6.1.2.1.25.6.3.1.2` | Installed software |
| `1.3.6.1.2.1.6.13.1.3` | Listening TCP ports |
| `1.3.6.1.4.1.77.1.2.25` | Windows users |
| `1.3.6.1.4.1.77.1.2.3.1.1` | Windows shares |

```bash
snmpwalk -v2c -c public $IP 1.3.6.1.4.1.77.1.2.25    # Windows users → build users.txt → spray SMB/SSH
```

```bash
snmpwalk -v2c -c public $IP 1.3.6.1.2.1.25.4.2.1.5   # process args (creds!)
```
**Look for:** usernames, process command lines (creds passed as args!), installed software (→ CVEs), open ports, network shares.

---

## 🗡️ EXPLOIT

- 🟢 **Info disclosure via read community** → users, software, creds in process args.
- 🟡 **Creds in command lines** → direct reuse on SSH/SMB.
- 🔵 **RW community (`private`)** on network gear → download/modify config (e.g. Cisco `snmp` config exfil), sometimes credentials/enable secrets.

SNMP itself rarely gives a shell. Its output is the **fuel**:
```
SNMP walk -> username + password in a process arg -> ssh user@IP  ✅
SNMP -> software version -> searchsploit -> exploit that service  ✅
```

## 🔁 FOUND → NEXT
| FINDING | MEANING | NEXT | RESULT |
|---|---|---|---|
| `public` works | RO access | full `snmpwalk` + `snmp-check` | users/procs/software |
| Username list | Targets | spray SMB/SSH | valid creds |
| Password in process args | Cred | reuse on SSH/SMB/web | shell |
| Software+version | CVE target | `searchsploit` | exploit |
| `private` (RW) | Reconfigure | pull/alter device config | secrets/foothold |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Nothing on `public` | Brute community strings (`onesixtyone`); try `private`, vendor defaults |
| Port not seen | You forgot **UDP** — `sudo nmap -sU -p161`; UDP scans are slow/lossy, retry |
| snmpwalk times out | UDP loss — retry, add `-r 1 -t 5`, or use `snmp-check` |
| v3 only | Needs username+auth — usually skip unless you have SNMPv3 creds |

## 📋 REFERENCE — mistakes · don't-miss · stop
**Mistakes:** **never UDP-scanning** (missing SNMP entirely) · stopping at `public` failing (brute the strings) · not grepping the full walk for `pass`/`user` · ignoring **process command-line args** (the credential goldmine).
**Reuse:** users & passwords from SNMP → [[SMB]], [[SSH]], web logins; software versions → [[HTTP]]/service exploits. See [[Credential Attacks]].
**Don't miss:** `sudo nmap -sU -p161` (UDP!) · brute community strings (not just `public`) · full `snmpwalk` + `snmp-check` · grep walk for `pass`/`user`/`cred` · process command-line OID (creds in args) · reuse users/creds on SSH/SMB.
**Stop when:** community strings brute-forced, full walk grepped, users/creds extracted and reused. Nothing found → move on. Keep any userlist for reuse.

## 📇 CHEAT SHEET
```bash
sudo nmap -sU -p161 -sV $IP
```

```bash
onesixtyone -c /usr/share/seclists/Discovery/SNMP/common-snmp-community-strings.txt $IP
```

```bash
snmpwalk -v2c -c public $IP > walk.txt
```

```bash
snmp-check -c public $IP
```

```bash
snmpwalk -v2c -c public $IP 1.3.6.1.2.1.25.4.2.1.5   # process args (creds!)
```

```bash
grep -iE 'pass|user|cred' walk.txt
```
**Kill shots:** password in process args → SSH/SMB · userlist → spray · software version → CVE.
