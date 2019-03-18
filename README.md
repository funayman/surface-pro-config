# surface-pro-config
files needed to set up a ballin surface pro 3

the following guide was used to tripple boot Windows 10, [Kali Linux](https://www.kali.org/), and [ArchLabs Linux](https://archlabslinux.com/) on a Surface Pro 3

# Installation
You'll need the following:
 - USB with Kali Linux
 - USB with ArchLabs Linux
 - microSD Card (I'm using SanDisk Ultra 128GB microSDXC)
 - Windows Recovery USB (*optional*)
 - USB with Microsoft Surface Data Eraser (*optional*)

First things first, [boot into BIOS/UEFI](https://support.microsoft.com/en-us/help/4023532/surface-how-do-i-use-the-bios-uefi) and disable Secure Boot and change the boot order to `USB -> HDD`.

Insert the microSD Card and format it (this will be `/home` for the Linux paritions and will be reformatted later)

## Step 0: Refresh Hard Drive
This step is optional, and only recommended if you want to remove all the data and start with a clean, prestine Windows installation to work with. **MAKE SURE YOU HAVE ALREADY CREATED A RECOVERY USB FOR YOUR SURFACE**

### Remove All Partitions
Use a Linux Live USB and use GParted to remove all partitions. I recommend using the Kali Linux USB you plan to use to install later.

### Setup Your Hard Drive for Windows
Follow Microsoft's guide to use [Microsoft Surface Data Eraser](https://docs.microsoft.com/en-us/surface/microsoft-surface-data-eraser) to repartition your hard drive. This will allow you to reinstall Windows on a clean hard drive and it will create the EFI system partition for you.

### Reinstall Windows
Use your RECOVERY USB to reinstall Windows. Select `Troubleshoot` -> `Install from Disk` -> `Windows 10`.

After you've gone through the installation process, make sure you aquire all the latest updates. This can take A LOOOONG TIME.

## Step 1: Windows Side of Things

Log into your Windows partition and open the Disk Management tool.

### Removing Extra Partitions (*optional*)
Chances are you will see a partition titled: `Healthy (Recovery Partition)`
The Disk Management tool will not allow you to remove it.
If this is the case, close the Disk Management tool and open a Command Prompt as Administrator and use `DISKPART` to remove the partition.
Otherwise, skip this step.

```dos
C:\Windows\system32> diskpart

DISKPART> list volume
## look for the Volume for the Healthy (Recovery Partition) and use the nuber in the next command

DISKPART> select volume X
DISKPART> delete volume override
```

Reopen the Disk Management tool and extend the Windows partition to reallocate the space the empty space. You could leave it unallocated, but I prefer reallocating and then shrinking the drive.

### Setup Disk Partition Layout
Next is to create the partition layout for your drive. Adjust to fit your needs, my final planned layout will look like:

| os | size |
|--------|------|
| Windows | 150GB |
| Kali | 40GB |
| Archbang | 40GB |
| Swap | 8GB |

Shrink Windows partition down to 90112 MB

Create two partitions for Kali and ArchLabs:
 - New Simple Volume
 - Size: 40960
 - Do not assign a letter
 - Format: exFAT Label: "KALI" or "ARCH"

Leave the remaining unallocated 8GB for `swap` later.

## Step 2: Kali Linux
Insert the Kali Linux USB and boot into the installer.

Go through the normal installation process, until you get the section on partitioning the drives.

In the options for how to handle the disk, choose `Manually`.

Find the exFAT partition labled "KALI" from earlier and set the following options:
- format as `btrfs` (or your prefered file system)
- set mountpoint as `/`


Find the microSD card amongst your devices and select the entire device. Format as before:
- format as `btrfs` (or your prefered file system)
- set mountpoint as `/home`

Select the empty unpartitioned space:
- format as `swap space`

Commit changes.

The installation process should continue as normal.

Restart! You should be greeted with the Kali's GRUB interface. Start Kali and proceede with the post install setup.

### Post Install
Log in as `root` and upgrade the system.

#### Change root User Home
Open a terminal and copy the `/root` folder to the `/home` directory.
```bash
cp -r /root /home/.
```

Now we need to tell the system that the root users home directory has changed.

```bash
sudoedit /etc/passwd
```
On the first line should be the root user's information, change `/root` to `/home/root`

Log out and log in to confirm everything is working.
Open a terminal and type `pwd` it should now show `/home/root`
```bash
$ pwd
/home/root
```

#### Kernel Management
Kali, as of the 2019.1a release, will mount your `/boot` partition at `/boot/efi`. Confirm w/ `fstab` before continuing as this guide assumes that is the case, otherwise adjust the scripts accordingly.

We will need to keep the kernel for each installed Linux system organized as to not override each other or cause conflicts. A simple way is to keep a folder for each OS and store its associated files in each.

```bash
$ mkdir -pv /boot/efi/EFI/kali
```

Post kernel install script

Remove GRUB

## Step 3: ArchLabs Linux
ArchLabs, as of 2019.01.20, does not allow the root partition to be formatted with `btrfs`. You can choose
### Bootloader
ArchLabs Linux forces you to select a bootloader to install. Choose rEFInd.

### Kernel Management
```ini
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux

[Action]
Description = Move kernel to new location after install
When = PostTransaction
Exec = mv /boot/vmlinuz-linux /boot/EFI/arch/vmlinuz-linux
```
Confirm its working

```bash
$ sudo pacman --force -S linux

--- snip ---

$ ls /boot/EFI/arch
vmlinuz-linux initrd.img
```

## Step 4: Clean Up UEFI and Configuring rEFInd

## Step 5: Controlling Secure Boot
