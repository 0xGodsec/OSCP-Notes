# 📇 Nmap Cheat Sheet

> Scan-only. Full detail in [[Port Scanning]] / [[Recon Methodology]].

```bash
export IP=10.10.10.10 ; mkdir -p nmap
```
Full TCP:
```bash
sudo nmap -p- --min-rate 5000 -T4 $IP -oN nmap/allports.txt
```
Open-port list for stage 2:
```bash
grep -oE '^[0-9]+/tcp' nmap/allports.txt | cut -d/ -f1 | paste -sd,
```
Targeted service + scripts:
```bash
sudo nmap -sC -sV -p<list> $IP -oN nmap/services.txt
```
UDP top ports:
```bash
sudo nmap -sU --top-ports 100 $IP -oN nmap/udp.txt
```
Vuln scripts:
```bash
sudo nmap -p<ports> --script vuln $IP -oN nmap/vuln.txt
```
SMB MS17-010 check:
```bash
sudo nmap -p445 --script "smb-vuln-*" $IP
```

## Flags
`-p-` all ports · `-Pn` skip ping · `-sC` default scripts · `-sV` versions · `-sU` UDP · `--min-rate N` speed · `-oN/-oA` output · `--version-intensity 9` harder ID.

## Rules
- Always `-p-`. Always UDP. `-Pn` if "host down".
- Route each open port → its `02 - Services` note.
- Re-scan after any new hostname/foothold.
