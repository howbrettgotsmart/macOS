#!/bin/bash

###############################################
# This script will provide temporary admin    #
# rights to a standard user right from self   #
# service. First it will grab the username of #
# the logged in user, elevate them to admin   #
# and then create a launch daemon that will   #
# count down from 30 minutes and then create  #
# and run a secondary script that will demote #
# the user back to a standard account. The    #
# launch daemon will continue to count down   #
# no matter how often the user logs out or    #
# restarts their computer.                    #
###############################################

#############################################
# find the logged in user and let them know #
#############################################

consoleUser=$(ls -l /dev/console | cut -d " " -f4)
currentUser=$(who | awk '/console/{print $1}')
if [[ "$consoleUser" == "root" ]];then
  echo "$consoleUser is showing as ROOT, using currentUser instead"
else
  echo "$consoleUser is not showing as ROOT, setting currentUser to $consoleUser"
  currentUser=$consoleUser
fi
echo "Current user is $currentUser"

osascript -e 'display dialog "You will now be granted administrative rights for 30 minutes. Please be careful and only use this privilege when asked by IT or for valid company business." buttons {"I Understand. Make me an admin, please!"} default button 1'

#########################################################
# write a daemon that will let you remove the privilege #
# with another script and chmod/chown to make 			#
# sure it'll run, then load the daemon					#
#########################################################

#Create the plist
cat << 'EOF' > /Library/LaunchDaemons/removeAdmin.plist
<?xml version="1.0" encoding="UTF-8"?> 
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> 
<plist version="1.0"> 
   <dict> 
       <key>Label</key>
       <string>removeAdmin</string>
       <key>ProgramArguments</key>
          <array>
             <string>/bin/sh</string>
             <string>/Library/Application Support/JAMF/removeAdminRights.sh</string>
          </array>
      <key>StartInterval</key>
      <integer>1800</integer>
      <key>RunAtLoad</key>
      <true/>
   </dict>
</plist>
EOF
