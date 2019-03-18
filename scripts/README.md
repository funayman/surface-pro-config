# scripts

handy scripts for smooth installation

```bash
# Kali Linux Post Kernel Install
cp zz-sign-and-move-kernel /etc/kernel/postinst.d/zz-sign-and-move-kernel
chmod 755 /etc/kernel/postinst.d/zz-sign-and-move-kernel
```

```bash
# ArchLabs Linux /etc/mkinitcpio.d/linux.preset
cp mkinitcpio-config /etc/mkinitcpio.d/linux.preset
```

```bash
# ArchLabs Linux Pacman Hook
cp 80-linux-move.hook /usr/share/libalpm/hooks/.
```
