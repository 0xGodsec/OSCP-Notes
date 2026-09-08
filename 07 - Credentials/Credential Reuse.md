# 🔑 Credential Reuse — The Matrix

> The single highest-value habit on OSCP: **every credential (or hash) you find gets tested on every service, on every host.** More boxes fall to a reused password than to any exploit. This is the mantra.

Part of [[Credential Attacks]]. Related: [[Pass-the-Hash]] · [[Finding Credentials]] · [[Password Spraying]]

---

## 🧠 THINK
- A cred from box A frequently unlocks box B in the same range/domain.
- A cred for one service (DB, web, mail) is frequently reused for **SSH / SMB / WinRM**.
- Keep a **running `creds.txt` / `users.txt`**; re-run the matrix on every new find.
- Have a hash, not a password? → [[Pass-the-Hash]].

## 💥 THE MATRIX (test any `user:pass` across open ports)
```bash
netexec smb   $IP -u user -p pass        # 445
```
```bash
netexec winrm $IP -u user -p pass        # 5985 -> evil-winrm if Pwn3d
```
```bash
netexec ldap  $IP -u user -p pass        # 389
```
```bash
netexec mssql $IP -u user -p pass        # 1433
```
```bash
netexec ssh   $IP -u user -p pass        # 22
```
```bash
mysql -u user -p'pass' -h $IP            # 3306
```
```bash
psql "postgresql://user:pass@$IP"        # 5432
```
```bash
xfreerdp /u:user /p:pass /v:$IP          # 3389
```
...plus **every web login** on the box.

## 💥 ACROSS HOSTS
```bash
netexec smb 10.10.10.0/24 -u user -p pass --continue-on-success
```
```bash
netexec smb 10.10.10.0/24 -u user -H <NThash>
```

## 🔁 FOUND → NEXT
| WHERE IT WORKS | NEXT |
|---|---|
| SMB `(Pwn3d!)` | psexec → SYSTEM → dump → new creds |
| WinRM | evil-winrm shell |
| SSH | shell → [[Linux Privilege Escalation]] |
| DB | dump → more creds; file/RCE primitives |
| Another host | lateral ([[AD Lateral Movement]]) |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Works nowhere yet | keep it — the target host/service may not be found yet; re-scan |
| Rejected on all | format/local-vs-domain/skew → [[Credentials Rejected]] |
| Only partial access | reuse on the rest of the subnet; combine with privesc |

## ⚠️ COMMON MISTAKES
- Cracking a hash then **not reusing** the plaintext everywhere.
- Testing on **one host** only, not the subnet.
- Forgetting **pass-the-hash** — you don't always need plaintext.
- Not keeping a running creds/users list.

## 📇 CHEAT SHEET
```bash
for p in smb winrm ldap mssql ssh; do netexec $p $IP -u user -p pass; done
```
```bash
netexec smb 10.10.10.0/24 -u user -p pass --continue-on-success
```
**Mantra:** find it → (crack/PtH it) → **reuse it on every service and every host**.
