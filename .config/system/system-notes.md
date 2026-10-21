# Legion 5 — Arch Linux system config

System-level setup for my **Lenovo Legion 5 15IMH05H** (i7, RTX 2060, 16 GB) running Arch with niri + Noctalia.

This folder holds the system files I've customised (things outside `$HOME`), plus notes on why they exist.

## Highlights

- **Boot:** GRUB → Unified Kernel Image (UKI) built by mkinitcpio. nouveau kept out of the initramfs so it doesn't fight the NVIDIA driver.
- **Graphics:** hybrid. Intel iGPU drives the display, the RTX 2060 runs games through `prime-run`.
- **Sleep:** suspend is broken on this laptop, so lid, sleep key and power button all **hibernate** instead. NVIDIA needed extra config to survive it.
- **CPU fix:** a small script clears BD PROCHOT, which otherwise pins the CPU at 800 MHz after resume. The cause is a board/EC fault (the EC distrusts AC power), so the fix stays.
- **CPU power limits:** PL1 45 W / PL2 65 W instead of Lenovo's 90/135 W. Runs ~3.2 GHz all-core in the low 80s instead of sitting at the 94 °C cap. Set by `intel-undervolt-loop.service`, which reapplies them every 5 s (survives resume and Fn+Q).
- **Swap:** zram for everyday swapping, plus a disk partition for the hibernation image.
- **Snapshots:** btrfs + snapper + snap-pac, with a snapshot before and after every pacman transaction. Bootable from the GRUB menu via grub-btrfs.
- **Networking:** NetworkManager with wpa_supplicant (not iwd), so the Wi-Fi card can run a hotspot alongside its own connection.
- **Login:** Ly.

## Layout

```
~/.config/system/
├── README.md     ← this file
├── system.md     ← detailed notes: every setting and why
├── sync.sh       ← copies the system files below into files/
└── files/        ← copies of system files, original paths kept
    ├── etc/
    └── usr/
```

| File in `files/`                                              | What it does                                                    |
| ------------------------------------------------------------- | --------------------------------------------------------------- |
| `etc/modprobe.d/nvidia-power.conf`                            | Lets NVIDIA save video memory across hibernation                |
| `etc/systemd/logind.conf.d/10-hibernate.conf`                 | Lid, sleep key and power button → hibernate                     |
| `etc/systemd/zram-generator.conf`                             | zram swap                                                       |
| `etc/snapper/configs/`                                        | Snapshot limits                                                 |
| `etc/pacman.d/hooks/`                                         | Back up `/boot` with every snapshot                             |
| `etc/ly/config.ini`                                           | Login screen config                                             |
| `etc/NetworkManager/conf.d/99-ignore-ap0.conf`                | Keeps NetworkManager off the hotspot interface                  |
| `etc/intel-undervolt.conf`                                    | CPU power limits (45/65 W); undervolt is BIOS-locked, left at 0 |
| `usr/local/bin/disable-bd-prochot.sh` (+ service, sleep hook) | BD PROCHOT fix, at boot and after resume                        |

## Usage

**After editing a system file**, copy it into the repo and commit:

```bash
~/.config/system/sync.sh
dot add ~/.config/system && dot commit -m "system: <what changed>" && dot push
```

**On a fresh install**, restore files one at a time with `sudo cp`; don't copy `files/` over `/` in bulk. Then `systemctl enable --now intel-undervolt-loop.service`.

Some edits aren't stored as files (`mkinitcpio.conf`, `pacman.conf`, GRUB, kernel command line, fstab), because packages update them or they contain install-specific UUIDs. Those are described in `system.md` instead.

## Notes

This setup is specific to this laptop. Most of it (hibernation, BD PROCHOT, power limits, the Wi-Fi/hotspot behaviour) depends on this exact hardware.
