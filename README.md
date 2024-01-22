A simple bash script to easily connect to Proxmox VE serial consoles and study collaboration

Utilities used: whirptail, screen, socat, qm

For connections via sshd, example configuration /etc/ssh/sshd_config.d/pve-serial-hub.conf:

```
Port 1022

Match LocalPort 1022
    AllowUsers root
    ForceCommand /root/pve-serial-hub.sh
```

Editing GUB:
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet console=ttyS0"
```
```
update-grub && reboot
```
