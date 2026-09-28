# Btrfs Snapshots & Rollback — Legion (Arch)

How snapshots are set up on this machine and how to recover from a bad update, a broken boot, or a deleted file.

---

## 1. How the setup works

| Piece                                | What it does                                                                                                                          |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| **snapper** (`root`, `home` configs) | Takes hourly timeline snapshots of `/` and `/home`, and cleans old ones up automatically                                              |
| **snap-pac**                         | Takes a `pre` snapshot before and a `post` snapshot after every pacman/AUR transaction                                                |
| **`/boot` backup hooks**             | Copies `/boot` (the UKI) into `/.bootbackup` before and after every transaction, so each root snapshot also holds the matching kernel |
| **Excluded subvolumes**              | `~/.local/share/Steam`, `~/.cache`, `~/.sdkman` are their own subvolumes, so home snapshots skip them                                 |

### Disk layout

| Subvolume          | Mounted at              | Snapshotted?                                                 |
| ------------------ | ----------------------- | ------------------------------------------------------------ |
| `@`                | `/`                     | Yes, config `root`                                           |
| `@home`            | `/home`                 | Yes, config `home`                                           |
| `@log`             | `/var/log`              | No. Logs survive a rollback, which is useful for debugging   |
| `@pkg`             | `/var/cache/pacman/pkg` | No. The package cache survives, so you can reinstall offline |
| `@/.snapshots`     | `/.snapshots`           | Where root snapshots are stored                              |
| `@home/.snapshots` | `/home/.snapshots`      | Where home snapshots are stored                              |

- Btrfs partition: `/dev/nvme0n1p3`
- ESP (`/boot`, FAT): `/dev/nvme0n1p1`. Check with `lsblk -f` before relying on this.
- Swap / hibernation: `/dev/nvme0n1p2`, UUID `b21112ac-2391-4a72-865c-ab616ba7b697`
- Kernel cmdline (`/etc/kernel/cmdline`) mounts root **by name** with `rootflags=subvol=@`. That's what makes Case B below work.

### Hook order during a pacman transaction

```
04-boot-backup-pre      copy /boot → /.bootbackup
05-snap-pac-pre         PRE snapshot  (contains the old kernel)
   ... packages change ...
90-mkinitcpio-install   rebuild the UKI
95-boot-backup-post     copy the new /boot → /.bootbackup
zz-snap-pac-post        POST snapshot (contains the new kernel)
```

The hook files live in `/etc/pacman.d/hooks/`.

### Retention limits

|                                   | root                  | home |
| --------------------------------- | --------------------- | ---- |
| Hourly                            | 5                     | 10   |
| Daily                             | 7                     | 7    |
| Weekly                            | 0                     | 4    |
| Monthly                           | 0                     | 2    |
| Yearly                            | 0                     | 0    |
| pacman snapshots (`NUMBER_LIMIT`) | 20 (about 10 updates) | n/a  |
| `SPACE_LIMIT`                     | 0.3                   | 0.3  |

---

## 2. Everyday commands

```bash
sudo snapper -c root list                 # list root snapshots
sudo snapper -c home list                 # list home snapshots
sudo snapper -c root status 69..70        # what files an update changed
sudo snapper -c root diff 69..70 /etc/pacman.conf   # diff one file between snapshots
sudo snapper -c root create -d "before messing with nvidia"   # manual snapshot
sudo snapper -c root delete 42            # delete one snapshot
sudo snapper -c home delete 1-40          # delete a range
sudo btrfs filesystem usage / -h          # disk space overview
```

**Take a manual snapshot before anything risky**, like editing the mkinitcpio config, the kernel cmdline or NVIDIA settings. pacman only snapshots automatically for package changes.

---

## 3. Restore a single file

Nothing needs to be rolled back. Just copy the file out of a snapshot.

```bash
# find a snapshot from before the file was lost
sudo snapper -c home list

# home snapshot N → your files are under .../snapshot/solidv/
sudo ls /home/.snapshots/N/snapshot/solidv/
sudo cp -a /home/.snapshots/N/snapshot/solidv/path/to/file ~/path/to/file
sudo chown solidv:solidv ~/path/to/file

# a system file from a root snapshot
sudo cp -a /.snapshots/N/snapshot/etc/some.conf /etc/some.conf
```

You can also let snapper do it:

```bash
sudo snapper -c home undochange N..0 /home/solidv/path/to/file   # 0 = current live system
```

> `Steam`, `.cache` and `.sdkman` are **not** in home snapshots. Restoring from them isn't possible.

---

## 4. Case A: the system boots, but an update broke something

1. Find the pre/post pair for the bad update:

   ```bash
   sudo snapper -c root list
   ```

   Look for a `pre` row, then a `post` row whose "Pre #" column points back to it, with the pacman command in the description. For example, `69 pre` and `70 post 69`.

2. See what it changed (optional):

   ```bash
   sudo snapper -c root status 69..70
   ```

3. Revert it:

   ```bash
   sudo snapper -c root undochange 69..70
   ```

   This also reverts `/.bootbackup` to the pre-update kernel.

4. Put the matching kernel/UKI back on the ESP:

   ```bash
   sudo rsync -a --delete /.bootbackup/ /boot/
   ```

5. Reboot:

   ```bash
   reboot
   ```

6. **Stop it happening again:** until the upstream problem is fixed, hold the broken package back by adding it to `IgnorePkg` in `/etc/pacman.conf`.

> pacman's database (`/var/lib/pacman`) is inside `@`, so it's reverted too. pacman will correctly think the old versions are installed.

---

## 5. Case B: it won't boot at all

You need an **Arch ISO USB stick**. Keep one around.

### Before you start: hibernation

If the laptop **hibernated** and then failed to come back, there's a stale hibernation image in swap. Resuming it onto a rolled-back filesystem can corrupt data. Clear it first, keeping the same UUID so `resume=` still works:

```bash
mkswap -U b21112ac-2391-4a72-865c-ab616ba7b697 /dev/nvme0n1p2
```

If the laptop was fully shut down, skip this.

### Steps (from the live USB)

```bash
# 0. check the partitions: p1 = vfat ESP, p2 = swap, p3 = btrfs
lsblk -f

# 1. mount the top level of the btrfs filesystem (not @)
mount -o subvolid=5 /dev/nvme0n1p3 /mnt

# 2. find the snapshot to restore (usually the PRE snapshot of the bad update)
ls /mnt/@/.snapshots/
cat /mnt/@/.snapshots/69/info.xml          # shows date + description

# 3. keep the broken system aside instead of deleting it
mv /mnt/@ /mnt/@broken

# 4. make a writable copy of the snapshot as the new @
btrfs subvolume snapshot /mnt/@broken/.snapshots/69/snapshot /mnt/@

# 5. carry over the nested subvolumes (a snapshot only has empty folders where these were)
rmdir /mnt/@/.snapshots && mv /mnt/@broken/.snapshots /mnt/@/
rmdir /mnt/@/var/lib/portables && mv /mnt/@broken/var/lib/portables /mnt/@/var/lib/
rmdir /mnt/@/var/lib/machines  && mv /mnt/@broken/var/lib/machines  /mnt/@/var/lib/

# 6. restore the matching kernel/UKI onto the ESP
mkdir -p /esp
mount /dev/nvme0n1p1 /esp
rsync -a --delete /mnt/@/.bootbackup/ /esp/

# 7. done
umount -R /esp /mnt
reboot
```

Because the kernel cmdline says `rootflags=subvol=@`, the system boots straight into the restored `@`.

### After it boots fine: delete the broken copy

```bash
sudo mount -o subvolid=5 /dev/nvme0n1p3 /mnt
sudo btrfs subvolume delete /mnt/@broken
sudo umount /mnt
```

### If step 5 complains

If `rmdir` says "Directory not empty", something else was in that folder. Look inside before continuing. Don't force it.

---

## 6. Restore all of `/home` (rare)

This is almost never needed, since restoring single files (section 3) covers most cases. If you must restore everything:

1. Log out and switch to a TTY as **root**. Your user must not be logged in.
2. Mount the top level, then swap `@home` the same way as Case B:
   ```bash
   mount -o subvolid=5 /dev/nvme0n1p3 /mnt
   mv /mnt/@home /mnt/@home-broken
   btrfs subvolume snapshot /mnt/@home-broken/.snapshots/N/snapshot /mnt/@home
   rmdir /mnt/@home/.snapshots && mv /mnt/@home-broken/.snapshots /mnt/@home/
   ```
3. **Move the excluded subvolumes back in**, because they'll be empty folders in the restored home:
   ```bash
   for d in solidv/.local/share/Steam solidv/.cache solidv/.sdkman; do
     rmdir "/mnt/@home/$d" && mv "/mnt/@home-broken/$d" "/mnt/@home/$d"
   done
   ```
4. `umount /mnt`, reboot, check everything, then delete `@home-broken`.

---

## 7. Why not `snapper rollback`?

`snapper rollback` works by changing the btrfs **default subvolume**. This system mounts root **explicitly** with `subvol=@` (in both fstab and the kernel cmdline), which overrides the default, so `snapper rollback` would not switch anything. Use Case A or Case B instead.

---

## 8. Snapshots are not backups

Snapshots live on the **same SSD**. If the drive dies, they die with it. Keep important data (projects, dotfiles) in git or on another disk as well.

---

## 9. Quick health check

```bash
systemctl is-enabled snapper-timeline.timer snapper-cleanup.timer   # both "enabled"
sudo snapper -c root list | tail -4                                  # recent pre/post pairs
sudo du -sh /boot /.bootbackup                                       # should be ~equal
sudo btrfs subvolume list /home | grep -E 'Steam|cache|sdkman'       # 3 excluded subvolumes
```
