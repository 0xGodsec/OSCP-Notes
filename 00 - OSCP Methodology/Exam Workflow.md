# 🎓 Exam Workflow — OSCP Day

> The end-to-end plan for exam day: point allocation, machine order, time-boxing, note-taking, screenshots, proof files, and reporting. Read this the morning of the exam. The *technical* how lives in the other notes; this is the **discipline** that stops you losing points to chaos.

Related: [[00 - START HERE (OSCP Playbook Index)|📁 START HERE]] · [[Recon Methodology]] · [[Enumeration Methodology]] · [[Exploitation Methodology]] · [[Troubleshooting Methodology]]

---

## 🧠 GROUND RULES (know these cold)
- **Current OSCP+ format (reviewed 2026-09-07):** 23 hours 45 minutes for the exam, then 24 hours to upload the report. The current published structure is three standalone machines (60 points total) plus a three-machine **Active Directory set** (40 points); 70/100 passes. Your control panel is authoritative for your specific attempt.
- **Proofs:** submit every `local.txt`/`proof.txt` in the control panel before the exam ends, and screenshot each flag with the target IP shown via `ipconfig`, `ifconfig`, or `ip addr`. Include `id`/`whoami` too—it is useful evidence even where not explicitly required.
- **Passing:** use the published 70-point paths as planning aids, but follow the objectives and point values in your control panel.
- **Metasploit limit:** you may use MSF/meterpreter on **one** target only (check current rules). Use it wisely; do everything else manually.
- **No AI during the exam or reporting phase:** OffSec's current FAQ prohibits KAI and other chatbots. Prepare and validate this vault before exam day.

## ⏱️ TIME-BOX PLAN (24h)
| Block | Focus |
|---|---|
| 0:00–0:30 | Read all target instructions; start `nmap` on **every** target in parallel; set up notes/screenshots |
| 0:30–?? | Prioritise the **Active Directory set** when it offers the clearest path; it chains, but each standalone can be a faster early win. |
| Rolling | Standalones in parallel with AD waits; rotate on 20–30 min dead-air |
| Every 2–3h | **Break** (eat, walk) — fatigue loses more points than any single box |
| Last ~3h | Stop hacking; verify all proofs + screenshots are captured; fill gaps |
| +24h | Write the report |

> **Rotate, don't rabbit-hole.** ~20–30 min of true dead-air on a service → move to another target, come back later ([[Troubleshooting Methodology]]).

## 🗺️ PER-MACHINE FLOW
```
1. Recon      → full TCP + targeted -sC -sV + top UDP        ([[Recon Methodology]])
2. Enumerate  → open each 02 - Services note, work its tree   ([[Enumeration Methodology]])
3. Foothold   → 03 - Initial Access technique → reverse shell ([[Exploitation Methodology]])
4. Stabilise  → upgrade shell, grab local.txt + screenshot    ([[Shells]])
5. PrivEsc    → 04/05 (+06 if AD) → root/SYSTEM               (linPEAS/winPEAS)
6. Proof      → submit flags + screenshot with target IP
7. Loot       → creds/keys → reuse on every other target      ([[Credential Attacks]])
```

## 📝 NOTE-TAKING & EVIDENCE (do it live)
- One folder per target: `nmap/`, `loot/`, `screenshots/`, `notes.md`.
- **Log every command + output** as you go (a tool like CherryTree/Obsidian/`script`); you can't reconstruct it later.
- **Screenshot the moment you get each flag** — command that reads it + target IP (`ipconfig`, `ifconfig`, or `ip addr`) in one frame; add `id`/`whoami` as strong supporting evidence.
- Save every credential/hash to a running `creds.txt` — the reuse matrix wins boxes.
- Note the exact **exploit source/URL** you used (needed for the report).

## 🧷 AD SET DISCIPLINE
- Treat it as **one connected network**, not three boxes: foothold → creds → lateral → DC.
- Reuse **every** credential across every host ([[Credential Attacks]]).
- Core chain: enumerate ([[LDAP]]/[[RPC]]/[[Kerberos]]) → AS-REP/Kerberoast → crack → lateral ([[SMB]]/[[WinRM]]) → DC → [[Active Directory]].

## ⚠️ COMMON MISTAKES (point-losers)
- **No screenshot** of a flag → zero points even though you owned it.
- Rabbit-holing one box for hours.
- Skipping **UDP** / a high port / a vhost → missing the intended path.
- Not reusing creds across targets (especially the AD set).
- Forgetting the **MSF one-target** limit and wasting it early.
- Poor notes → a painful, incomplete report.

## ✅ EXAM-START CHECKLIST
- [ ] Read every target's instructions
- [ ] `nmap` launched on **all** targets
- [ ] Notes + screenshot workflow ready
- [ ] `export IP=` and per-target folders
- [ ] Start on the highest-confidence path (often the **AD set**)
- [ ] Break timer set

## ✅ BEFORE YOU STOP CHECKLIST
- [ ] `local.txt` + `proof.txt` captured for every owned host
- [ ] Each proof submitted in the **control panel** before time expires
- [ ] Each proof screenshotted with the target IP + `id`/`whoami`
- [ ] Exploit sources noted for the report
- [ ] All creds/hashes saved
- [ ] Point total tallied — do you have a pass?
- [ ] Boxes reverted / changes tracked → [[Post-Engagement Cleanup]]

## 🔄 VALIDATION

Exam-policy statements were reviewed on **2026-09-07** against the [official OSCP+ Exam Guide](https://help.offsec.com/hc/en-us/articles/360040165632-OSCP-Exam-Guide). Re-check it immediately before an exam; OffSec can change rules, objectives, and scoring. Command recipes remain lab-validation items in [[Validation Register]].
