# 🧯 Troubleshooting Methodology

> The meta-note for the dead-air moments. When something "should work but doesn't," or you're stuck on a box, run this instead of spiralling. Detailed per-symptom playbooks live in [[00 - START HERE (OSCP Playbook Index)|09 - Troubleshooting]]; this is the mindset + triage.

Related: [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]] · [[Enumeration Methodology]] · [[Exploitation Methodology]] · [[Shells]]

---

## 🧠 STUCK → THINK
- **90% of "stuck" is missed enumeration.** Re-read *your own notes* first.
- **Time-box:** ~20–30 min of true dead-air → switch targets, come back later.
- **Change one variable at a time** — port, payload, encoding — so you know what fixed it.
- **Every credential → test on every service.** The unlock is often a cred you already have.

## 🔁 THE STUCK LOOP
```
1. Re-read your notes for THIS box — what did you skip? (UDP? a port? a vhost? default creds?)
2. Re-run recon — full TCP (-p-), UDP, -Pn; new hostname? -> /etc/hosts -> re-enum
3. Test cred reuse — every user/pass/hash/key on every service
4. Check the service's FAILED -> NEXT table
5. Still stuck after 20-30 min -> move to another target; return with fresh info
```

## 🩺 FAST SYMPTOM TRIAGE
| Symptom | First checks | Deep note |
|---|---|---|
| No open ports | `-Pn`, full `-p-`, UDP, VPN/routing | [[No Open Ports]] |
| Reverse shell won't connect | listener up? right `tun0` IP? egress port (443/53)? OS/payload match? | [[Reverse Shell Not Connecting]] |
| Exploit fails | exact version/arch/OS; edit LHOST/URL/offsets; another PoC | [[Exploit Fails]] |
| Creds rejected | format (`DOMAIN\user`/`user@domain`), clock skew (Kerberos), lockout, wrong service | [[Credentials Rejected]] |
| Shell unstable | TTY upgrade, `stty`, rlwrap, better transport | [[Shell Is Unstable]] |
| Tool errors | Kali package/version quirks, missing client, Python/impacket | [[Tool Not Working]] |
| Totally stuck | the meta checklist | [[Stuck — What Now]] |

## 🌐 CONNECTIVITY QUICK CHECKS
Confirm your VPN IP (use it as LHOST everywhere):
```bash
ip a show tun0
```
Can you even reach the target?
```bash
ping -c 2 $IP
```
```bash
sudo nmap -Pn -p<known-open-port> $IP
```
Is your listener actually up?
```bash
ss -tlnp | grep 443
```

## 🧭 MINDSET RULES
- **Don't marry a box.** Rotating keeps you finding points; tunnelling loses hours.
- **Fatigue is a bug.** Take the scheduled break; solutions appear after a walk.
- **Read the error.** Most tool failures state the cause (auth format, skew, missing dep).
- **Assume you missed enumeration** before assuming the box is broken.
- **The answer is usually a cred you already have** — reuse relentlessly ([[Credential Attacks]]).

## ⚠️ COMMON MISTAKES
- Re-running the **same failing command** hoping for a different result.
- Forgetting `-Pn` / UDP / full port range.
- Using the **wrong LHOST** (not `tun0`) for reverse shells.
- Ignoring **clock skew** on Kerberos/AD.
- Not trying the **anonymous/default** path you skipped.

## ✅ WHEN NOTHING WORKS — CHECKLIST
- [ ] Re-read all notes for this box (skipped port/vhost/UDP/default creds?)
- [ ] Full re-recon (`-p-`, UDP, `-Pn`)
- [ ] New hostname → `/etc/hosts` → re-enumerate
- [ ] Cred reuse across **every** service/host
- [ ] Correct `tun0` LHOST + listener up + open egress port
- [ ] Read the actual error message
- [ ] Time-boxed out? → switch targets, return later
