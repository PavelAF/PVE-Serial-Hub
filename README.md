A simple bash script to easily connect to Proxmox VE serial consoles and study collaboration

Utilities used: whirptail, screen, socat, qm

For connections via sshd, example configuration `/etc/ssh/sshd_config.d/pve-serial-hub.conf`:

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

For adaptive console size, you can use this bash script, which will be run at login:
```
cat <<'EOT' >/etc/profile.d/serial_resize.sh
serial_resize() {
  old=$(stty -g)
  stty raw -echo min 0 time 5

  printf '\0337\033[r\033[999;999H\033[6n\0338' > /dev/tty
  IFS='[;R' read -r _ rows cols _ < /dev/tty

  stty "$old"

  stty cols "$cols" rows "$rows"
}
[[ "$(tty)" =~ ^/dev/ttyS[0-9]$ ]] && serial_resize
EOT
```
And run `serial_resize`
