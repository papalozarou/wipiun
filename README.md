# WiPiUn

A Dockerised VPN using **Wi**reguard, **Pi**Hole and **Un**bound: **WiPiUn**.

This setup guide has been tested on Ubuntu 20.04 LTS and 22.04 LTS.

## Contents

1. [Cloning and customising the repository](#4-cloning-and-customising-this-repository)
1. [Installing the Wireguard app, and the profiles, on your devices](#5-installing-the-wireguard-app-and-the-profiles-on-your-devices)
1. [Post run configuration](#6-post-run-configuration)
1. [Credits](#7-credits)

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
