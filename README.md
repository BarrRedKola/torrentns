# torrentns
Scripts for firing up linux network namespace and run transmission server and openvpn within it.

# Before usage
Update source/extra.sh to specify different constant variables

# Bootstrap
Run `./bootstrap.sh` to install the necessary dependencies

# For VPN
Create an `auth.txt` in the SCRIPT_ROOT as well as in SCRIPT_ROOT/nordVPN to make sure.
This file should contain your nordVPN username and password; each in one line below each other and nothing else, e.g.:
```
myNordVPNuser
secretPassword4VPN
```

# Usage
```
sudo bash ./run_torrent_ns.sh -p <SCRIPT_ROOT> -n <NAMESPACE> -t <TRANSMISSION_DIR>
```
NAMESPACE will be `torrent`, SCRIPT_ROOT will be `$HOME/torrentns`, and TRANSMISION_DIR will be `$HOME/.config/transmission-daemon` if not changed!

# Set your own transmission preferences 
via copying the `transmission_config` to `$HOME/.config/transmission-daemon/`


# Add script to run on RaspberryPI/Debian/Ubuntu/OtherLinuxDistros after system boots
Add the following line to `/etc/crontab` as root
```
@reboot  root cd /home/ryzen/torrentns && /home/<YOURUSER>/torrentns/run_torrent_ns.sh -p <SCRIPT_ROOT> -n <NAMESPACE> -t <TRANSMISSION_CONFIG> &
```
Update path if required!

# Disable the original transmission-daemon to start at boot
```
sudo systemctl disable transmission-daemon
```
Also edit `/etc/default/transmission-daemon` and change the line
```
ENABLE_DAEMON=1
```
to
```
ENABLE_DAEMON=0

```

Then, reboot your machine and see if everything works as expected.

The best way to check this is to run the script first manually, ensure it is running in the namespace.
Then, add a torrent. For instance, the checkIP torrent in this repo.
Then, reboot your machine. 
After it boots up, and you can connect to the transmission-daemon and the added torrent is still there, you have configured everything correctly.
If there is no added torrent, it means you connected to another instance, which might not be running within the namespace, i.e., not running behind a VPN.


## Troubleshooting
Some full-fledged distributions trying to take over the control from you, like Ubuntu-based ones, like to mess up with your settings. 
It means that your `NetworkManager` and/or the `systemd/system-resolved` services can mess up your DNS configuration found in `/etc/resolv.conf`.
What this means is that the system uses its own stub resolver, not that there is anything wrong with that BUT, which can be found at `127.0.0.53`.
This works totally fine for your system, but within the network namespace, this stub resolver cannot be reached! Therefore, since the network namespace also gets the DNS server data from `/etc/resolv.conf`, you end up not having domain name resulution within the namespace.

Psssst, manually editing the file works until you reboot, but even if this script I wrote has a `nameserver 1.1.1.1` text, which it appends to /etc/resolv.conf, if the script is set to run after reboot, your `NetworkManager` and/or `systemd/system-resolved` service may overwrite it.

### Enough said! What is the solution!
Add your nameservers to `/etc/resolvconf/resolv.conf.d/tail`!
```
nameserver 1.1.1.1
nameserver 8.8.8.8
```
If you don't have this file, install `resolvconf` package.

Then, to lose `127.0.0.53` as the DNS, disable the systemd-resolved service and stop it:
```
sudo systemctl disable systemd-resolved.service
sudo service systemd-resolved stop
```
Put the following line in the `[main]` section of your `/etc/NetworkManager/NetworkManager.conf`:
```
dns=default
```

Delete the symlink `/etc/resolv.conf` (yes, it is a symlink, so it is recommended to delete and let the system recreate it as a regular file):
```
sudo rm /etc/resolv.conf
```

Restart `network-manager`:
```
sudo service network-manager restart 
```
This is it! After reboot, and already after restarting network-manager, your resolv.conf will look like as we want!



