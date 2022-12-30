# WiPiUn

A Dockerised VPN using **Wi**reguard, **Pi**Hole and **Un**bound: **WiPiUn**.

This setup guide has been tested on Ubuntu 20.04 LTS and 22.04 LTS.

## Contents

1. [Choosing where to host your server](#1-choosing-where-to-host-your-server)
1. [Securing your server](#2-securing-your-server)
1. [Installing Docker](#3-installing-docker)
1. [Cloning and customising the repository](#4-cloning-and-customising-this-repository)
1. [Installing the Wireguard app, and the profiles, on your devices](#5-installing-the-wireguard-app-and-the-profiles-on-your-devices)
1. [Post run configuration](#6-post-run-configuration)
1. [Credits](#7-credits)

## 1. Choosing where to host your server

You will need somewhere to host your VPN server, either an existing server, a hosting service, or something like Google Cloud. This guide covers both hosted servers and Google Cloud VM instances.

### 1.1. On your own server

If you have an existing server, most likely you can skip to step 4, as we'll assume you've secured your server and are already using Docker. If you're setting up a server for the first time, skip to step 1.3.

### 1.2. On your Google VM instance

One of the advantages of hosting your VPN in a Google VM instance is that, if you [stick within certain limits](https://cloud.google.com/free/docs/free-cloud-features#free-tier-usage-limits), you can host it on a free account.

We'll assume you already have a [Google account](https://accounts.google.com), but if not create one. From there use it to log into [cloud.google.com](https://cloud.google.com), by tapping `Try for Free` in the top right. 

Then follow these steps:

1. Agree to the terms and conditions and then enable billing on your account – you can't continue without it.
2. Tap the menu in the top left, tap `Compute Engine` and select `VM instances`.
3. At this point if you haven't created a project already you will be asked to. 
4. Enable billing on this project – as with step 2, you can't continue without it.
5. Create a new VM instance by tapping the `Create` button.
6. Fill in or change the following details:
   * Name: `${yourInstanceName}`
   * Region: `us-east1`, `us-west1`, or `us-central1` if you want to remain in the free tier
   * Machine configuration: `General-purpose`, `E2`, `e2-Micro` again for the free tier
   * Boot disk: `Ubuntu`, `Ubuntu 20.04 LTS minimal` or `Ubuntu 22.04 LTS minimal`, `Standard persistent disk`, `30GB`
7. Expand `Advanced Options` then `Networking`, then scroll down and expand `Edit network interface` under `Network interfaces`:
   * Open the `External IPv4 address` dropdown
   * Tap `Create IP address` to create a static IP address
   * Give it a name and tap `Reserve`
9. Scroll to the bottom and tap `Create` to save the instance.

You will now have a Google VM instance that you can SSH into via the Google Cloud console. You will add an SSH key, and change the port for access via a third party client, in step 2. 

### 1.3 Update and upgrade your server

Once you have your server instance ready to go, SSH into your server then update and upgrade with:

```
:~ $ sudo apt update && sudo apt upgrade -y
```

### References
* [Rajan Patel's guide to Google Compute hosting](https://github.com/rajannpatel/Pi-Hole-on-Google-Compute-Engine-Free-Tier-with-Full-Tunnel-and-Split-Tunnel-Wireguard-VPN-Configs/blob/master/GOOGLE-CLOUD.md)

## 2. Securing your server

### 2.1. Hardening OpenSSH

The next step is to secure your server by hardening SSH access. The SSH server will be configured to:

1. only listen for ip4 connections;
2. change the listening port to [a random port number between 20000 and 65535](https://www.random.org);
3. disable root login;
4. enable ssh keys;
5. disable password authentication; and
6. disable some other options.

Open the SSH daemon config file:

```
:~ $ sudo nano /etc/ssh/sshd_config
```

Edit and set the following lines – some of them may need uncommenting, the last one needs commenting out:

```
Port ${sshPortNumber}
AddressFamily inet
[…]
LoginGraceTime 20
PermitRootLogin no
[…]
MaxAuthTries 3
MaxSessions 3
[…]
AuthenticationMethods publickey
PubkeyAuthentication yes
[…]
PasswordAuthentication no
PermitEmptyPasswords no
[…]
KbdInteractiveAuthentication no
[…]
KerberosAuthentication no
[…]
GSSAPIAuthentication no
[…]
UsePAM no
[…]
AllowAgentForwarding no
[…]
X11Forwarding no
[…]
PermitUserEnvironment no
[…]
#AcceptEnv LANG LC_*
```

*N.B.*
Although [Digital Ocean's guide recommends it](https://www.digitalocean.com/community/tutorials/how-to-harden-openssh-on-ubuntu-20-04), setting `AllowTcpForwarding` to `no` in `sshd_config` will mean you can't connect via Visual Studio Code. The guide also recommends setting `PermitTunnel` to `no` but this will interfere with your VPN. 

### 2.3. Adding your SSH keys

The method of adding your SSH keys varies depending on where you are hosting your VPN.

#### 2.3.1. On your own server

On your server you need to set up the `.ssh` folder and `authorized_keys` file to store the public key, ensuring that the correct permissions are set on the folder – `700` – and the file – `600`:

```
:~ $ mkdir ~/.ssh
:~ $ touch ~/.ssh/authorized_keys
:~ $ chmod 700 ~/.ssh
:~ $ chmod 600 ~/.ssh/authorized_keys
:~ $ ls -lna ~/.ssh
drwx------ .
-rw------- authorized_keys
```

Paste the generated public key into `authorized_keys` and save. You can now restart the server:

```
:~ $ sudo systemctl restart sshd
```

*N.B.*
Before closing the current session, check you can still login to your server by opening a new terminal session and testing the login. 

#### 2.3.2. On your Google VM instance

If you want to access the VM using third party software, i.e. not Google's Cloud CLI or the web interface, you will need to add a public SSH key to your VM instance. Before doing this, using your chosen method, you will need to generate an `rsa` SSH key pair – at present VM instances _only_ supports `rsa` keys.

Once you have generated your keys, you will need to add the public key to your VM instance:

1. In your Google Cloud console, navigate to your VM instance and tap on it's name, then tap `Edit` in the top banner.
2. Scroll down to the SSH section within `Security and access`.
3. Tap `Add item` to add a new key, and paste the public key inside the text box that appears.
4. If you wish to create a new user on the VM instance, you will need to add the username, preceeded by a space, to the end of they key within this field, i.e. `ssh-rsa {yourPublicKey} ${yourUsername}`.
5. Scroll to the bottom and tap `Save`.

*N.B.*
Do not restart sshd just yet – you will need to allow your SSH port in step 2.3.2 first.

#### 2.3.3. On your local machine

On your local machine add the server to your `ssh_config` or `config` file:

```
:~ $ nano ~/.ssh/ssh_config
```

And add the following, editing according to your setup:

```
Host ${connectionName}
  Hostname ${ipAddress} 
  Port ${sshPortNumber} 
  User ${userName}
  IdentityFile ~/.ssh/${piRouterPrivateKeyFile}
```

You can now connect to your router via:

```
:~ $ ssh ${connectionName}
```

### 2.3. Configuring a firewall

As with SSH keys, the firewall you use depends on where you are hosting your VPN

#### 2.3.1. On your own server

UFW may or may not be installed and if it isn't, install it with:

```
:~ $ sudo apt install ufw -y
```

Whether it was already installed or you installed it, it will be inactive. Before activating it, you must allow ports for your SSH connection and the later VPN connection.

Firstly you want to explicitly deny all incoming traffic and allow all outgoing traffic:

```
:~ $ sudo ufw default deny incoming
:~ $ sudo ufw default allow outgoing
```

For good measure, explicilty deny port 22:

```
:~ $ sudo ufw deny 22
```

Add your `${sshPortNumber}`, from step 2.1, via `tcp` only:

```
:~ $ sudo ufw limit ${sshPortNumber}/tcp
```

And then add [a random port number between 20000 and 65535](https://www.random.org) for your VPN, via `udp` only:

```
:~ $ sudo ufw limit ${vpnPortNumber}/tcp
```

UFW doesn't allow you to block ping responses via it's commandline interface, so you need to edit `before.rules`:

```
:~ $ sudo nano /etc/ufw/before.rules
```

And then change the following lines from `ACCEPT` to `DROP`:

```
# ok icmp codes for INPUT
[…]
-A ufw-before-input -p icmp --icmp-type echo-request -j DROP
```

Now enable UFW:

```
:~ $ sudo ufw enable
```

#### 2.3.2. On your Google VM instance

You can add firewall rules via Google Cloud's web interface. Tap the menu in the top left hand corner, go to the `VPC Network` menu, and tap `Firewall`. You will be presented with a list of the current firewall rules.

Firstly, you need to edit the existing SSH rule to allow your ${sshPortNumber} from step 2.1. To do this, tap the existing `default-allow-ssh` rule, tap `edit` towards the top then change the value under `TCP` to match your `${sshPortNumber}`. Scroll to the bottom and tap `Save`. This will return you to the current firewall rules list.

It's now safe to restart the sshd server for your VM instance:

```
:~ $ sudo systemctl restart sshd
```

You will need to add your VPN rule. Towards the top you will see an option to `Create a firewall rule`. Tap this then:

1. Give your rule a name, i.e. `allow-vpn`.
2. Scroll down to `Targets` and select `All instances in the network`.
3. Under `Source IPv4 ranges *`, type `0.0.0.0/0`.
4. Make sure `Specified protocols and ports` is selected then check `UDP` and add [a random port number between 20000 and 65535](https://www.random.org) for your VPN in the `UDP Ports` field.
5. Scroll to the bottom and tap `Create`.

*N.B.*
You can also delete the `default-allow-rdp` and `default-allow-icmp` rules – you will not be running any services on port 3389 (rdp) and you don't really want anyone issuing the [ping of death](https://en.wikipedia.org/wiki/Ping_of_death) (icmp) against you either.

### 2.4. Configuring Fail2Ban

Fail2Ban will likely not be so install it with:

```
:~ $ sudo apt install fail2ban -y
```

By default, Fail2Ban reads `*.conf` files first, then `*.local` files, which override any settings found in the `*.conf` files.

As you're not changing anything within the default `fail2ban.conf` you only need to create a jail config:

```
:~ $ sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

Open the `jail.local` file:

```
:~ $ sudo nano /etc/fail2ban/jail.local
```

And set the following lines – you may need to comment some of these lines out to set them:

```
ignoreip = 127.0.0.1/8
[…]
bantime = 10m
[…]
findtime = 5m
[…]
maxretry = 3
[…]
[sshd]
[…]
enabled = true
```

Save and exit the config file. Now reload Fail2Ban:

```
:~ $ sudo systemctl start fail2ban
```

Should you wish, you can check the status of Fail2Ban with:

```
:~ $ sudo systemctl status fail2ban
```

### References
* [Digital Ocean's guide to hardening OpenSSH server](https://www.digitalocean.com/community/tutorials/how-to-harden-openssh-on-ubuntu-20-04)
* [Cyberciti's OpenSSH best practices](https://www.cyberciti.biz/tips/linux-unix-bsd-openssh-server-best-practices.html)
* [sshd_config man page](https://man.openbsd.org/sshd_config)
* [Digital Ocean's guide to setting up UFW](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-20-04)
* [Cyberciti's guide to limiting SSH connections with UFW](https://www.cyberciti.biz/faq/howto-limiting-ssh-connections-with-ufw-on-ubuntu-debian/)
* [Digital Ocean's guide to protecting SSH with Fail2Ban](https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-ubuntu-20-04)

## 3. Installing Docker

As Docker maintains excellent documentation it's pointless to rehash that here – just follow the [Docker Linux install guide](https://docs.docker.com/engine/install/ubuntu/) then come back here and resume from step 4.

### References
* [Docker's Linux install guide](https://docs.docker.com/engine/install/ubuntu/)

## 4. Cloning and customising this repository

To run this project you will first need to clone it from Github:

```
:~ $ git clone https://github.com/papalozarou/WiPiUn ~/{yourVPNFolder}
```

Then copies of both `.env-example` and `docker-compose-example.xml`:

```
:~ $ cd ~/${yourVPNFolder}
:~ $ cp .env-example .env
:~ $ cp docker-compose-example.yml docker-compose.yml
```

### 4.1 Customising the `.env` file

You should be able to run the project without making changes to the `.env` file, however there are two changes that you may want to make.

#### 4.1.1 Changing the user name and group name

If you want to more closely match your host system values, run:

```
:~ $ whoami && id
${yourUsername}
uid=${yourUID}(${yourUsername}) gid=${yourGID}(${yourGroupName}) …
```
And edit lines 4-7 to match:

```
H_UID=${yourUID}
H_GID=${yourGID}
H_USR=${yourUsername}
H_GRP=${yourGroupName}
```

If you change `H_USR` and/or `H_GRP` you _will_ need to change the corresponding values in `~/${yourVPNFolder}/unbound/unbound.sh` on lines 23 and 24.

#### 4.1.2 Changing the Unbound version

If you want to change the version of Unbound, edit line 29 to match the version you require:

```
U_VERSION=1.16.2
```
The latest stable version number can be found on the [Unbound homepage](https://nlnetlabs.nl/projects/unbound/about/).

### 4.2 Customising the `docker-compose.yml` file

The `docker-compose.yml` file is heavily annotated, so reading it will give you a fair idea of what's going on. 

For the project to run, the only change you need to make are within the `wireguard` service, on lines 52, 53, 55 and 63:

```
      - TZ=Europe/London
      - SERVER_PORT=00000
      # - SERVER_URL=yoursubdomain.yourdomain.com
      - CLIENTS=The,List,Of,Your,Devices
      […]
    ports:
    - "00000:51820/udp"
```

Adjust the timezone to your desired setting, and change `SERVER_PORT` to the `${vpnPortNumber}` you defined in step 2.3.x. Add a comma seperated list of your devices to `CLIENTS` – this can actaully be a number, though it's easier if you explicitly name each device. Finally change line 63 to so that it reads `${vpnPortNumber}:51820/udp`.

You can ignore the commented out `SERVER_URL` declaration until this guide is updated with Nginx and LetsEncrypt instructions.

Each service runs on a specific IP address, within the `172.16.0.0/24` range, on the `vpnNetwork` Docker network:

* Wireguard – `172.16.0.2`
* Pihole – `172.16.0.3`
* Unbound – `172.16.0.4`

Wireguard also has it's own internal subnet range of `172.17.0.0` that it uses to give connected devices an IP.

The project will run without making any changes to this network config, however you can obviously change the network IP addresses, and Wireguard's internal subnet, to something in the `10.x.x.x` or `192.168.x.x` range. You can also change the network name with a quick find and replace for `vpnNetwork`.

### 4.3 Wireguard

You do not need to make any changes within `~/${yourVPNFolder}/wireguard`. All necessary files will be generated on first run of the Wireguard container.

### 4.4 Pihole

You do not need to make any changes within `~/${yourVPNFolder}/pihole`. All necessary files will be generated on first run of the Pihole container.

### 4.5 Unbound

If you did not change the `.env` file, you do not need to make any changes within `~/${yourVPNFolder}/unbound`. All necessasry files will be generated on first run of the Unbound container.

If you changed lines 4-7 within the `.env` file however, you _will_ need to change lines 23 and 24 in `unbound.sh` to match:

```
H_USR=${yourUsername}
H_GRP=${yourGroupName}
```

### 4.6 Running the project

You will now be ready to bring the project up with:

```
:~ $ sudo docker compose up -d
```

On first run, both the Wireguard and Unbound containers will be built from scratch, creating and downloading the necessary files.

To check that things are working correctly you can run:

```
:~ $ sudo docker compose ps -a
NAME                COMMAND             SERVICE             STATUS              PORTS
pihole              "/s6-init"          pihole              running (healthy)   53/udp, 53/tcp, 80/tcp, 67/udp
unbound             "/unbound.sh"       unbound             running             53/tcp, 53/udp
wireguard           "/init"             wireguard           running             0.0.0.0:${vpnPortNumber}->51820/udp, :::${vpnPortNumber}->51820/udp
```

## 5. Installing the Wireguard app, and the profiles, on your devices

Now you can [install the Wireguard App](https://www.wireguard.com/install/) for your selected system and add the profile for your selected device, either using the QR code or the file found in `~/${yourVPNFolder}/wireguard/config/client_${yourDeviceName}`.

## 6. Post run configuration

Once the containers are up and running, you need to set a password in Pihole and optionally add more blocklists. You must be connected to your VPN to administer your VPN's instance of Pihole.

### 6.1. Set a Pihole password

Because there is no password specified in `docker-compose.xml`, the Pihole container generates a random admin password when it first runs. To set a new one, we need to SSH into our Pihole Docker container:

```
:~ $ sudo docker exec -it pihole /bin/sh
```

Once inside the container, change the password with:

```
:~ $ pihole -a -p
```

You will be prompted to type a new password. If you leave it empty, no password will be set so you can login without one.

### 6.2. Add blocklists

Within `~/${yourVPNFolder}/pihole` you will find `blocklists.txt` which contains a space separated list of blocklists. To add this list to Pihole:

1. Tap `Adlists` in the left hand navigation of Pihole;
2. Paste the contents of `blocklists.txt` into the `Address:` field;
3. Tap `Add`;
4. Tap `Tools` in the left hand navigation, then tap `Update Gravity`; and
5. Tap `Update`.

Once Gravity has updated, if you navigate back to the `Adlists` page, you will see all the additional blocklists.

## 7. Credits

This project has shamelessly cherry picked, and built on top of, other people's amazing work:

* The main inspiration to do this came from [Rajan Patel's Pihole/Wireguard hosted VPN](https://github.com/rajannpatel/Pi-Hole-on-Google-Compute-Engine-Free-Tier-with-Full-Tunnel-and-Split-Tunnel-Wireguard-VPN-Configs).
* Further inspiration was taken from [Linuxserver's Wireguard Docker container](https://github.com/linuxserver/docker-wireguard), taking their approach and re-writing their set-up script to learn about how to set Wireguard up – it was more interesting than following the docks. DUDE.
* To make sure the above was done in the correct way, [Just Containers' s6-overlay service as a script guide](https://github.com/just-containers/s6-overlay#writing-a-service-script) was followed.
* Pihole simply uses the [Pihole official Docker containter](https://hub.docker.com/r/pihole/pihole/) because life is too short.
* For Unbound minor tweaks were made to [Matthew Vance's Unbound Docker](https://github.com/MatthewVance/unbound-docker).
* Lastly, there are definitely several StackOverflow and Pihole forum posts that I have forgotten, which also went into getting this up and running.
