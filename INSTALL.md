# surface-pro-config
files needed to set up a ballin surface pro 3

the following guide was used to tripple boot Windows 10, [Kali Linux](https://www.kali.org/), and [ArchLabs Linux](https://archlabslinux.com/) on a Surface Pro 3

# Installation Prerequisites
You'll need the following:
 - USB with Kali Linux
 - USB with ArchLabs Linux
 - microSD Card (I'm using SanDisk Ultra 128GB microSDXC)
 - Windows Recovery USB (*optional*)
 - USB with Microsoft Surface Data Eraser (*optional*)

First things first, [boot into BIOS/UEFI](https://support.microsoft.com/en-us/help/4023532/surface-how-do-i-use-the-bios-uefi) and disable Secure Boot and change the boot order to `[USB -> SSD]`.

Insert the microSD Card and format it (this will be `/home` for the Linux paritions and will be reformatted later)

## Step 0: Refresh Hard Drive
This step is optional, and only recommended if you want to remove all the data and start with a clean, prestine Windows installation to work with. **MAKE SURE YOU HAVE ALREADY [CREATED A RECOVERY USB](https://support.microsoft.com/en-us/help/4023512/surface-creating-and-using-a-usb-recovery-drive) FOR YOUR SURFACE**

### Remove All Partitions
Use a Linux Live USB and use GParted to remove all partitions. I recommend using the Kali Linux USB you plan to use to install later.

### Setup Your Hard Drive for Windows
Follow Microsoft's guide to use [Microsoft Surface Data Eraser](https://docs.microsoft.com/en-us/surface/microsoft-surface-data-eraser) to repartition your hard drive. This will allow you to reinstall Windows on a clean hard drive and it will create the EFI system partition for you.

### Reinstall Windows
Use your RECOVERY USB to reinstall Windows.\
Select `Troubleshoot` -> `Recover from a drive` -> `Just remove my files` -> `Recover`

After you've gone through the installation process, make sure you aquire all the latest updates. This can take A LOOOONG TIME.

## Step 1: Windows Side of Things

Log into your Windows partition and open the Disk Management tool.

### Removing Extra Partitions (*optional*)
Chances are you will see a partition titled: `Healthy (Recovery Partition)`
The Disk Management tool will not allow you to remove it.
If this is the case, close the Disk Management tool and open a Command Prompt as Administrator and use `DISKPART` to remove the partition.
Otherwise, skip this step.

```bat
C:\Windows\system32> diskpart

DISKPART> select disk 0

DISKPART> list partition
:: look for the Volume for the Recovery Partition and use the number in the next command

DISKPART> select partition X
DISKPART> delete partition override
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
| `/dev/sdc1` | Kali + ArchLabs | 128 GB | `/home` |

To match the layout in the table above, the amount of space to shrink the Windows partition down by is 90112 MB

Create two partitions for Kali and ArchLabs:
- New Simple Volume
- Simple volume size in MB: 40960
- Do not assign a drive letter or drive path
- Format Partition
  - **File system**: exFAT
  - **Volume Label**: "KALI" or "ARCH"

Leave the remaining unallocated 8GB for `swap`. That will be created during the Kali installation.

### Install WinBtrfs (*optional*)
If you plan on using btrfs as your primary partition format, be sure to install [WinBtrfs](https://github.com/maharmstone/btrfs). Its still under active development, but good enough for day-to-day tasks and viewing your file systems on Windows. There is a very large NOTICE in the Readme file though. Decide if its worth the risk.

## Step 2: Kali Linux
Insert the Kali Linux USB and boot into the installer.

The mouse/trackpad didn't work with the Surface 4 TypeCover, the whole setup can be done without a mouse though. Go through the normal installation process, until you get the section on partitioning the drives.

In the *Partition disk* section, choose the `Manual` method.

Find the exFAT partition labled "KALI" from earlier and set the following options:
- format as `ext4` or `btrfs` (or your prefered file system)
- set mountpoint as `/`

Find the microSD card amongst your devices and select the entire device. Format as before:
- format as `ext4` or `btrfs` (or your prefered file system)
- set mountpoint as `/home`

Select the empty unpartitioned space:
- format as `swap`

Commit changes to disk.

The installation process should continue as normal.

Restart! You should be greeted with the Kali's GRUB interface. Start Kali and proceed with the post install setup.

### Post Install
Log in as `root`, upgrade the system, and install the `efitools` and `sbsigntool` packages.
```shellsession
root@kali:~# apt update && apt upgrade --yes && apt install efitools sbsigntool
```

#### Change root User Home
Open a terminal and copy the `/root` folder to the `/home` directory.
```shellsession
root@kali:~# cp -vr /root /home/.
```

Now we need to tell the system that the root users home directory has changed.

```shellsession
root@kali:~# sudoedit /etc/passwd
```
On the first line should be the root user's information, change `/root` to `/home/root`

Log out and log in to confirm everything is working.
Open a terminal and type `pwd` it should now show `/home/root`
```shellsession
root@kali:~# pwd
/home/root
```

#### Kernel Management
Kali, as of the 2019.1a release, will mount your `/boot` partition at `/boot/efi`. Confirm w/ `fstab` before continuing as this guide assumes that is the case, otherwise adjust the scripts accordingly.

We will need to keep the kernel for each installed Linux system organized as to not override each other or cause conflicts. A simple way is to keep a folder for each OS and store its associated files in each.

```shellsession
root@kali:~# mkdir -pv /boot/efi/EFI/kali
```

To ensure that the kernel is kept up to date, copy `zz-move-kernel` to the `postinst.d` folder 
```shellsession
root@kali:~# cp config/zz-move-kernel /etc/kernel/postinst.d/zz-move-kernel
root@kali:~# chmod 755 /etc/kernel/postinst.d/zz-move-kernel
```
This will ensure that any time the kernel is updated, that script will run, and place the kernel in the correct directory.

You can test to make sure that the script is working by reinstalling the kernel. Your version may be different, be sure to check `/lib/modules` to check which versions are available for reinstall.

```shellsession
root@kali:~# apt reinstall linux-image-4.19.0-kali3-amd64
```

#### Remove Grub
The system will be unbootable until another bootloader is installed, but that will be taken care of come ArchLabs.
```shellsession
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
Once rebooted, you should be greeted with the default config for the rEFInd bootloader. Hopefully you'll see 3 options: `Windows`, `vmlinuz-linux`, `\EFI\kali\vmlinuz`. Select `vmlinuz-linux` to boot into Arch.

Login and update the system (should be up to date from install), and install the `efitools` and `sbsigntools` packages
```shellsession
$ sudo pacman -Syyu efitools sbsigntools
```

#### Kernel Management
Similar to the setup for Kali, the linux kernel needs to be move/organized in order to not conflict with other distributions.
```shellsession
$ sudo mkdir -pv /boot/EFI/arch
$ sudo mv /boot/vmlinuz* /boot/initramfs* /boot/intel-ucode.img /boot/amd-ucode.img /boot/refind_linux.confg /boot/EFI/arch/.
```

Next, change the default locations for when `mkinitcpio` is called. You can manually change the location yourself or copy the config file in the `config` folder
```shellsession
$ sudo cp config/mkinitcpio-config /etc/mkinitcpio.d/linux.preset
```

Lastly, we need to add in [pacman hooks](https://wiki.archlinux.org/index.php/Pacman#Hooks) to sign (more on that later) and move `vmlinuz-linuz` to the `/boot/EFI/arch` directory.

```shellsession
$ sudo cp config/80-linux-move.hook /usr/share/libalpm/hooks/.
```
Confirm its working by reinstalling the `linux` package.

```shellsession
$ sudo pacman -Sy linux

### output should not have any errors ###

$ ls /boot/EFI/arch
initramfs-linux-fallback.img initramfs-linux.img vmlinuz-linux
```

Don't restart your computer yet, there are still a few issues with rEFInd that need to be taken care of.

### Fix Booting
#### Fixing Kali Linux

- copy `/boot/EFI/arch/refind_linux.conf` to `/boot/EFI/kali/refind_linux.conf`
  - Remove the second line about "Fallback"
  - Rename to `Kali Linux`
  - Update the `PARTUUID` in the file with Kali Linux's root partition (most likely `/dev/sda3` if youve been following along)
- mount `/dev/sda4` to `/mnt`
- use `lsblk` to view UUIDs
- update `/mnt/etc/fstab` to represent the swap partition (ArchLabs changed the partition id)

#### Fixing ArchLabs Linux
Open the `/boot/EFI/arch/refind_linux.conf`
Change the `initrd` options to have a prepended `/EFI/arch` in their path.
You can now reboot without a problem

## Step 4: Clean Up UEFI and Configuring rEFInd

### Cleaning Up UEFI and Boot Order
```shellsession
$ sudo efibootmrg
```

Make sure to remove any unnecessary bootloaders. I recommend keeping it to a minimum. I prefer to have USB first and foremost, then rEFInd, and if all else fails, make sure that the Windows Bootloader stays intact and I can get into my Windows system. For example, if you have `kali`, `grub`, etc, you can delete them using the `efibootmgr` command. Replace `XXXX` with the number of the bootloader from the output above.  

```shellsession
$ efibootmgr -B -b XXXX
```

### Configuring rEFInd
We need to manually add in the operating systems along with their respective loaders. `refind.conf` has a lot of templates at the bottom to choose from. I recommend starting out with them and then modifying it to match your system.

```nginx
menuentry "Windows" {
    loader \EFI\Microsoft\Boot\bootmgfw.efi
    enabled
}

menuentry "Arch Linux" {
    loader   /EFI/arch/vmlinuz-linux
    initrd   /EFI/arch/initramfs-linux.img
    options  "root=PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX rw add_efi_memmap"
    submenuentry "Boot using fallback initramfs" {
        initrd /EFI/archinitramfs-linux-fallback.img
    }
    submenuentry "Boot to terminal" {
        add_options "systemd.unit=multi-user.target"
    }
    enabled
}

menuentry "Kali Linux" {
    loader   /EFI/kali/vmlinuz
    initrd   /EFI/kali/initrd.img
    options  "root=PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX rw add_efi_memmap"
    enabled
}
```

For Arch and Kali, you will need to specify the root device and specify the `PARTUUID` in entry's `options` similar to the config shown above. Replace the `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` with your own `PARTUUID`s To find your `PARTUUID` values, use the `lsblk` command
```shellsession
$ lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,PARTUUID

NAME     SIZE TYPE MOUNTPOINT PARTUUID
sda    238.5G disk
├─sda1   200M part /boot      000f9b82-0f3f-4099-b246-5a4d3516c6e6
├─sda2   128M part            a7071e38-8fd9-4efb-9fdb-5b4ad1941105
├─sda3 150.2G part            50b39080-a066-4831-bd46-41db09f609a0
├─sda4    40G part            6eeac1ab-1bcb-4ef0-a36c-a256b4e2f197
├─sda5    40G part /          f6a9bd85-78b2-4d8c-a852-3a1ea3a86fc7
└─sda6     8G part [SWAP]     8014899f-61bb-4012-80e8-6bf403bc7a1a
sdb    119.1G disk
└─sdb1 119.1G part /home      1060381b-5222-4dcd-8c0a-88a851be879d
```

There are a lot of way to [customize rEFInd](http://www.rodsbooks.com/refind/configfile.html) and if you want to spice it up, I recommend going for it. There are also a [few themes](https://github.com/search?q=rEFInd+theme) out there you can use as well. I have my own custom setup at [my github page](https://github.com/funayman/surface-pro-config).

---

Restart and make sure you can boot into all of your operating systems.

You should have a fully functioning system.


## Step 5: Enabling Secure Boot (*optional*)
If you're happy without Secure Boot, you can skip this step. The following will erase all keys on your system, create your own keys, and use them to sign all the binaries needed to keep your computer running.

You can do this on either Linux distro, but I did everything from Kali.

I tried to make it as painless as possible, execute the scripts from this repo

```shellsession
root@kali:~# ./scripts/secure-boot-make-keys.sh
```

**reboot**

Go into BIOS/UEFI and delete keys and enable Secure Boot (this is Setup Mode).

**reboot into Kali**

Before installing the keys, the `secure-boot-install-keys.sh` script has hard-coded locations for the kernels. If you've been making changes along the way, adjust the following accordingly:
```shell
EPS=/dev/sda1
MOUNT=/mnt

# edit to your needs
declare -a BINARIES=(
"$MOUNT/EFI/kali/vmlinuz"
"$MOUNT/EFI/arch/vmlinuz-linux"
"$MOUNT/EFI/refind/refind_x64.efi"
)
```

Then run the script to install your keys and sign your kernels.

```shellsession
root@kali:~# ./scripts/secure-boot-install-keys.sh
```

If you're interested in how the scripts work, what they do, or where they were derived from, check out the following resources:
- [Sakaki's EFI Install Guide/Configuring Secure Boot](https://wiki.gentoo.org/wiki/Sakaki%27s_EFI_Install_Guide/Configuring_Secure_Boot)
- [Arch Wiki: Secure Boot](https://wiki.archlinux.org/index.php/Secure_Boot)
- [Managing EFI Boot Loaders for Linux: Controlling Secure Boot](http://www.rodsbooks.com/efi-bootloaders/controlling-sb.html#creatingkeys)

### Confirmation
Once you reboot, you should have Secure Boot Enabled along with the ability to boot into all of your OSes!

If you go into the BIOS/UEFI, you should see "Secure Boot Enabled".

### Ensuring Kernel Updates Get Signed
Time to future proof the machine. Any time there is a kernel upgrade, it needs to be signed with the keys you made previously. If all the key files are still in the EFI System Partition from the `secure-boot-install.sh` script, then everything is ready to go.

## Kali Linux
You will need to replace the previously installed `zz-move-kernel` script with one that will sign the kernel when upgrading.

```shellsession
root@kali:~# rm /etc/kernel/postinst.d/zz-move-kernel
root@kali:~# cp config/zz-sign-kernel /etc/kernel/postinst.d/zz-sign-kernel
root@kali:~# chmod 755 /etc/kernel/postinst.d/zz-sign-kernel
```

Confirm its working properly by reinstalling the kernel (your kernel might be a different version).

```shellsession
root@kali:~# apt reinstall linux-image-4.19.0-kali3-amd64
```

If there were no errors, thats a good sign! Restart the machine and ensure that you can still boot Kali.

## ArchLabs Linux
A similar approach will be taken for Arch Linux. The hook previously installed needs to be replaced with a `-sign` version.

```shellsession
$ sudo rm /usr/share/libalpm/hooks/80-linux-move.hook
$ sudo cp config/80-linux-sign.hook /usr/share/libalpm/hooks/80-linux-sign.hook
```

Confirm its working properly by reinstalling the `linux` package

```shellsession
$ sudo pacman -Sy linux
```

Again, no errors is a good start. Reboot the machine and confirm that rEFInd can still boot into ArchLabs.
