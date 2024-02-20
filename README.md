A simple bash script to easily connect to Proxmox VE serial consoles and for learning/collaboration.

`screen` launches with multi-user support, allowing multiple users to interact with the console simultaneously. Simply open a second console on another host and start collaborating..

Utilities used: whirptail, screen, socat, qm

For connections via sshd, example configuration `/etc/ssh/sshd_config.d/pve-serial-hub.conf`:

```
cat <<'EOT' >/etc/ssh/sshd_config.d/pve-serial-hub.conf
Port 1022

Match LocalPort 1022
    AllowUsers root
    ForceCommand /root/pve-serial-hub.sh
EOT
service ssh reload
```

Now we need to start the getty process responsible for the serial terminal on /dev/ttyS0 on the VM::
```
systemctl enable --now serial-getty@ttyS0
```

To exit and save session, press Ctrl+D. To break session, press Ctrl+B.


For adaptive console size, you can use this bash script on VM, which will be run at login:
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
chmod +x /etc/profile.d/serial_resize.sh
```
And run `serial_resize`
