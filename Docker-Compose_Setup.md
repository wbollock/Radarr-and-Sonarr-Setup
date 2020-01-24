# Yet Another Radarr and Sonarr Guide - Docker Conversion




Shortly after posting my last guide, I was quickly informed how much better this setup would be with docker. Well, here I am, trying to get one monolithic docker compose file for the services previously installed:

Radarr

Sonarr

Deluge

Jackett

This guide can also be used for first time setups of these services, just ignore all the backing up and restoring. You might've seen my [previous guide](https://github.com/wbollock/Radarr-and-Sonarr-Setup/blob/master/Dockerless_Setup.md).

Written for Ubuntu 18.04. One caveat is that I have had little experience with docker before this, completing the tutorial around a year ago and not touching it since.


## Installing Docker and Docker compose

[Source 1 (Docker)](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04#step-1-%E2%80%94-installing-docker)

[Source 2 (Docker Compose)](https://linuxize.com/post/how-to-install-and-use-docker-compose-on-ubuntu-18-04/)

Now you should have Docker and Docker Compose installed.

Test with:

<code>docker -v</code>

<code>docker-compose --version</code>

## Backup our Existing Setups

Sonarr and Radarr should really be backed up first. I put the most time into those, such as importing movies and fixing TV shows, plus all the custom settings. 

To backup, go to System -> Backups. Download this file on your main machine, or copy the link address and use

<code>wget <INSERT LINK\></code>

to download this on your server.

Download the latest copies of both backups.

Backing up Jackett didn't see to work for me. The Content folder didn't match any of the docker configs. Because it was so little to configure, I just set it up from scratch again. 

~~I don't feel it's worth to bother backing up Jackett, as I only had 6 indexers. I also couldn't find a good way to backup Jackett.~~

~~To backup Jackett, cp -r the /home/<USER>/Jackett/Content folder, or wherever it is on your machine~~ 


## Making our Docker Compose File

Timezone: America/New_York

Find your timezone [here](https://docs.diladele.com/docker/timezones.html).

Here is a template for all services. Radarr, Sonarr, Jackett, Deluge:

<pre>
version: '3'
services:
 radarr:
  container_name: radarr
  restart: unless-stopped
  ports:
   - 7878:7878
  volumes:
    - <\path to data>:/config
    - <\path/to/movies>:/movies
    - <\path/to/downloadclient-downloads>:/downloads
  environment:
   - PUID=1000
   - PGID=1000
   - TZ=America/New_York
  image: linuxserver/radarr
 
 sonarr:
  container_name: sonarr
  restart: unless-stopped
  ports:
   - 8989:8989
  volumes:
    - <\path to data>:/config
    - <\path/to/tv>:/tv
    - <\path/to/downloadclient-downloads>:/downloads
  environment:
   - PUID=1000
   - PGID=1000
   - TZ=America/New_York
  image: linuxserver/sonarr
 
 jackett:
  container_name: jackett
  restart: unless-stopped
  ports:
   - 9117:9117
  volumes:
   - <\path to data>:/config
  environment:
   - PUID=1000
   - PGID=1000
   - TZ=America/New_York
  image: linuxserver/jackett

  deluge:
    image: linuxserver/deluge
    container_name: deluge
    network_mode: host
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - UMASK_SET=000 #optional
      - DELUGE_LOGLEVEL=error #optional
    volumes:
      - <\/path/to/deluge/config>:/config
      - <\/path/to/your/downloads>:/downloads
    restart: unless-stopped
</pre>

All we need to do is fill in the blanks (meaning all the <path/to/configs>).


### Username

First, get the PUID and PGID (unique identifiers) of the user you want to use these services with. 

<code>id <username\></code>

<pre>
uid=1000(wbollock) gid=1000(wbollock) groups=1000(wbollock),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),109(lxd),114(lpadmin),115(sambashare),128(deluge)
</pre>

So, here they are both 1000. Substitute the username you wish to run these services with. Permissions are important in this case, and <code>ls -l</code> is your friend.

### Directories

Now we are onto the directories. 

I want my configuration files in /etc/. We need to make a configuration directory for each service.

For example, our radarr container needs these values:

<pre>
volumes:
    - <\path to data>:/config
    - <\path/to/movies>:/movies
    - <\path/to/downloadclient-downloads>:/downloads
</pre>

You need to repeat this step for every service. Here's a one liner of a good setup.

<code>sudo mkdir /etc/radarr/ /etc/sonarr/ /etc/jackett/ /etc/deluge/</code>

Now fill in the "<\path to data>" with the above directories.

Example:
<pre>
volumes:
    - /etc/radarr/:/config
</pre>


Do the same with your "Movies" and "TV" directories.
<pre>
/mnt/STR/Plex Library/Movies:/movies
</pre>

The section after the colon, "/movies", is what docker associates with the long path before it. It's a psuedo symlink.

Now, the deluge downloads folder is important. The other services will use it. I wanted this on my large storage array, so I chose:
<code>/mnt/STR/deluge/</code>

Fill in the section <code><path/to/downloadclient-downloads></code> with the above.

I also wanted to make sure my user had access to all the config directories. 

<code>sudo chown -R wbollock:wbollock /etc/radarr/ /etc/deluge/ /etc/sonarr/ /etc/jackett</code>

## Almost There

Now we need to stop the existing services, as they both can't be bound to one port (there are other reasons too).

<code>sudo systemctl stop radarr.service jackett.service deluged.service deluge-web.service sonarr.service</code>

Your completed docker-compose file should look something like this:

<pre>
version: '3'
services:
 radarr:
  container_name: radarr
  restart: unless-stopped
  ports:
   - 7878:7878
  volumes:
    - /etc/radarr/:/config
    - /mnt/STR/Plex Library/Movies:/movies
    - /mnt/STR/deluge/:/downloads
  environment:
   - PUID=1000
   - PGID=1000
   - TZ=America/New_York
  image: linuxserver/radarr
 
 sonarr:
  container_name: sonarr
  restart: unless-stopped
  ports:
   - 8989:8989
  volumes:
    - /etc/sonarr/:/config
    - /mnt/STR/Plex Library/TV Shows:/tv
    - /mnt/STR/deluge/:/downloads
  environment:
   - PUID=1000
   - PGID=1000
   - TZ=America/New_York
  image: linuxserver/sonarr
 
 jackett:
  container_name: jackett
  restart: unless-stopped
  ports:
   - 9117:9117
  volumes:
   - /etc/Jackett/:/config
  environment:
   - PUID=1000
   - PGID=1000
   - TZ=America/New_York
  image: linuxserver/jackett
 
 deluge:
  container_name: deluge
  restart: unless-stopped
  network_mode: host
  environment:
   - PUID=1000
   - PGID=1000
   - TZ=America/New_York
   - UMASK_SET=000 
   - DELUGE_LOGLEVEL=error 
  volumes:
   - /etc/deluge/:/config
   - /mnt/STR/deluge/:/downloads
  image: linuxserver/deluge
</pre>

Check your compose file with <code>docker-compose config</code>. Mine is located in /home/wbollock/Radarr-Stack. Make sure to name the file docker-compose.yml.

**Important:** yml uses spaces, NOT tabs. It's very particular about every single indent. Make sure to line everything up properly, and possibly use an [online yml parser](http://yaml-online-parser.appspot.com/) to help.

You can only run docker-compose commands when in the same directory with your yml file. Or use the --file parameter to specify where the yml file is, if you're outside of that directory.


Finally, once you get a valid output and no errors from the above command, we're ready to create (it'll spit out the error in an obvious way if you have any). Run this in the folder with docker-compose.yml

<code>sudo docker-compose up -d</code>

**Explanation:** the -d is to run in detached mode, so we can use the terminal normally while it runs. Similar to &.


**Note:** one error I ran into was that a process, mono, was already listening on 8989. I took down my docker compose stack with <code>sudo docker-compose down</code>, and ran <code> sudo netstat -tulpn | grep :8989</code> to find out what was listening on that port. It was mono, with PID 5649. I ran <code>sudo kill 5649</code> to remove it from that port.

To see your processes run, type <code>docker-compose ps</code>. Make sure you see every service there. 

## Restoring our Settings

Now we should have a clean version of each service. Visit those services and make sure they all work.

Check out some of the files in /etc/radarr/. A lot of them are the same ones we backed up! We need to override those files with our backup.

First, stop all running containers.

<code>sudo docker-compose stop</code>

Then navigate to your radarr_backup.zip. Unzip it. Remove all files in /etc/radarr/ and /etc/sonarr/. This includes any .pids, config.xmls, nzbdrone.db*. Really everything important except for logs, if you care.

Move all the files (config.xml, nzbdrone.db, and nzbdrone.db-journal) to /etc/radarr/. These are unzipped from our .zip backups.


Then run <code>sudo docker-compose -d</code> from your original docker compose folder.

All your Radarr and Sonarr settings should be saved! Do <code>sudo docker-compose logs</code> if you have any issues.

To access your services, go to YOUR IP.XX.XX:<\PORT SET IN DOCKER>.

For example, running <code>sudo docker-compose ps</code>:

<pre>
 Name     Command   State           Ports

deluge    /init     Up
jackett   /init     Up      0.0.0.0:9117->9117/tcp
radarr    /init     Up      0.0.0.0:7878->7878/tcp
sonarr    /init     Up      0.0.0.0:8989->8989/tcp
</pre>

For some reason, deluge doesn't show up, but it's port is 8112. If you're using <code>ufw</code>, make sure to run <code>sudo ufw allow PORT</code> to get by your firewall.





## Reconfiguring a few things

Sadly this isn't all automated. For example, my Sonarr/Radarr couldn't collect to deluge. I had to change "localhost" in the connection settings to 192.168.0.186 (IP you connect to deluge with). 

Also, your apps will no longer understand the long root directories, /mnt/STR/Plex Library/Movies. Instead, change the path to /movies/ or /tv/, respectfully. I updated my library after doing this.

Also, deluge will need it's download folder to change. In preferences, change that to /downloads.

Lastly, just re-do your indexers in Jackett, and connect them to Radarr and Sonarr. All I had to change was my new API key - everything else stayed the same.

## Missing Root Folder Error

After verifying your /movies/ or /tv/ folders work, and you want the clear the Root Folder Error, go the Series or Movies editor. Select all entries, or just one to test (safer), and select a different root folder on the bottom bar. Then hit save. The error will go away after all pieces of media are updated (and the service is restarted).


## A reminder - some useful docker-compose commands
<pre>
 docker-compose

  Run and manage multi container docker applications.
  More information: https://docs.docker.com/compose/reference/overview/.

  - List all running containers:
    docker-compose ps

  - Create and start all containers in the background using a docker-compose.yml file from the current directory:
    docker-compose up -d

  - Start all containers, rebuild if necessary:
    docker-compose up --build

  - Start all containers using an alternate compose file:
    docker-compose --file path/to/file up

  - Stop all running containers:
    docker-compose stop

  - Stop and remove all containers, networks, images, and volumes:
    docker-compose down --rmi all --volumes

  - Follow logs for all containers:
    docker-compose logs --follow
</pre>
(Taken from [tldr](https://github.com/tldr-pages/tldr))

Everything else should work just fine! I hope you enjoyed.
