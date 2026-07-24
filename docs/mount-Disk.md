sudo mkdir -p /mnt/wehttamsnaps/LINUXDRIVE
sudo mkdir -p /mnt/wehttamsnaps/EXTRA1TB
sudo mkdir -p /mnt/wehttamsnaps/GAMEDRIVE
sudo mkdir -p /mnt/wehttamsnaps/WettamSnapsMain

sudo mount /dev/sdb1 /mnt/wehttamsnaps/LINUXDRIVE-1
sudo mount -t ntfs-3g /dev/sdd1 /mnt/wehttamsnaps/PC-EXTRA-2
sudo mount -t ntfs-3g /dev/sdi1 /mnt/wehttamsnaps/GAMEDRIVE
sudo mount -t ntfs-3g /dev/sdj1 /mnt/wehttamsnaps/Wettam-Snaps-Main

sudo unmount /dev/sdb1 /mnt/wehttamsnaps/LINUXDRIVE-1
sudo udiskie-umount /dev/sdd1 /mnt/wehttamsnaps/PC-EXTRA-2
sudo udiskie-umount /dev/sde1 /mnt/wehttamsnaps/GAMEDRIVE
sudo udiskie-umount /dev/sdj1 /mnt/wehttamsnaps/Wettam-Snaps-Main

echo "========================================"
echo "Arch Linux Disk Mounting Cheat Sheet"
echo "========================================"

echo -e "\n📋 QUICK MOUNT COMMANDS:"
echo "# Mount drive: udisksctl mount -b /dev/sdXY"
echo "# Unmount: udisksctl unmount -b /dev/sdXY"
echo "# List drives: lsblk -f"

echo -e "\n🎯 YOUR DRIVES CHEAT SHEET:"
echo "PC-EXTRA-2:      udisksctl mount -b /dev/sdd1"
echo "Wettam Snaps Main: udisksctl mount -b /dev/sde1"
echo "GAMEDRIVE:       udisksctl mount -b /dev/sdj1"
echo "LINUXDRIVE-1:    udisksctl mount -b /dev/sdb1"

echo -e "\n🔍 CHECK DRIVE STATUS:"
echo "# See all drives: lsblk -f"
echo "# See mounted drives: df -h | grep -E '(/dev/sd|/mnt/)'"
echo "# Check drive health: sudo smartctl -a /dev/sdX"

# --- WehttamSnaps Data Drives ---

# /dev/sdc1 -> LINUXDRIVE
UUID=c0f59cf7-9437-4ee3-be68-e27e7b1e52ae  /mnt/wehttamsnaps/LINUXDRIVE       ext4    defaults,noatime,nofail    0>

# /dev/sdf1 -> EXTRA1TB
UUID=d3283959-c9d3-494a-b832-72f961ea7a92  /mnt/wehttamsnaps/EXTRA1TB         ext4    defaults,noatime,nofail    0>

# /dev/sdd1 -> GAMEDRIVE
UUID=3f996c97-b699-4208-b9fc-1a64bc65b478  /mnt/wehttamsnaps/GAMEDRIVE        ext4    defaults,noatime,nofail    0>

# /dev/sde1 -> WettamSnapsMain (4.5TB NTFS)
UUID=2C66D88566D850E6                      /mnt/wehttamsnaps/WettamSnapsMain  ntfs-3g defaults,uid=1000,gid=1000,d>


echo -e "\n📁 AUTO-MOUNT AT BOOT (fstab):"
echo "# Edit fstab: sudo nano /etc/fstab"
echo "# Example entry:"
echo "/dev/sdd1 /mnt/PC-EXTRA-2 ntfs-3g defaults,uid=1000,gid=1000,umask=002 0 0"
echo ""
echo "# Apply changes:"
echo "sudo systemctl daemon-reload"
echo "sudo mount -a"

