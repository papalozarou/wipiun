# WiPiUn

A Dockerised VPN using **Wi**reguard, **Pi**Hole and **Un**bound: **WiPiUn**.

This setup guide has been tested on Ubuntu 20.04 LTS and 22.04 LTS.

## Contents

1. [Installation](#1-cloning-and-customising-this-repository)
1. [Installing the Wireguard app, and the profiles, on your devices](#2-installing-the-wireguard-app-and-the-profiles-on-your-devices)
1. [Post run configuration](#3-post-run-configuration)
1. [Credits](4-credits)

## Prerequisites

To run this repository it's assumed you've used the [linux setup scripts]() and built the [base alpine images]().

## 1. Installation

Clone the repository, and change to the repository setup directory with:

```
git clone --recursive https://github.com/papalozarou/wipiun.git && \
cd ~/wipiun/setup
```

Run the first script:

```
sudo ./01-initialise-setup.sh
```

Once completed, run subsequent scripts following instructions and prompts.

## 2. Installing the Wireguard app, and the profiles, on your devices

Now you can [install the Wireguard App](https://www.wireguard.com/install/) for your selected system and add the profile for your selected device, either using the QR code or the file found in:

```
~/wipiun/wireguard/config/client_${yourDeviceName}
```

## 3. Post run configuration

Once the containers are up and running, you need to set a password in Pihole and optionally add more blocklists. You must be connected to your VPN to administer your VPN's instance of Pihole.

### 3.1. Set a Pihole password

Because there is no password specified in `compose.xml`, the Pihole container generates a random admin password when it first runs. To set a new one, we need to SSH into our Pihole Docker container:

```
sudo docker exec -it pihole /bin/sh
```

Once inside the container, change the password with:

```
pihole -a -p
```

You will be prompted to type a new password. If you leave it empty, no password will be set so you can login without one.

### 3.2. Add blocklists

Within `~/wipiun/pihole` you will find `blocklists.txt` which contains a space separated list of blocklists. To add this list to Pihole:

1. Tap `Adlists` in the left hand navigation of Pihole;
2. Paste the contents of `blocklists.txt` into the `Address:` field;
3. Tap `Add`;
4. Tap `Tools` in the left hand navigation, then tap `Update Gravity`; and
5. Tap `Update`.

Once Gravity has updated, if you navigate back to the `Adlists` page, you will see all the additional blocklists.

## 4. Credits

This project has shamelessly cherry picked, and built on top of, other people's amazing work:

* The main inspiration to do this came from [Rajan Patel's Pihole/Wireguard hosted VPN](https://github.com/rajannpatel/Pi-Hole-on-Google-Compute-Engine-Free-Tier-with-Full-Tunnel-and-Split-Tunnel-Wireguard-VPN-Configs).
* Further inspiration was taken from [Linuxserver's Wireguard Docker container](https://github.com/linuxserver/docker-wireguard), taking their approach and re-writing their set-up script to learn about how to set Wireguard up – it was more interesting than following the docks. DUDE.
* To make sure the above was done in the correct way, [Just Containers' s6-overlay service as a script guide](https://github.com/just-containers/s6-overlay#writing-a-service-script) was followed.
* Pihole simply uses the [Pihole official Docker containter](https://hub.docker.com/r/pihole/pihole/) because life is too short.
* For Unbound minor tweaks were made to [Matthew Vance's Unbound Docker](https://github.com/MatthewVance/unbound-docker).
* Lastly, there are definitely several StackOverflow and Pihole forum posts that I have forgotten, which also went into getting this up and running.
