# System Notes: Legion 5 (Arch)

What's customised at the system level on this laptop, and why.

- **Custom files** (written from scratch) are copied into `files/` by `sync.sh`, with their original paths kept. Restore them with `sudo cp`, **one file at a time**.
- **Stock files with small edits** (mkinitcpio, cmdline, pacman.conf, fstab) are **not** copied. The edits are described below. On a fresh install, apply them to the new stock file.
- Related docs: `btrfs-rollback.md` (snapshots and recovery), `hotspot.md` (Wi-Fi hotspot)

Lines marked **TODO** still need filling in from the running system.

---

## Contents of `files/`

| File                                                   | Purpose                                                                     |
| ------------------------------------------------------ | --------------------------------------------------------------------------- |
| `etc/modprobe.d/nvidia-power.conf`                     | NVIDIA options that make hibernation work                                   |
| `etc/systemd/logind.conf.d/10-hibernate.conf`          | Lid-close behaviour (hibernate instead of the broken suspend)               |
| `etc/systemd/zram-generator.conf`                      | 4G zram swap                                                                |
| `etc/snapper/configs/root`, `home`                     | Tuned snapshot limits                                                       |
| `etc/pacman.d/hooks/04-boot-backup-pre.hook`           | Copies `/boot` into `/.bootbackup` before the snap-pac pre snapshot         |
| `etc/pacman.d/hooks/95-boot-backup-post.hook`          | Copies `/boot` again after the UKI rebuild, before the post snapshot        |
| `etc/pacman.d/hooks/LenovoLegionLinux.hook`            | Hook for LenovoLegionLinux (see below)                                      |
| `usr/local/bin/disable-bd-prochot.sh`                  | Clears BD PROCHOT (CPU stuck at 800 MHz)                                    |
| `etc/systemd/system/disable-bd-prochot.service`        | Runs the script early at boot                                               |
| `usr/lib/systemd/system-sleep/disable-bd-prochot`      | Re-runs the script after every resume                                       |
| `etc/greetd/config.toml`                               | Login screen: greetd + tuigreet                                             |
| `etc/systemd/system/create_ap.service.d/override.conf` | Hotspot service: `Restart=no` (the stock unit retries every 5 s on failure) |

### Two directions: don't mix them up

| When                                     | Direction     | Command                                   |
| ---------------------------------------- | ------------- | ----------------------------------------- |
| **Normal use**: you edited a system file | system → repo | `~/.config/system/sync.sh`, then commit   |
| **Fresh install only**                   | repo → system | the `sudo cp` lines in each section below |

```bash
# normal use: after changing any of the files above
~/.config/system/sync.sh
dot add ~/.config/system && dot commit -m "system: <what changed>" && dot push
```

The `sudo cp` commands in this file are **restore instructions for a new install**. On the running laptop the files are already in place, so never run them there. They need `sudo` because `/etc` and `/usr` are owned by root. In the restore commands, `files` means `~/.config/system/files`.

---

## Hardware quick facts

- **Lenovo Legion 5 15IMH05H**: the Intel iGPU drives the display, and the **RTX 2060** runs games through `prime-run`.
- Wi-Fi card: **Intel AX201** (one client plus one AP at once, on the same channel only)
- Disks: ESP `nvme0n1p1` (FAT, `/boot`), swap `nvme0n1p2` (18G), btrfs root `nvme0n1p3`, and an **HDD mounted at `/mnt/hdd`** (Steam library)
- **Suspend is broken** (NVIDIA + USB-C issues), so the laptop uses **hibernate** instead.
- **Dead ports (hardware, ignore them):**
  - one USB-A port; the kernel logs `usb1-port6: unable to enumerate`
  - the **USB-C port**

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

## Login

**greetd** with **tuigreet** as the greeter. The config is in `files/etc/greetd/config.toml`.

```bash
sudo pacman -S greetd greetd-tuigreet
sudo systemctl enable greetd.service
```

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

|                              | Size | Priority | Role                             |
| ---------------------------- | ---- | -------- | -------------------------------- |
| zram (`zram-generator.conf`) | 4G   | 100      | Used first, compressed in RAM    |
| `nvme0n1p2`                  | 18G  | -1       | Hibernation image, plus overflow |

---

## Storage: HDD

- Mounted at **`/mnt/hdd`** through `/etc/fstab`. It holds the **Steam library**, added under Steam → Settings → Storage.
- On a reinstall, add the fstab line again using the HDD's UUID from `lsblk -f`.
- TODO: filesystem type and mount options (`grep hdd /etc/fstab`). It must **not** be NTFS for a Steam library, because Proton breaks on it.

---

## Networking

- **NetworkManager with the default `wpa_supplicant` Wi-Fi backend.** **iwd is uninstalled.** iwd can't run a second (AP) interface on the same card, which the hotspot needs. Don't reinstall iwd, and don't add a `wifi.backend=iwd` drop-in.
- **Wi-Fi profiles are pinned to `wlan0`**, so NetworkManager never puts the laptop's own connection on the hotspot interface `ap0`:
  ```bash
  nmcli con mod "<profile>" connection.interface-name wlan0
  ```
  Current profiles: `5 GHz_extend`, `2.4 GHz`. The profiles themselves hold Wi-Fi passwords and are **not** synced.
- **Hotspot:** `linux-wifi-hotspot` (`create_ap`). Full setup, modes and troubleshooting are in **`hotspot.md`**. On a reinstall:
  ```bash
  sudo pacman -S linux-wifi-hotspot hostapd dnsmasq iw qrencode   # TODO: confirm repo vs AUR
  sudo cp -r ~/.config/system/files/etc/systemd/system/create_ap.service.d /etc/systemd/system/
  sudo systemctl daemon-reload
  sudoedit /etc/create_ap.conf      # recreate from hotspot.md; set a NEW passphrase here
  sudo chown root:solidv /etc/create_ap.conf && sudo chmod 640 /etc/create_ap.conf
  ```
  `create_ap.service` stays **disabled**, and is started by hand when needed. The override sets `Restart=no`, so a failed start (e.g. 5 GHz on country `00`) stops instead of retrying every 5 seconds.

---

## BD PROCHOT fix (CPU stuck at 800 MHz)

The firmware can assert BD PROCHOT and pin the CPU at 800 MHz, especially after resuming from hibernation. The fix clears **bit 0 of MSR `0x1FC`** on every CPU.

The script, the boot service and the post-resume sleep hook are all in `files/`. To restore:

```bash
sudo pacman -S msr-tools     # TODO: confirm the script uses wrmsr/rdmsr from msr-tools
sudo cp ~/.config/system/files/usr/local/bin/disable-bd-prochot.sh /usr/local/bin/
sudo cp ~/.config/system/files/etc/systemd/system/disable-bd-prochot.service /etc/systemd/system/
sudo cp ~/.config/system/files/usr/lib/systemd/system-sleep/disable-bd-prochot /usr/lib/systemd/system-sleep/
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
   The games themselves live on the HDD, but the Steam client folder still churns, so keep it as a subvolume.

---

## pacman

TODO: list the `/etc/pacman.conf` edits (e.g. `Color`, `ParallelDownloads`, `ILoveCandy`, `IgnorePkg`, `[multilib]` for Steam).

---

## Enabled services

```bash
sudo systemctl enable \
  greetd.service \
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
7. **Login:** greetd + tuigreet, restore `config.toml`, enable `greetd.service`.
8. **HDD:** add the `/mnt/hdd` line to fstab, then re-add the library in Steam.
9. **Networking:** NetworkManager without iwd, pin the Wi-Fi profiles to `wlan0`, set up the hotspot from `hotspot.md`.
10. **LenovoLegionLinux:** install it and restore its hook.
11. **Snapshots:** snapper, snap-pac, the boot-backup hooks, the tuned configs, and the excluded subvolumes.
12. **Dotfiles:**
    ```bash
    git clone --bare git@github.com:<user>/dotfiles.git ~/.dotfiles
    alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
    dot checkout              # if it refuses because files exist, back them up and retry
    dot config status.showUntrackedFiles no
    ```
    Noctalia's colour files (niri, GTK, Qt, btop, cava) aren't tracked. Noctalia regenerates them on first run.
13. **Before starting niri for the first time**, run:
    ```bash
    touch ~/.config/niri/noctalia.kdl
    ```
    niri's `config.kdl` has `include "noctalia.kdl"`, and niri **refuses to load the whole config** if that file is missing (tested). Without it, niri falls back to defaults, Noctalia never starts, and the file never gets generated. An empty file is enough; Noctalia fills it in on first run.
