# Overview

Please note this guide was written with Ubuntu 18.04 LTS in mind. Experience with Linux command line is necessary. Enjoy.

I finally did the Radarr/Deluge pipeline for torrents. A short description of how this works is:

* Mullvad VPN on client (plex server)
* Radarr imports movies and allows you to find new ones with The Movie DB
* Radarr sees you want a new movie. It finds it on trackers setup with Jackett.
* It sends that torrent URL to Deluge.
* Deluge downloads it.
* Radarr grabs that file and throws it into Plex.
* Plex sees the library change and indexes the movie.

My old system was:

* Turn on VPN on Windows machine
* Download torrent manually, check multiple sites
* SFTP to Plex server

This was shitty and manual. I had 187 movies at the time of this writing doing this method.

To start, I setup Mullvad VPN on my private network. This can be done with a VPS or other remote server, you just need to have enough storage to make it worthwhile. It is assumed you have a working Plex installation on the remote server. All of the links for services you see are assuming my private network. Adjust your IP accordingly, but the default ports should be the same and useful for you. Start by SSHing into your remote server.

## Mullvad

You can use any trusted VPN. I highly recommend [Mullvad](https://mullvad.net/en/) due to their security and anonymity. 

It's use is super easy. First, download the Linux client with:
<code>wget https://mullvad.net/media/app/MullvadVPN-2019.10_amd64.deb</code>

Install this with:
<code>sudo dpkg -i MullvadVPN-2019.10_amd64.deb</code>

Now you can use the mullvad VPN on command line. For my setup, I wanted to have my VPN on all the time. Some other users may want to only have their torrent client use the VPN, to prevent leakage. See this [article](https://mullvad.net/en/help/bittorrent/) for help, and expand it to other torrent clients.

**Important:** I instantly locked myself out of my machine when setting this up without thinking. You MUST enable LAN access to continue remote access to your machine. See <code>mullvad lan</code> for more details.


<code>mullvad status</code> is a good way to see the current status. Are you connected or not?

<code>mullvad account XXXXX</code> to connect. Obviously input XXXX as your actual account number.

To verify, run <code>curl ifconfig.me</code>. Make sure it's not your normal public IP. This method is insecure, for some reason, so keep that in mind.

Now your machine is connected to a VPN, *and* accessible through it's private address. Good job!

## Radarr

[Radarr](http://192.168.0.186:7878/)

Onto Radarr. I didn't setup anything with docker due to prior bad experiences.
**Explanation:** docker works very well for this setup. That way you don't have a bunch of web apps scattered around your machine, and you can force VPN traffic easier. However, I wanted to set this up in a comfortable way, and went without this option.

I installed it manually, and ran it under the wbollock user instead of Radarr for ease of use. It uses systemd like everything else.

**Note:** wondering what systemd is? It's a system wide method of managing services. When you make this systemd scripts I recommend, you need to run the following:
<pre>sudo systemctl daemon-reload     (this is when you've made a new systemd service file, or made a change to one)
  sudo systemctl start *SERVICE* (replace service with the actual service name)
  sudo systemctl status *SERVICE* (debug issues)
  sudo systemctl enable *SERVICE* (to run the service on every boot)
</pre>

This is the central location for everything. You import existing movies and find new ones. It'll even recommend movies for you! [The Radarr Wiki](https://github.com/Radarr/Radarr/wiki) was quite useful in setting this up. I did the .tar.gz and moved it /opt/Radarr. wbollock already had permission on this folder.

Radarr will have big red/orange status indicators when first setting it up. Really just follow these to get everything working (under System tab). Obviously the Radarr user will need permission to where your movies are.

**Explanation:** I ran Radarr under my normal local user. I had to make sure this user had access to my movie folders. In this case,
<code>ls -l</code> is your friend to diagnose any Radarr issue about "Permission denied".

### Importing Existing Movies

I had some trouble with this at first. I needed to restart Radarr and have it running on wbollock (local user) to correctly get it to update automatically and import movies. This is so Radarr won't download things you already have. It can even fetch better copies of movies you already had.

## Deluge

[Deluge](http://192.168.0.186:8112/)

Next I installed Deluge. Make sure to check [I know what you download](https://iknowwhatyoudownload.com/en/peer/) to avoid any love letters from ISP.

**Explanation:** That site will give a good guess at any torrent traffic on your IP. I live in an apartment complex and share my external IP with the whole building, so there were some entries there, but nothing I downloaded.

Deluge runs as systemd services *deluged* and *deluge-web*. Start both of these (see earlier note on systemd) and select 192.XXX as the connection(should be IP of the host you're on). Make sure to start the daemon (option in web GUI). Make sure to change the default password, which is deluge.

### Transmission

I briefly tried to use Transmission instead, but found the UI bad and settings didn't change like I'd like them to (settings.json kept resetting, I eventually got it to work). Plus it used sysint, gross.

### Installing Deluge

This [link](https://idroot.us/install-deluge-ubuntu-18-04-lts/) from idroot was super helpful when installing it. I'm pasting it here as this website seems like it'll go down anytime. One note is, ignore the <code>sudo gpasswd -a idroot deluge</code> when installing it.

**Explanation:** without doing further research, I'd guess idroot is a VPS provider or similar and their systems have an idroot user already.

Log into deluge and change the password.

**Note:** after *all* these services, go through the Radarr GUI and enable them. For example, Deluge is under "Download Clients". See this link to the [Radarr Wiki](https://github.com/Radarr/Radarr/wiki). The tooltips in the GUI are actually pretty good too.

Now you have Deluge and Radarr. As the above note suggests, link the two with Radarr's GUI. By default, downloads go to /home/deluge/Downloads/. Don't worry, Radarr will help us with this.

**Explanation:** I don't want my movies in /home/deluge/Downloads. Plex already points at /mnt/STR/Plex\ Library\, so I want my movies in there.

### idroot.us Install Deluge



<pre>
sudo apt-get update
sudo apt-get upgrade (why does every guide include this)

sudo add-apt-repository ppa:deluge-team/ppa
sudo apt install deluged deluge-webui

sudo adduser --system --group deluge

nano /etc/systemd/system/deluged.service
</pre>

Copy the following code into that service file.

<pre>
[Unit]
Description=Deluge Bittorrent Client Daemon
After=network-online.target

[Service]
Type=simple
User=deluge
Group=deluge
UMask=000

ExecStart=/usr/bin/deluged -d

Restart=on-failure

\# Configures the time to wait before service is stopped forcefully.
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
</pre>

<pre>
systemctl start deluged
systemctl enable deluged

nano /etc/systemd/system/deluge-web.service
</pre>


<pre>
[Unit]
Description=Deluge Bittorrent Client Web Interface
After=network-online.target

[Service]
Type=simple

User=deluge
Group=deluge
UMask=000

ExecStart=/usr/bin/deluge-web

Restart=on-failure

[Install]
WantedBy=multi-user.target
</pre>

<pre>
systemctl start deluge-web
systemctl enable deluge-web
</pre>

"Deluge will be available on HTTP port 8112 by default. Open your favorite browser and navigate to http://yourdomain.com:8112 or http://server-ip:8112.  The default password for deluge is deluge, better change it when you are first to login." 

I had an issue with Radarr user (wbollock) not being able to access the downloaded torrent files. ~~I'm lazy and just chmod 777'd the entire home directory of user deluge to overcome this.~~

**Addendum:** what actually worked for me was editing the <code>UMask</code> value in the above files. They're both 000. A better way to do this, on a system where you care about security (mine is locked down), is make appropirate UMask entries and have the Radarr user in the proper group. See this [Umask calculator](https://wintelguy.com/umask-calc.pl) for more details

**Note:** Radarr should warn you about the "Label" plugin in Deluge needing to be added. Simply go to Preferences -> Plugins to enable this.

## Jackett

[Jackett](http://192.168.0.186:9117/UI/Dashboard)

Now you have a torrent client! Great! But it has to receive torrent links to download. This is where [Jackett](https://github.com/Jackett/Jackett) comes in. 


### Installing Jackett
(Taken from the Github Link)

<pre>
Install as service

Download and extract the latest Jackett.Binaries.LinuxAMDx64.tar.gz release from the releases page

To install Jackett as a service, open a Terminal, cd to the jackett folder and run 

sudo ./install_service_systemd.sh 

You need root permissions to install the service. The service will start on each logon. You can always stop it by running systemctl stop jackett.service from Terminal. You can start it again it using systemctl start jackett.service. Logs are stored as usual under ~/.config/Jackett/log.txt and also in journalctl -u jackett.service.

</pre>

Easy. You don't actually initialize Jackett itself in Radarr. Instead, you do each tracker individually. To start, click the big green "Add Indexer" button. You can start with common ones like The Pirate Bay. Make sure to hit "Test" to, well, test it.

**Note:** I configured each tracker individually, in Radarr and Sonarr. Some bold users may just want to use every damn tracker there. Great! No setup! However, Radarr lists some issues with this in the wiki. In short, it makes setup time null, but may hurt you down the line:

Aggregate indexers
A special "all" indexer is available at /api/v2.0/indexers/all/results/torznab. It will query all configured indexers and return the combined results.

If your client supports multiple feeds it's recommended to add each indexer directly instead of using the all indexer. Using the all indexer has no advantages (besides reduced management overhead), only disadvantages:
<pre>
you lose control over indexer specific settings (categories, search modes, etc.)
mixing search modes (IMDB, query, etc.) might cause low quality results
indexer specific categories (>= 100000) can't be used.
slow indexers will slow down the overall result
total results are limited to 1000
To get all Jackett indexers including their capabilities you can use t=indexers on the all indexer. To get only configured/unconfigured indexers you can also add configured=true/false as query parameter.
</pre>
<pre>
Adding a Jackett indexer in Sonarr or Radarr

Go to Settings > Indexers > Add > Torznab > Custom.

Click on the indexers corresponding  button and paste it into the Sonarr/Radarr URL field.

For the API key use **REDACTED**. (grab this unique identifier from the main page of Jackett)

Configure the correct category IDs via the (Anime) Categories options. See the Jackett indexer configuration for a list of supported categories.
</pre>

One hiccup I had was doing the Radarr instructions before adding an indexer. Then you get the "Copy Torznab Feed" button. Don't just guess at the URL like I did.


Well, hell ya, we have some indexes running. Make sure to hit "Test" on the Radarr side too.

Now we're cooking. Make sure to check the logs for Radarr to avoid any issues. This is all you need, good hunting!


## Sonarr

[Sonarr](http://192.168.0.186:8989/)

Sonarr is the original fork of Radarr, and virtually identical to setup. I followed the wiki to install it. One thing special, is I made a systemd service copied from Radarr, but edited the <code>ExecStart</code>. Here it is:

<pre>
[Unit]
Description=Sonarr Daemon
After=syslog.target network.target

[Service]
# Change the user and group variables here.
User=wbollock
Group=wbollock

Type=simple

# Change the path to Radarr or mono here if it is in a different location for you.
ExecStart=/usr/bin/mono --debug /opt/NzbDrone/NzbDrone.exe -nobrowser
TimeoutStopSec=20
KillMode=process
Restart=on-failure

# These lines optionally isolate (sandbox) Radarr from the rest of the system.
# Make sure to add any paths it might use to the list below (space-separated).
#ReadWritePaths=/opt/Radarr /path/to/movies/folder
#ProtectSystem=strict
#PrivateDevices=true
#ProtectHome=true

[Install]
WantedBy=multi-user.target
</pre>

**Note:** when adding existing TV Shows, the folder has to be readable (and writeable?) by the user running Sonarr.


## Ongoing Issues

One problem I am running into is /home/deluge/Downloads is located on my small OS SSD. Downloads are hard linked to my larger storage partition, so my plan is to:

* Periodically check free space on OS SSD
* If free space is not high, delete last 10 files by date in /home/deluge/Downloads.
* This allows me to seed somewhat while keeping this drive clean.

In the mean time, I just rm -rf my home/deluge/downloads folder when I need to.
