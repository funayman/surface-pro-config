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

First things first, [boot into BIOS/UEFI](https://support.microsoft.com/en-us/help/4023532/surface-how-do-i-use-the-bios-uefi) and disable Secure Boot and change the boot order to `[USB -> SSD]`.

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
Next is to create the partition layout for your drive. Adjust to fit your needs, my final layout ended up being:

**Internal Hard Drive**

| Device | OS | Size | Mount Point |
|----|----|----|----|
| `/dev/sda1` | EFI System Partition | 200 MB | `/boot` |
| `/dev/sda3` | Windows | 160 GB | `C:` |
| `/dev/sda4` | Kali | 40 GB | `/` |
| `/dev/sda5` | ArchLabs | 40 GB | `/` |
| `/dev/sda6` | Swap | 8 GB | `swap` |

**microSD Card**

| Device | OS | Size | Mount Point |
|----|----|----|----|
| `/dev/sdc1` | N/A | 128 GB | `/home` |

Shrink the Windows partition down to 90112 MB

Create two partitions for Kali and ArchLabs:
 - New Simple Volume
 - Size: 40960
 - Do not assign a letter
 - Format: exFAT Label: "KALI" or "ARCH"

Leave the remaining unallocated 8GB for `swap`. That will be created during the Kali installation.

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
Log in as `root`, upgrade the system, and install the `efitools` and `sbsigntool` packages.
```bash
root@kali:~# apt update && apt upgrade --yes && apt install efitools sbsigntool
```

#### Change root User Home
Open a terminal and copy the `/root` folder to the `/home` directory.
```
root@kali:~# cp -r /root /home/.
```

Now we need to tell the system that the root users home directory has changed.

```
root@kali:~# sudoedit /etc/passwd
```
On the first line should be the root user's information, change `/root` to `/home/root`

Log out and log in to confirm everything is working.
Open a terminal and type `pwd` it should now show `/home/root`
```
root@kali:~# pwd
/home/root
```

#### Kernel Management
Kali, as of the 2019.1a release, will mount your `/boot` partition at `/boot/efi`. Confirm w/ `fstab` before continuing as this guide assumes that is the case, otherwise adjust the scripts accordingly.

We will need to keep the kernel for each installed Linux system organized as to not override each other or cause conflicts. A simple way is to keep a folder for each OS and store its associated files in each.

```
root@kali:~# mkdir -pv /boot/efi/EFI/kali
```

To ensure that the kernel is kept up to date, copy `zz-sign-and-move-kernel` to the `postinst.d` folder 
```bash
cp scripts/zz-sign-and-move-kernel /etc/kernel/postinst.d/zz-sign-and-move-kernel
chmod 755 /etc/kernel/postinst.d/zz-sign-and-move-kernel
```
This will sign the new kernel with your MOK (more on that later) and place it in the correct directory.

#### Remove Grub
The system will be unbootable until another bootloader is installed, but that will be taken care of come ArchLabs.
```
root@kali:~# apt purge grub*
root@kali:~# apt autoremove --purge
```

## Step 3: ArchLabs Linux
ArchLabs, as of 2019.01.20, does not allow the root partition to be formatted with `btrfs`. You can choose `ext4` and then try to convert it to `btrfs` post install, but thats on your own.

### Installation
I wont go over how to install ArchLabs as the developers have made the installation process very easy to figure out. There are a couple of options during the installation process that need to be addressed.

#### Mount and Format Partitions
When selecting `/`, as mentioned before, `btrfs` was not an option so I opted for `ext4` instead.
The installer will ask what to use as a `swap` partition, select the previous partition you selected for Kali Linux.
Finally, you'll have a chance select other mount points. Select `/dev/sdc1/` (or whatever your microSD card device is) and mount it as `/home`. **DO NOT FORMAT THE microSD CARD**

##### Bootloader
ArchLabs Linux allows you to choose a bootloader of your choice. Since the end goal is rEFInd, select it and have it install for us.

#### Create User and Set Passwords
When choosing a username, **do not** use the same one that is used for Kali (if you created a regular user on Kali). Make sure to have different user names on each Linux installation. Otherwise it will cause conflicts with config files and software versions.

### Post Installation
Once rebooted, you should be greeted with the default config for the rEFInd bootloader. You'll notice that Kali Linux is not listed on there. Thats fine, we will fix everything in the following section.

Login and update the system (should be up to date from install), and install the `efitools` and `sbsigntools` packages
```bash
$ sudo pacman -Syyu efitools sbsigntools
```

#### Kernel Management
Similar to the setup for Kali, the linux kernel needs to be move/organized in order to not conflict with other distributions.
```
$ sudo mkdir -pv /boot/EFI/arch
$ sudo mv /boot/vmlinuz* /boot/initramfs* /boot/intel-ucode.img /boot/EFI/arch/.
```

Next, change the default locations for when `mkinitcpio` is called. You can manually change the location yourself or copy the config file in the `scripts` folder
```bash
$ cp scripts/mkinitcpio-config /etc/mkinitcpio.d/linux.preset
```

Lastly, we need to add in [pacman hooks](https://wiki.archlinux.org/index.php/Pacman#Hooks) to sign (more on that later) and move `vmlinuz-linuz` to the `/boot/EFI/arch` directory.

```bash
$ sudo cp scripts/80-linux-move.hook /usr/share/libalpm/hooks/.
```
Confirm its working

```bash
$ sudo pacman -Sy linux

### output should not have any errors ###

$ ls /boot/EFI/arch
initramfs-linux-fallback.img initramfs-linux.img vmlinuz-linux
```

## Step 4: Clean Up UEFI and Configuring rEFInd

## Step 5: Controlling Secure Boot

Copy the `KeyTool.efi` to the rEFInd `tools` directory
```bash
# Kali Linux
root@kali:~$ cp /usr/lib/efitools/x86_64-linux-gnu/KeyTool.efi /boot/efi/EFI/tools/.
```
```bash
# ArchLabs Linux
$ sudo cp /usr/share/efitools/efi/KeyTool.efi /boot/EFI/tools/.
```

