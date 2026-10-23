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
# FASTER full walk — bulk requests, far less UDP loss/timeout on big trees (prefer this for the full dump)
snmpbulkwalk -v2c -c public -Cr1000 $IP .1 > snmp_full.txt
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

## 🔎 IDENTIFY AN UNKNOWN OID (don't guess — translate it)

An OID is a path down the global naming tree. Decode `1.3.6.1.4.1.77.1.2.25`:
```
1.3.6.1       -> iso.org.dod.internet
      .4.1    -> private.enterprises
      .77     -> enterprise 77 = Microsoft / LAN Manager
      .1.2.25 -> userTable.userName   (= Windows/LANMgr user accounts)
```
Install MIBs so tools print NAMES instead of raw numbers (disabled by default on kali):
```bash
sudo apt install snmp snmp-mibs-downloader && sudo download-mibs
sudo sed -i 's/^mibs :/# mibs :/' /etc/snmp/snmp.conf
```

```bash
snmpwalk -v2c -c public -m ALL $IP          # walk the tree WITH human-readable names
```

```bash
snmptranslate 1.3.6.1.4.1.77.1.2.25          # number -> name
snmptranslate -On SNMPv2-MIB::sysDescr.0     # name   -> number
snmptranslate -Td 1.3.6.1.4.1.77.1.2.25      # full description of the node
```

```bash
snmpwalk -v2c -c public $IP .1               # walk from ROOT to discover every enumerable branch
```
**Workflow:** run `snmp-check` first (it labels everything for you). Only drop to raw OIDs + `snmptranslate` when you want to chase a specific branch `snmp-check` didn't show.

---

## 📑 ALL IMPORTANT OIDs (full reference)

> ⭐ = top priority on the exam. All queryable with `snmpwalk -v2c -c public $IP <OID>`.

**System info — MIB-2 `1.3.6.1.2.1.1`**
| OID | Data |
|---|---|
| `1.3.6.1.2.1.1.1.0` | ⭐ `sysDescr` — OS + kernel/version banner |
| `1.3.6.1.2.1.1.2.0` | `sysObjectID` — vendor/device type |
| `1.3.6.1.2.1.1.3.0` | `sysUpTime` |
| `1.3.6.1.2.1.1.4.0` | `sysContact` — admin email/name (user hints) |
| `1.3.6.1.2.1.1.5.0` | ⭐ `sysName` — hostname |
| `1.3.6.1.2.1.1.6.0` | `sysLocation` |

**Host Resources — `1.3.6.1.2.1.25` (users/procs/software/disk)**
| OID | Data |
|---|---|
| `1.3.6.1.2.1.25.1.5.0` | `hrSystemNumUsers` — logged-in user count |
| `1.3.6.1.2.1.25.1.6.0` | `hrSystemProcesses` — process count |
| `1.3.6.1.2.1.25.2.3.1.3` | `hrStorageDescr` — disks / mounts |
| `1.3.6.1.2.1.25.4.2.1.2` | ⭐ `hrSWRunName` — running programs |
| `1.3.6.1.2.1.25.4.2.1.4` | `hrSWRunPath` — process executable path |
| `1.3.6.1.2.1.25.4.2.1.5` | ⭐⭐ `hrSWRunParameters` — **process command-line ARGS (creds leak here)** |
| `1.3.6.1.2.1.25.6.3.1.2` | ⭐ `hrSWInstalledName` — installed software → CVEs |

**Network — MIB-2 `1.3.6.1.2.1`**
| OID | Data |
|---|---|
| `1.3.6.1.2.1.2.2.1.2` | `ifDescr` — network interfaces |
| `1.3.6.1.2.1.4.20.1.1` | `ipAdEntAddr` — host IP addresses |
| `1.3.6.1.2.1.4.21.1.1` | `ipRouteDest` — routing table (pivot targets) |
| `1.3.6.1.2.1.4.22.1.2` | `ipNetToMedia` — ARP table / MACs (other live hosts) |
| `1.3.6.1.2.1.6.13.1.3` | ⭐ `tcpConnLocalPort` — listening TCP ports |
| `1.3.6.1.2.1.7.5.1.2` | `udpLocalPort` — listening UDP ports |

**Windows / LAN Manager — enterprise `1.3.6.1.4.1.77`**
| OID | Data |
|---|---|
| `1.3.6.1.4.1.77.1.2.25` | ⭐ user accounts (`userName`) → build users.txt |
| `1.3.6.1.4.1.77.1.2.3.1.1` | network shares |
| `1.3.6.1.4.1.77.1.2.27` | logged-in / session users |

**Net-SNMP extend/exec — enterprise `1.3.6.1.4.1.2021` & `.8072` (Linux goldmine)**
| OID | Data |
|---|---|
| `1.3.6.1.4.1.2021.8.1.101` | ⭐ `extOutput` — output of admin-configured `exec` scripts (can leak creds / command output) |
| `1.3.6.1.4.1.8072.1.3.2.3.1.2` | ⭐ `nsExtendOutputFull` — output of `extend` directives (NET-SNMP-EXTEND-MIB) |
| `1.3.6.1.4.1.2021.4` | memory stats (`memory` directive) |
| `1.3.6.1.4.1.2021.9` | disk usage (`disk` directive) |

> If `sysDescr` shows a net-snmp daemon, ALWAYS walk `1.3.6.1.4.1.2021` and `1.3.6.1.4.1.8072` — admins wire scripts to `exec`/`extend` and their raw output (sometimes with passwords, API keys, or full command results) is readable through SNMP.

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
| snmpwalk times out | UDP loss — use `snmpbulkwalk` (bulk requests, fewer round-trips), add `-r 1 -t 5`, or use `snmp-check` |
| Only part of the tree returns | `snmpwalk` stopped early — re-run with `snmpbulkwalk ... .1`; try `-v1` if `-v2c` misbehaves |
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
snmpbulkwalk -v2c -c public -Cr1000 $IP .1 > walk.txt   # faster full dump, less UDP loss
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
