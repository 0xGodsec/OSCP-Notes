# 🪟 COM, File Association & Protocol Hijacks

> Per-user registry configuration can sometimes override an application handler that an elevated process later invokes. The key question is always the same: does a higher-integrity process honor a user-writable handler?

Part of [[Windows Privilege Escalation]]. Related: [[Registry Permissions & UAC]] · [[Application Control & UAC]]

---

## 🧠 THINK
- Many per-user handler changes affect only the current user and are persistence, not privilege escalation.
- A candidate becomes an elevation route only when an elevated consumer reads the user-controlled registration and has a reliable, authorized trigger.
- COM registrations, URL protocols, and file associations are version- and application-dependent; validate behavior rather than relying on a name alone.

## ⚡ DETECT
Inspect per-user class/protocol registrations and compare them with machine-wide registrations:
```cmd
reg query HKCU\Software\Classes /s
```
```cmd
reg query HKLM\Software\Classes /s
```
Inspect a particular file extension or protocol handler:
```cmd
assoc .<extension>
```
```cmd
ftype <filetype>
```
Use Procmon in the authorized lab to confirm which registry key and executable an elevated application actually accesses.

## ✅ VALIDATE
| Requirement | Evidence |
|---|---|
| Handler is user-writable | key is under HKCU or ACL grants write rights |
| Higher-integrity consumer exists | documented task/application runs elevated |
| Consumer honors the override | Procmon shows it reads the user-controlled value |
| Trigger is predictable | normal application action or authorized test trigger |

## 🔁 FOUND → NEXT
| Finding | Next |
|---|---|
| Only a non-elevated consumer uses it | user-context persistence only; not privesc |
| Elevated consumer uses a user-controlled handler | document the chain and test its behavior only in the authorized lab |
| Machine-wide execution setting is writable | [[Registry Permissions & UAC]] |
| DLL path/plugin setting is writable | [[DLL Search Order & PATH Hijacking]] |

## 📇 CHEAT SHEET
```cmd
reg query HKCU\Software\Classes /s
```
```cmd
assoc .<extension> & ftype <filetype>
```
**Kill shot:** elevated consumer + observed user-controlled handler + repeatable trigger.
