# 🔑 07 — Credentials (Map of Content)

> The connective tissue of every box: **find it → crack/pass it → reuse it everywhere.** Start at the hub for the golden rule and router.

Back to [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]]. Working hub: [[Credential Attacks]].

## Notes in this folder
- [x] [[Credential Attacks]] — **hub / index** (golden rule, router, quick order)
- [x] [[Finding Credentials]] — where creds hide + username enumeration
- [x] [[Password Spraying]] — spray (1 pw → many users) + brute force
- [x] [[Hash Cracking]] — hashcat/john + the `-m` mode table
- [x] [[Pass-the-Hash]] — NTLM auth without the plaintext
- [x] [[Credential Reuse]] — the reuse matrix (every service, every host)

## Order
find ([[Finding Credentials]]) → crack ([[Hash Cracking]]) or pass ([[Pass-the-Hash]]) → spray ([[Password Spraying]]) → **reuse on every service & host** ([[Credential Reuse]]).
Condensed commands: [[Credential Attacks Cheat Sheet]].

## Credential loop
1. Record the exact artifact and source: username, plaintext password, hash, key, ticket, or config.
2. Classify it. Plaintext → [[Credential Reuse]]; NT hash → [[Pass-the-Hash]]; crackable hash/key → [[Hash Cracking]]; username-only → [[Finding Credentials]] / [[Password Spraying]].
3. Test valid credentials against every enumerated service and host within the authorized scope.
4. Each new login, share, or shell restarts enumeration and the relevant privesc workflow.
