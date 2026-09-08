# 🧯 Tool Not Working

> A Kali tool errors, isn't installed, or behaves oddly. Usually a **missing package**, a **Python/impacket version** quirk, or a **wrong invocation**. Quick fixes.

Related: [[Troubleshooting Methodology]] · [[Credential Attacks]]

---

## First moves
Is it installed / what's the path?
```bash
which <tool> || apt-cache search <tool>
```
Install it:
```bash
sudo apt update && sudo apt install <package> -y
```
Read the actual error — it usually names the cause (missing dep, auth format, syntax).

## Common culprits
| Tool / symptom | Fix |
|---|---|
| `rlogin`/`rsh`/`rexec` not found | `sudo apt install rsh-client` |
| `mongosh` missing | use legacy `mongo`, or `nmap --script mongodb-*`, or `mongodump` |
| `sqlplus`/Oracle | `odat` is self-contained; else install Oracle Instant Client |
| `netexec` vs old `crackmapexec` | use `netexec` (aka `nxc`); same syntax |
| impacket script name | prefix `impacket-` (e.g. `impacket-secretsdump`) or `GetNPUsers.py` |
| Python2-only PoC | run with `python2`; install `python2` if needed |
| `pip` module missing | `pip install <module>` (or `pipx`, venv) |
| hashcat "no devices" | add `--force`; use CPU if no GPU |
| `responder` no hashes | check `-I tun0`, firewall to your 445/80, correct LHOST |
| SSL/cert errors (ldap/curl) | `LDAPTLS_REQCERT=never`, `curl -k` |

## impacket quick sanity
```bash
impacket-secretsdump -h            # confirms it runs; shows usage
```
If a `.py` name is expected by a guide, the Kali wrapper is usually `impacket-<name>`.

## When it's not the tool
- **Auth-format** rejections look like tool bugs but aren't → [[Credentials Rejected]].
- **Clock skew** breaks Kerberos tools → `sudo ntpdate $IP`.
- **Egress/firewall** breaks callbacks (responder/reverse shells), not the tool itself.

## Rules
- Read the error message first — it's usually explicit.
- Prefer the tool the box actually needs over forcing a familiar one.
- Keep a fallback per task (e.g., manual `nc`/`openssl` when a fancy tool won't cooperate).
