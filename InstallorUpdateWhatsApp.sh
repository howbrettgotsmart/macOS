#!/bin/zsh
#  __    __     ______     _____     ______        ______     __  __        ______     ______     ______     ______   ______  
# /\ "-./  \   /\  __ \   /\  __-.  /\  ___\      /\  == \   /\ \_\ \      /\  == \   /\  == \   /\  ___\   /\__  _\ /\__  _\ 
# \ \ \-./\ \  \ \  __ \  \ \ \/\ \ \ \  __\      \ \  __<   \ \____ \     \ \  __<   \ \  __<   \ \  __\   \/_/\ \/ \/_/\ \/ 
#  \ \_\ \ \_\  \ \_\ \_\  \ \____-  \ \_____\     \ \_____\  \/\_____\     \ \_____\  \ \_\ \_\  \ \_____\    \ \_\    \ \_\ 
#   \/_/  \/_/   \/_/\/_/   \/____/   \/_____/      \/_____/   \/_____/      \/_____/   \/_/ /_/   \/_____/     \/_/     \/_/ 
#                                                                                                                            

# Created by Brett Thomason - Kills WhatsApp and updates to latest version.  


# Function to check if WhatsApp is installed
check_whatsapp_installed() {
    if [ -d "/Applications/WhatsApp.app" ]; then
        return 0  # WhatsApp is installed
    else
        return 1  # WhatsApp is not installed
    fi
}

# Function to check if WhatsApp is running
check_whatsapp_running() {
    if pgrep -x "WhatsApp" >/dev/null; then
        return 0  # WhatsApp is running
    else
        return 1  # WhatsApp is not running
    fi
}

# Function to quit WhatsApp
quit_whatsapp() {
    if check_whatsapp_running; then
        echo "Quitting WhatsApp..."
        osascript -e 'tell application "WhatsApp" to quit'
        sleep 2  # Allow time for WhatsApp to quit
    fi
}

# Function to download and install the latest version of WhatsApp
install_whatsapp() {
    local download_url="https://web.whatsapp.com/desktop/mac_native/release/?configuration=Release"
    local download_file="/tmp/WhatsApp.dmg"
    local mount_point="/Volumes/WhatsApp Installer"

    echo "Downloading WhatsApp..."
    curl -L "$download_url" -o "$download_file"

    # Check if the download was successful
    if [ $? -eq 0 ]; then
        echo "Download successful. Installing WhatsApp..."

        echo "Mounting disk image..."
        hdiutil attach "$download_file"

        # List contents of mounted volume for debugging
        echo "Listing contents of mounted volume..."
        ls "$mount_point"

        echo "Copying WhatsApp to Applications..."
        cp -R "$mount_point/WhatsApp.app" "/Applications/"

        echo "Unmounting disk image..."
        hdiutil detach "$mount_point"

        echo "Cleaning up..."
        rm "$download_file"

        echo "WhatsApp installed successfully!"
    else
        echo "Download failed. Please check your internet connection and try again."
        exit 1
    fi
}

# Main script
if check_whatsapp_installed; then
    quit_whatsapp
    install_whatsapp
    open -a "WhatsApp"
else
    echo "WhatsApp is not installed. Installing WhatsApp..."
    install_whatsapp
    open -a "WhatsApp"
fi
