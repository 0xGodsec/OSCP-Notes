# 📇 Port → Action Cheat Sheet

> Scan-only. See a port → do this first. One line each; open the linked note for depth. Full lookup in [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]].

| Port | See it → do first | Note |
|---|---|---|
| 21 FTP | anon login `ftp $IP` (anonymous/anonymous); pull + grep files; version→searchsploit | [[FTP]] |
| 22 SSH | try found keys/creds; note version; it's where loot cashes out | [[SSH]] |
| 23 Telnet | banner → device; default/reused creds = instant shell | [[Telnet]] |
| 25 SMTP | `VRFY`/`RCPT` user enum; version→CVE | [[SMTP]] |
| 53 DNS | zone transfer `dig axfr @$IP domain`; subdomains | [[DNS]] |
| 79 Finger | enumerate usernames | [[Finger]] |
| 80/443 HTTP(S) | whatweb/nuclei; dir+vhost brute; read cert (443); every input | [[HTTP]] / [[HTTPS]] |
| 88 Kerberos | it's a DC; sync clock; AS-REP/Kerberoast | [[Kerberos]] |
| 110/143 POP3/IMAP | reused creds → read mail for secrets | [[POP3 IMAP]] |
| 111/2049 NFS | `showmount -e`; mount + loot; `no_root_squash` | [[NFS]] |
| 135 MSRPC | `rpcclient -U "" -N`; enumdomusers; RID-brute | [[RPC]] |
| 139/445 SMB | MS17-010; null/guest shares; `netexec` creds | [[SMB]] |
| 161/UDP SNMP | `snmpwalk -v2c -c public`; creds/processes/routes | [[SNMP]] |
| 389/636 LDAP | anon bind dump; descriptions=creds; roast targets | [[LDAP]] |
| 512-514 R-svc | `rlogin -l root $IP` (trust) | [[R-services]] |
| 1433 MSSQL | weak `sa`; `xp_cmdshell`; `xp_dirtree`→Responder | [[MSSQL]] |
| 1521 Oracle | SID guess → default creds → `odat` | [[Oracle TNS]] |
| 3306 MySQL | reused creds; `LOAD_FILE`/`INTO OUTFILE` | [[MySQL]] |
| 3389 RDP | creds → `xfreerdp`; grab GUI/loot | [[RDP]] |
| 5432 Postgres | `trust`/weak creds; `COPY FROM PROGRAM` | [[PostgreSQL]] |
| 5900 VNC | no-auth / weak pw; decrypt `.vnc/passwd` | [[VNC]] |
| 5985/5986 WinRM | cred/hash → `evil-winrm` shell | [[WinRM]] |
| 6379 Redis | unauth → SSH key / webshell write | [[Redis]] |
| 27017 MongoDB | unauth `mongosh` → dump creds | [[MongoDB]] |

**Universal:** version→`searchsploit`; anonymous/default creds; reuse every cred everywhere ([[Credential Attacks]]).
