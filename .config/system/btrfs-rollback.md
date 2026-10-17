# Snapshots & Rollback

How this laptop recovers from a bad update or a broken boot.

## How it works

- **btrfs** root and home, split into subvolumes: `@` (`/`), `@home`, `@log`, `@pkg`.
- **snapper** takes hourly snapshots of `/` and `/home`, and deletes old ones automatically.
- **snap-pac** takes a snapshot **before and after** every pacman transaction.
- **`/boot` backup hooks**: `/boot` is a FAT partition that snapshots can't include, so a pacman hook copies it into `/.bootbackup` first. Every snapshot carries the kernel that matches it.
- **grub-btrfs** lists the snapshots in the GRUB menu, so you can boot into one.
- Caches and big re-downloadable folders (`~/.cache`, Steam, SDKMAN) are separate subvolumes, so home snapshots skip them.

## Recovering

| Problem                                | Fix                                                                                       |
| -------------------------------------- | ----------------------------------------------------------------------------------------- |
| Lost or broke one file                 | Copy it back out of `/.snapshots/N/snapshot/` or `/home/.snapshots/N/snapshot/`           |
| An update broke something, still boots | `snapper undochange` the update's pre/post pair, then copy `/.bootbackup` back to `/boot` |
| Won't boot                             | Hold **Esc** → GRUB → **Arch Linux snapshots** → boot one, then make it the new `@`       |
| GRUB menu doesn't work either          | Arch ISO USB: rename `@`, make a writable copy of a snapshot as the new `@`               |

Root is mounted by name (`subvol=@`), so whatever subvolume is called `@` is what boots. That's why rollbacks swap `@` instead of using `snapper rollback`.

## Things to remember

- **Snapshot before risky changes** (kernel cmdline, mkinitcpio, GRUB, NVIDIA): `sudo snapper -c root create -d "description"`. Only package changes are snapshotted automatically.
- **If it failed while hibernated**, clear the hibernation image in swap before rolling back.
- **A snapshot boot is for recovery only**: read-only root, current kernel, no hibernation.
- **Snapshots aren't backups.** They live on the same SSD. Keep important things in git or on another disk.
