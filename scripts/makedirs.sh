#!/bin/bash

users=( "deluge" "")

for user in $username
do
       
       useradd $user
       echo $password | passwd --stdin $user
done

# Used for config folders

dirs=( "/opt/deluge" "/opt/radarr" "/opt/sonarr" "/opt/bazarr" "/opt/4K_radarr" "/opt/4K_bazarr" "/opt/prowlarr" "/opt/overseerr" )
users=( "deluge:media" "radarr:media" "sonarr:media" "bazarr:media" "radarr4k:media" "bazarr4k:media" "prowlarr:media" "overseerr:media" )

# make dirs and set perms
for jawn in "${!dirs[@]}"; do
	echo "Creating ${dirs[jawn]}"
	mkdir -p ${dirs[jawn]}
	echo "Setting perms for ${users[jawn]} on ${dirs[jawn]}"
	chown -R ${users[jawn]} ${dirs[jawn]}
done
