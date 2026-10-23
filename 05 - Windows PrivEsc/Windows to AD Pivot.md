# 🪟 Windows to Active Directory Pivot

> A domain-joined Windows foothold can lead to domain escalation, but that is not a local Windows privilege-escalation path. Switch methodologies when the evidence points to AD.

Part of [[Windows Privilege Escalation]]. Related: [[Active Directory]] · [[SMB]] · [[Kerberos]]

---

## ⚡ CONFIRM THE PIVOT
```cmd
wmic computersystem get domain,partofdomain
```
```cmd
set USERDOMAIN
```
```cmd
nltest /dsgetdc:<domain>
```

## 🧠 ROUTE THE FINDING
| Evidence | Where to go |
|---|---|
| Domain credential or joined host | [[Active Directory]] → [[AD Enumeration]] |
| Service account / SPN opportunity | [[Kerberoasting]] |
| User without pre-authentication | [[AS-REP Roasting]] |
| Relationship/ACL path from a domain account | [[BloodHound]] → [[AD ACL Abuse]] |
| Remote admin rights or reused local-admin credential | [[AD Lateral Movement]] |
| Domain-replication rights | [[DCSync & Domain Dominance]] |
| SMB signing / relay exposure | [[SMB]]; validate the environment and authorization before any test |

## ⚠️ SCOPE
Delegation, GPO control, AD CS, LDAP/AD ACL abuse, and NTLM relay are domain/network workflows. They require separate authorization and should be documented as such; do not label them “local privesc.”

**Kill shot:** confirm domain context → move to the AD workflow → map an authorized path from the current principal to the target privilege.
