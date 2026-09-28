# System Notes: Legion 5 (Arch)

What's customised at the system level on this laptop, and why.

- **Custom files** (written from scratch) are copied into `files/` by `sync.sh`, with their original paths kept. Restore them with `sudo cp`, **one file at a time**.
- **Stock files with small edits** (mkinitcpio, cmdline, pacman.conf) are **not** copied. The edits are described below. On a fresh install, apply them to the new stock file.
- Rollback procedures are in `btrfs-rollback.md`.

Lines marked **TODO** still need filling in from the running system.

---

## Contents of `files/`

| File | Purpose |
|---|---|
| `etc/modprobe.d/nvidia-power.conf` | NVIDIA options that make hibernation work |
| `etc/systemd/logind.conf.d/10-hibernate.conf` | Lid-close behaviour (hibernate instead of the broken suspend) |
| `etc/systemd/zram-generator.conf` | 4G zram swap |
| `etc/snapper/configs/root`, `home` | Tuned snapshot limits |
| `etc/pacman.d/hooks/04-boot-backup-pre.hook` | Copies `/boot` into `/.bootbackup` before the snap-pac pre snapshot |
| `etc/pacman.d/hooks/95-boot-backup-post.hook` | Copies `/boot` again after the UKI rebuild, before the post snapshot |
| `etc/pacman.d/hooks/LenovoLegionLinux.hook` | Hook for LenovoLegionLinux (see below) |
| `usr/local/bin/disable-bd-prochot.sh` | Clears BD PROCHOT (CPU stuck at 800 MHz) |
| `etc/systemd/system/disable-bd-prochot.service` | Runs the script early at boot |
| `usr/lib/systemd/system-sleep/disable-bd-prochot` | Re-runs the script after every resume |

To update this folder after changing any of these files:
```bash
~/.config/system/sync.sh
dot add ~/.config/system && dot commit -m "system: <what changed>" && dot push
```

---

## Hardware quick facts

- **Lenovo Legion 5 15IMH05H**: the Intel iGPU drives the display, and the **RTX 2060** runs games through `prime-run`.
- Disks: ESP `nvme0n1p1` (FAT, `/boot`), swap `nvme0n1p2` (18G), btrfs root `nvme0n1p3`
- **Suspend is broken** (NVIDIA + USB-C issues), so the laptop uses **hibernate** instead.
- **One USB port is physically dead.** The kernel logs `usb1-port6: unable to enumerate`. This is hardware, so ignore it.

---

## Boot: UKI via mkinitcpio

The system boots a **Unified Kernel Image** at `/boot/EFI/Linux/arch-linux.efi`, built by mkinitcpio.

### `/etc/mkinitcpio.d/linux.preset` (edited)
Enable the UKI line and disable the plain image:
```bash
default_uki="/boot/EFI/Linux/arch-linux.efi"
#default_image=...
```
TODO: confirm whether a fallback UKI is also built.

### `/etc/kernel/cmdline` (created, install-specific)
```
root=PARTUUID=<root-partuuid> zswap.enabled=0 rootflags=subvol=@ rw rootfstype=btrfs resume=UUID=<swap-uuid>
```
- **`rootflags=subvol=@`** must be **by name**, never `subvolid=`. Snapshot rollbacks create a new `@` with a different ID.
- **`zswap.enabled=0`**: zram is used instead, and zswap on top of it is pointless.
- **`resume=UUID=`** is the **swap partition's** UUID, from `lsblk -f`.
- UUIDs change on a reinstall, so rewrite this file rather than copying it.
- Rebuild after editing: `sudo mkinitcpio -P`

### `/etc/mkinitcpio.conf` (edited)
- **`HOOKS`** uses the **`systemd`** hook, which handles hibernation resume by itself, so there's no separate `resume` hook.
- **`MODULES` must NOT contain the nvidia modules.** Early-loading them made the hibernation resume freeze fail with error `-5`.
- TODO: paste the final `HOOKS=(...)` line.

---

## Hibernation with NVIDIA

It only works when all three of these are in place:

1. The nvidia modules are **not** in mkinitcpio `MODULES`.
2. `/etc/modprobe.d/nvidia-power.conf` exists (in `files/`):
   ```
   options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp
   ```
3. The NVIDIA power services are enabled:
   ```bash
   sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
   ```

Related behaviour:
- **Idle** is handled by **Noctalia**: lock, then screen off, then a custom `systemctl hibernate`. No swayidle.
- **Lid close** is set by `logind.conf.d/10-hibernate.conf`. Goal: lid close should **not** hibernate while on external power.
- Test with `systemctl hibernate` after any NVIDIA or kernel change.

---

## Swap

| | Size | Priority | Role |
|---|---|---|---|
| zram (`zram-generator.conf`) | 4G | 100 | Used first, compressed in RAM |
| `nvme0n1p2` | 18G | -1 | Hibernation image, plus overflow |

---

## BD PROCHOT fix (CPU stuck at 800 MHz)

The firmware can assert BD PROCHOT and pin the CPU at 800 MHz, especially after resuming from hibernation. The fix clears **bit 0 of MSR `0x1FC`** on every CPU.

The script, the boot service and the post-resume sleep hook are all in `files/`. To restore:
```bash
sudo pacman -S msr-tools     # TODO: confirm the script uses wrmsr/rdmsr from msr-tools
sudo cp files/usr/local/bin/disable-bd-prochot.sh /usr/local/bin/
sudo cp files/etc/systemd/system/disable-bd-prochot.service /etc/systemd/system/
sudo cp files/usr/lib/systemd/system-sleep/disable-bd-prochot /usr/lib/systemd/system-sleep/
sudo chmod +x /usr/local/bin/disable-bd-prochot.sh /usr/lib/systemd/system-sleep/disable-bd-prochot
sudo systemctl enable disable-bd-prochot.service
```

---

## LenovoLegionLinux

Driver and tools for Legion features (power modes, fan control and more). There's a pacman hook for it in `files/etc/pacman.d/hooks/`.

TODO:
- how it was installed (AUR package name, e.g. `lenovolegionlinux-dkms` / `lenovolegionlinux`)
- what the hook does (e.g. rebuilds or reloads the module on kernel updates)
- any settings in use (power mode, fan curve)

---

## Snapshots

Everything is covered in `btrfs-rollback.md`. Setup on a fresh install:

1. `sudo pacman -S snapper snap-pac rsync`
2. `sudo snapper -c root create-config /` and `sudo snapper -c home create-config /home` (archinstall may have done this already)
3. Copy `files/etc/snapper/configs/*` for the tuned limits.
4. Copy the two `boot-backup` hooks from `files/etc/pacman.d/hooks/`.
5. `sudo systemctl enable snapper-timeline.timer snapper-cleanup.timer`
6. Create these as **separate subvolumes** before they fill up, so home snapshots skip them:
   ```bash
   btrfs subvolume create ~/.cache
   btrfs subvolume create ~/.sdkman
   mkdir -p ~/.local/share && btrfs subvolume create ~/.local/share/Steam
   ```

---

## pacman

TODO: list the `/etc/pacman.conf` edits (e.g. `Color`, `ParallelDownloads`, `ILoveCandy`, `IgnorePkg`, `[multilib]` for Steam).

---

## Enabled services

```bash
sudo systemctl enable \
  nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service \
  disable-bd-prochot.service \
  snapper-timeline.timer snapper-cleanup.timer
```
TODO: add the rest from `systemctl list-unit-files --state=enabled`.

---

## Fresh install checklist

1. **Base install** with the btrfs layout: `@`, `@home`, `@log` (`/var/log`), `@pkg` (`/var/cache/pacman/pkg`)
2. **UKI:** edit the preset, write `/etc/kernel/cmdline` with the **new UUIDs**, set `HOOKS`, then `mkinitcpio -P`.
3. **NVIDIA:** drivers, `nvidia-power.conf`, enable the NVIDIA services. **Don't** add nvidia to `MODULES`.
4. **BD PROCHOT:** restore the script, service and sleep hook; enable the service.
5. **Swap:** `zram-generator.conf`, the swap partition, `resume=` in the cmdline, then `mkinitcpio -P`. Test `systemctl hibernate`.
6. **Lid behaviour:** restore `logind.conf.d/10-hibernate.conf`.
7. **LenovoLegionLinux:** install it and restore its hook.
8. **Snapshots:** snapper, snap-pac, the boot-backup hooks, the tuned configs, and the excluded subvolumes.
9. **Dotfiles:**
   ```bash
   git clone --bare git@github.com:<user>/dotfiles.git ~/.dotfiles
   alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
   dot checkout              # if it refuses because files exist, back them up and retry
   dot config status.showUntrackedFiles no
   ```
10. Re-apply `--skip-worktree` on the Noctalia-generated colour files (btop, cava, gtk-3.0, gtk-4.0, niri, qt5ct, qt6ct).
