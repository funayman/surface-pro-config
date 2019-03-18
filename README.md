# surface-pro-config
files needed to set up a ballin surface pro 3

the following guide was used to tripple boot Windows 10, [Kali Linux](https://www.kali.org/), and [ArchLabs Linux](https://archlabslinux.com/) on a Surface Pro 3

# Installation
Disable Secure boot
Insert SD Card and format to FAT (this will be `/home` for the Linux paritions and will be reformatted later)


## Step 0: Refresh Hard Drive
This step is optional, and only recommended if you want to remove all the data and start with a clean, prestine Windows installation to work with. **MAKE SURE YOU HAVE ALREADY CREATED A RECOVERY USB FOR YOUR SURFACE**

### Remove All Partitions
Use a Linux Live USB and use GParted to remove all partitions. I recommend using the Kali Linux USB you plan to use to install later.

### Setup Your Hard Drive for Windows
Follow Microsoft's guide to use [Microsoft Surface Data Eraser](https://docs.microsoft.com/en-us/surface/microsoft-surface-data-eraser) to repartition your hard drive. This will allow you to reinstall Windows on a clean hard drive and it will create the EFI partition for you.

### Reinstall Windows
Use your RECOVERY USB to reinstall Windows. Select `Troubleshoot` -> `Install from Disk` -> `Windows 10`.

After you've gone through the installation process, make sure you aquire all the latest updates. This can take A LOOOONG TIME.

## Step 1: Windows Side of Things

## Step 2: Kali Linux
go through the usual install process until partition section

Select "Manually"

Find the exFAT partition labled "KALI" earlier, format as `btrfs`, set mountpoint as `/`
Select the SDCard AS A WHOLE, we will reformat the whole SDCARD. format as `btrfs`, set mountpoint as /home
Select the empty unpartitioned space. Format as swap space.
Commit changes.

The installation process should continue as normal.

Restart! You should be greeted with the Kali's GRUB interface. Start Kali and proceede with the post install setup.

### Post Install
Log in as `root`

#### Change root User Home
Open a terminal and copy the `/root` folder to the `/home` directory.
```bash
cp -r /root /home/.
```

Now we need to tell the system that the root users home directory has changed. Enter the following in your terminal:

```bash
sudoedit /etc/passwd
```
On the first line should be the root user's information, change `/root` to `/home/root`

Log out and log back in to confirm everything is working.
Open a terminal and type `pwd` it should now show `/home/root`
```bash
$ pwd
/home/root
```

#### Kernel Management
Kali, as of the 2019.1a release, will mount your `/boot` partition at `/boot/efi`. Confirm w/ `fstab` before continuing as this guide assumes that is the case, otherwise adjust the scripts accordingly.

We will need to keep the kernels for each installed Linux system organized as to not override each other or cause conflicts.

```bash
$ mkdir -p /boot/efi/EFI/kali
```

Post kernel install script

## Step 3: ArchLabs Linux

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
