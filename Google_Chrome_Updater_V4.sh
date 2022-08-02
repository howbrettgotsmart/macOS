#!/bin/sh

#############################################################################################################################
#checks Chrome version on web, and version on Mac
#if version on web is newer it will download and install
##############################################################################################################################

## Set the Variables
logpath="/var/log/LOGFolder/"
chromePath="/Applications/Google Chrome"
bddy="/usr/libexec/PlistBuddy"
tgt="/Applications/Google Chrome.app/Contents/Info.plist"
instld=$($bddy -c "Print :CFBundleShortVersionString" "$tgt")
url="https://dl.google.com/chrome/mac/stable/accept_tos%3Dhttps%253A%252F%252Fwww.google.com%252Fintl%252Fen_ph%252Fchrome%252Fterms%252F%26_and_accept_tos%3Dhttps%253A%252F%252Fpolicies.google.com%252Fterms/googlechrome.pkg"
urlcheck=$(curl -Is https://dl.google.com/chrome/mac/stable/accept_tos%3Dhttps%253A%252F%252Fwww.google.com%252Fintl%252Fen_ph%252Fchrome%252Fterms%252F%26_and_accept_tos%3Dhttps%253A%252F%252Fpolicies.google.com%252Fterms/googlechrome.pkg | head -n 1 | awk '{print $2}')
# m1 url=https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg

#Ensure logFile can be written
if [ ! -d "${logpath}" ]; then
  mkdir "${logpath}"
fi

##Create the logFile
logFile="${logpath}"installChrome.log



#Get the current local Chrome version
echo $(date) "Installed Chrome version is "$instld" "
echo $(date) "Installed Chrome version is "$instld" " >> $logFile

#Get the current online version
verchk=$(curl -s https://omahaproxy.appspot.com/history|awk -F',' '/mac,stable/{print $3; exit}')
echo $(date) "Current available Chrome version is "$verchk" "
echo $(date) "Current available Chrome version is "$verchk" " >> $logFile

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# FUNCTIONS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## Download and install Chrome
installChrome () {
# Make temp folder for downloads
echo $(date) "Creating the /tmp folder"
echo $(date) "Creating the /tmp folder" >> $logFile
mkdir "/tmp/googlechrome"

# Change the directory
echo $(date) "CD'n to the /tmp folder" 
echo $(date) "CD'n to the /tmp folder" >> $logFile
cd "/tmp/googlechrome"

echo $(date) "Downloading Current Stable "$verchk" "
echo $(date) "Downloading Current Stable "$verchk" " >> $logFile
curl -L -o "/tmp/googlechrome/googlechrome.pkg" ${url}

#Install current Chrome version
/usr/sbin/installer -pkg googlechrome.pkg -target /
echo $(date) "Installing Chrome"
echo $(date) "Installing Chrome" >> $logFile
sleep 10

#Remove Chrome from /tmp
rm -rf "/tmp/googlechrome"
sleep 5
echo $(date) "Download deleted"
echo $(date) "Download deleted" >> $logFile
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# APPLICATION
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#Check if the Google Chrome update URL is up
	if [ "$urlcheck" == "200" ]; then
	echo $(date) "Google Chrome Updater Site is Available"
	echo $(date) "Google Chrome Updater Site is Available" >> /var/log/GSAlog
else
	echo $(date) "Google Chrome Updater Site is Not Available, Exiting"
	echo $(date) "Google Chrome Updater Site is Not Available, Exiting" >> /var/log/GSAlog
	exit 1
fi

#Check if Chrome is installed, if not install it.
if [ ! -f "/Applications/Google Chrome.app/Contents/Info.plist" ]; then
	echo $(date) "Chrome is not installed. Installing Chrome"
	echo $(date) "Chrome is not installed. Installing Chrome" >> $logFile
	installChrome
	echo $(date) "Installed Chrome version is "$instld" "
	echo $(date) "Installed Chrome version is "$instld" " >> $logFile
else
	echo $(date) "Chrome is installed and version is "$instld" "
	echo $(date) "Chrome is installed and version is "$instld" " >> $logFile
fi

sleep 10

#Check Chrome version.. Update if not on correct version
if [[ "$instld" == "$verchk" ]]; then
	echo $(date) "Chrome is Current"
	echo $(date) "Chrome is Current" >> $logFile
else
	echo $(date) "Chrome is not Current.. Updating version"
	echo $(date) "Chrome is not Current.. Updating version" >> $logFile
	installChrome
	echo $(date) "Installed Chrome version "$instld" "
	echo $(date) "Installed Chrome version "$instld" " >> $logFile
fi
exit 0
