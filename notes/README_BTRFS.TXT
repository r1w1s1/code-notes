
INSTALLING SLACKWARE64-CURRENT ON BTRFS SUBVOLUMES
==================================================

This is a short recipe for installing Slackware64-current with Btrfs
subvolumes using the normal Slackware installer.

The basic layout is:

    @       /
    @home   /home

Both subvolumes share the free space of one Btrfs filesystem. This guide does
not require a separate /home partition. @tmp, quotas, and snapshots are
optional and are covered briefly at the end.

WARNING: partitioning and filesystem creation destroy data. Confirm the target
disk with lsblk before running any destructive command.

For clarity, use three virtual consoles during the installation:

    Console 1 (Alt-F1)  this document, mounted at /doc
    Console 2 (Alt-F2)  commands and checks
    Console 3 (Alt-F3)  setup

If this document is on a USB drive, identify its partition first. Do not
assume that the USB drive is /dev/sda or /dev/sdb:

    lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS
    mkdir -p /doc
    mount /dev/sdX1 /doc
    less /doc/README_BTRFS.TXT

Replace /dev/sdX1 with the actual USB partition. Do not mount the whole disk
when it has a partition table.

Keep setup open in Console 3 while running the required checks in Console 2.
Return to Console 3 only after the checks have succeeded.


1. BOOT THE INSTALLER AND IDENTIFY THE DISK
-------------------------------------------

Boot the Slackware64-current installer and log in as root. Check the boot mode
and available disks:

    test -d /sys/firmware/efi && echo UEFI || echo Legacy
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS

Use the whole disk name with cfdisk or cgdisk, not a partition name.

For Legacy/BIOS on /dev/sda, create an MBR/DOS partition table:

    cfdisk /dev/sda

    /dev/sda1    swap
    /dev/sda2    remaining space for Btrfs

For UEFI/GPT on /dev/nvme0n1, use cgdisk or cfdisk with a GPT partition
table:

    cgdisk /dev/nvme0n1

    /dev/nvme0n1p1    512 MiB or larger EFI System Partition
    /dev/nvme0n1p2    swap
    /dev/nvme0n1p3    remaining space for Btrfs

Use the corresponding /dev/sda names for a SATA disk. Confirm the result:

    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS

Set variables in the same console and keep them for the remaining steps.

Legacy/MBR:

    SWAP=/dev/sda1
    ROOT=/dev/sda2

UEFI/GPT on NVMe:

    EFI=/dev/nvme0n1p1
    SWAP=/dev/nvme0n1p2
    ROOT=/dev/nvme0n1p3

UEFI/GPT on SATA:

    EFI=/dev/sda1
    SWAP=/dev/sda2
    ROOT=/dev/sda3


2. FORMAT THE FILESYSTEMS
-------------------------

Verify the variables before continuing:

    printf 'EFI=%s\nSWAP=%s\nROOT=%s\n' "$EFI" "$SWAP" "$ROOT"

For Legacy, EFI will be empty. Format the Btrfs partition now. The Slackware
installer will format and activate swap in ADDSWAP:

    /sbin/mkfs.btrfs -f -L SLACK_ROOT "$ROOT"

For UEFI, also format the EFI System Partition:

    mkfs.fat -F 32 -n SLACK_EFI "$EFI"


3. CREATE THE SUBVOLUMES
-------------------------

Mount the Btrfs top-level subvolume and create @ and @home:

    mount -o subvolid=5 "$ROOT" /mnt
    /sbin/btrfs subvolume create /mnt/@
    /sbin/btrfs subvolume create /mnt/@home

Make @ the default subvolume. Use the ID shown for the line whose path is @:

    /sbin/btrfs subvolume list /mnt
    /sbin/btrfs subvolume set-default <ID-of-@> /mnt
    /sbin/btrfs subvolume get-default /mnt

The last command must show the ID and path of @, not ID 5 (FS_TREE). This is
required because the unmodified Slackware installer mounts the selected
partition without subvol=@. Unmount the top-level subvolume:

    umount /mnt


4. RUN THE NORMAL SLACKWARE INSTALLER
--------------------------------------

    setup

Use the normal sequence:

    KEYMAP       optional
    ADDSWAP      select the swap partition and let setup format it
    TARGET       select the Btrfs ROOT partition
    SOURCE       select the installation source
    SELECT       choose the package series
    INSTALL      install the packages
    CONFIGURE    configure the installed system

In TARGET, select ROOT and choose not to format it. TARGET is required so
setup can mount /mnt, install the packages, and create the initial fstab.
The initial root entry will be corrected in the next section.

Before installing packages, open another console with Alt-F2, or leave setup
after TARGET, and remount /mnt with compression:

    mount -o remount,noatime,compress=zstd /mnt
    findmnt -no SOURCE,FSTYPE,OPTIONS /mnt

Continue only when the output shows subvol=@ and compress=zstd. Mount options
added later to fstab do not compress files that were already installed.

Do not select ROOT as a second target for /home. The installer does not know
that @ and @home are separate subvolumes in one partition.

For UEFI, let setup detect and mount the EFI System Partition at /boot/efi.
Configure the bootloader normally. Bootloader details are outside this guide.


5. MOUNT @HOME AND FIX /ETC/FSTAB
---------------------------------

After installation and configuration, return to the installer shell. Ensure
the installed root is mounted at /mnt, then mount @home:

    mkdir -p /mnt/home
    mount -o noatime,compress=zstd,subvol=@home "$ROOT" /mnt/home
    findmnt /mnt/home

Edit the fstab of the installed system, not the installer environment:

    vi /mnt/etc/fstab

Replace the plain Btrfs root entry generated by setup; do not add a duplicate
root entry.

Legacy/MBR example:

    /dev/sda2  /      btrfs  noatime,compress=zstd,subvol=@      0 0
    /dev/sda2  /home  btrfs  noatime,compress=zstd,subvol=@home  0 0
    /dev/sda1  none   swap   defaults                            0 0

UEFI/GPT example:

    /dev/nvme0n1p3  /          btrfs  noatime,compress=zstd,subvol=@      0 0
    /dev/nvme0n1p3  /home      btrfs  noatime,compress=zstd,subvol=@home  0 0
    /dev/nvme0n1p2  none       swap   defaults                            0 0
    /dev/nvme0n1p1  /boot/efi  vfat   defaults                            1 0

Use the actual device names. UUID= entries are also valid, but this guide
uses Slackware's usual /dev names. Keep the proc, devpts, and tmpfs entries
created by setup. Do not leave duplicate entries for /, /home, or /boot/efi.

Correct the swap entry as shown above and remove any stale entries that refer
to hardware not present, such as /dev/fd0. Check the file before rebooting:

    cat /mnt/etc/fstab

If the bootloader was configured before this fstab change, update its
configuration afterward. The Legacy/GRUB kernel command line must include:

    rootflags=subvol=@


6. VERIFY AND REBOOT
--------------------

Check the target, subvolumes, fstab, and boot files before rebooting:

    findmnt /mnt
    /sbin/btrfs subvolume list /mnt
    cat /mnt/etc/fstab
    ls -l /mnt/boot

The root entry must use subvol=@ and the home entry must use subvol=@home.

    reboot

After the first boot, verify:

    findmnt /
    findmnt /home
    findmnt --verify
    btrfs subvolume list /

For UEFI, also check:

    findmnt /boot/efi


7. OPTIONAL: @TMP AND QUOTAS
----------------------------

Do this only after the basic installation boots successfully. To create @tmp,
mount the top-level subvolume and add a matching fstab entry:

    ROOT=/dev/sda2              # Legacy example
    # ROOT=/dev/nvme0n1p3       # UEFI/NVMe example
    mkdir -p /mnt/btrfs-top
    mount -o subvolid=5 "$ROOT" /mnt/btrfs-top
    btrfs subvolume create /mnt/btrfs-top/@tmp
    umount /mnt/btrfs-top
    rmdir /mnt/btrfs-top

Add this to /etc/fstab, using the actual device name:

    /dev/sda2  /tmp  btrfs  noatime,compress=zstd,subvol=@tmp  0 0

Move or remove existing /tmp contents before mounting the new subvolume over
the directory.

Btrfs quotas are not required for normal operation and do not divide the
available space automatically. If you need them, study and test separately:

    btrfs quota enable /
    btrfs quota rescan /
    btrfs qgroup show /


==================================================================
Author:
    Ricardson Williams <ricardsonwilliams@gmail.com>


------------------------------------------------------------------

Last Modified: 2026-10-16 14:00:09 UTC
