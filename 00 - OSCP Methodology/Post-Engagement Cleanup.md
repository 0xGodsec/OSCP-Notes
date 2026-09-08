# 🧹 Post-Engagement Cleanup

> Leave the target as close to how you found it as possible. On OSCP this is good hygiene (the reset button handles the rest); on a **real engagement** it's part of scope — track everything you drop so you can remove it and document it in the report.

Part of [[_MOC (Methodology)]]. Related: [[Exam Workflow]] · [[File Transfer]] · [[Linux Privilege Escalation]] · [[Windows Privilege Escalation]]

---

## 🧠 THINK
- The only reliable cleanup is a **drop-log you build while attacking** — you can't remember at 2am what you dropped at noon.
- **Never** tamper with client logs on a real engagement unless the RoE says so — that destroys their evidence and breaches scope.
- Preserve **your own** evidence (screenshots, command logs, loot hashes) for the report **before** wiping local copies.
- OSCP: you don't scrub anything — just revert/note the box. The skill this teaches is **tracking every change you make**.

## 📝 KEEP A DROP-LOG AS YOU GO
For every action note: **host · path/change · time**.
```
10.10.10.10  /tmp/linpeas.sh            uploaded 14:02
10.10.10.10  /dev/shm/shell.elf         uploaded 14:05  (chmod +x, run)
10.10.10.10  /etc/crontab               added line 14:11  <- REVERT
10.10.10.10  user 'svc-backup'          created 14:20     <- DELETE
```

## 🧽 REMOVE WHAT YOU DROPPED — Linux
```bash
rm -f /tmp/linpeas.sh /tmp/lp.out /dev/shm/shell.elf /tmp/nc
```

```bash
shred -u /tmp/sensitive.loot            # if it held creds/PII
```
Revert config you changed (restore the backup you took **before** editing):
```bash
cp /etc/crontab.bak /etc/crontab
```

```bash
userdel -r svc-backup 2>/dev/null                       # planted account
```

```bash
sed -i '/YOUR_PUBKEY_COMMENT/d' /root/.ssh/authorized_keys   # planted SSH key
```

## 🧽 REMOVE WHAT YOU DROPPED — Windows
```powershell
Remove-Item C:\Windows\Temp\winPEASx64.exe,C:\Windows\Temp\shell.exe -Force
net user svc-backup /delete                             # planted account
sc.exe delete EvilSvc ; schtasks /delete /tn EvilTask /f  # persistence
```

## 🔁 PERSISTENCE & PRIVILEGE ARTIFACTS TO REVERSE
- **Accounts / group membership** you added (esp. local admin / sudoers).
- **SSH keys** appended to `authorized_keys`.
- **Scheduled tasks / cron / services** created for persistence or SUID-cron privesc.
- **Web shells** uploaded to web roots.
- **Registry run-keys / startup items** (Windows).
- **File permission / ownership** changes (`chmod`/`chown`, ACLs).
- **Firewall rules** you opened.

## ✅ RESTORE & REPORT
```bash
# confirm nothing of yours remains (files created this session):
find / -newermt '2026-09-06 14:00' -type f 2>/dev/null
```
- Put back the original of anything you modified (from your pre-edit backups).
- Note anything you **could not** cleanly remove — hand it to the client so they can.
- Save exploit sources, creds/hashes, and proof screenshots for the report first.

## ✅ CLEANUP CHECKLIST
- [ ] Drop-log reviewed — every entry handled
- [ ] Uploaded tools / payloads / output removed
- [ ] Config changes reverted from backup
- [ ] Planted accounts / SSH keys / web shells / tasks removed
- [ ] `netsh portproxy` / tunnel rules deleted ([[Pivoting and Port Forwarding]])
- [ ] Own evidence saved before wiping
- [ ] Anything un-removable documented for the client
