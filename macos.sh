#!/usr/bin/env bash

# script-template.sh https://gist.github.com/m-radzikowski/53e0b39e9a59a1518990e76c2bff8038 by Maciej Radzikowski
# MIT License https://gist.github.com/m-radzikowski/d925ac457478db14c2146deadd0020cd
# https://betterdev.blog/minimal-safe-bash-script-template/

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

# shellcheck disable=SC2034
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# This ensures that on Mac with ARMs / Apple Silicon the do script can do its job
# and refer to things like brew without reloading or absolute paths as they are
# typically not available on the $PATH on a blank/stock macOS installation.
BREW_PREFIX="/opt/homebrew"
if sysctl -n machdep.cpu.brand_string | grep -q 'Intel' ; then
	BREW_PREFIX="/usr/local"
fi

export PATH="${BREW_PREFIX}/bin:${PATH:-}"

usage() {
	cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]
Configure macos.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-f, --fore      Apply without confirmation
EOF
	exit
}

cleanup() {
	trap - SIGINT SIGTERM ERR EXIT
	# script cleanup here
}

setup_colors() {
	if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
		# shellcheck disable=SC2034
		NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
	else
		# shellcheck disable=SC2034
		NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
	fi
}

msg() {
	echo >&2 -e "${1-}"
}

die() {
	local msg=${1}
	local code=${2-1} # default exit status 1
	msg "${msg}"
	exit "${code}"
}

parse_params() {
	# default values of variables set from params
	force=0

	while :; do
		case "${1-}" in
		-h | --help) usage ;;
		-v | --verbose) set -x ;;
		-f | --force) force=1 ;;
		--no-color) NO_COLOR=1 ;;
		-?*) die "Unknown option: $1" ;;
		*) break ;;
		esac
		shift
	done

	# check required params and arguments
	#[[ -z "${param-}" ]] && die "Missing required parameter: param"
	#[[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

	return 0
}

parse_params "$@"
setup_colors

# script logic here
if [[ -z "${force-}" ]] || [[ "${force-}" == 0 ]]; then
	msg "${RED}This will modify macOS system settings and applications.${NOFORMAT}"
	msg ""
	msg "${ORANGE}Full Disk Access is required for this, see: https://support.apple.com/en-us/HT210595${NOFORMAT}"
	msg "${ORANGE}If you run into any trouble applying the settings do the following:${NOFORMAT}"
	msg "${ORANGE}Add your Terminal App to Full Disk Access via ' > System Settings > Privacy & Security > Full Disk Access > +' ${NOFORMAT}"
	msg "${ORANGE}Please restart your Terminal afterwards to apply the changes.${NOFORMAT}"
	msg ""
	msg "${RED}Only proceed if you read the script contents and are fine with the settings.${NOFORMAT}"
	read -rp "Are you sure? (y/n) " -n 1
	echo ""
	if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
		die "Cancelled configuration."
	fi
fi

# Try to access a file that requires Full Disk Access before continuing
# everything up to this point doesn't strictly speaking require this but e.g. the defaults domain com.apple.Safari is sandboxed and
# requires the Terminal to have access upfront.
if ! sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
	'select client from access where auth_value and service = "kTCCServiceSystemPolicyAllFiles"' &>/dev/null; then
	die "Full Disk Access not granted to Terminal.app or iTerm; cannot continue setting preferences"
fi

msg "${GREEN}Prepare configuration. Will ask for sudo password to make necessary changes.${NOFORMAT}"

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `macos.sh` has finished
while true; do
	sudo -n true
	sleep 60
	kill -0 "$$" || exit
done 2>/dev/null &

###############################################################################
# General UI/UX                                                               #
###############################################################################

msg "${GREEN}Configuring General UI/UX.${NOFORMAT}"

# Set computer name (as done via System Preferences → Sharing)
#sudo scutil --set ComputerName "0x6D746873"
#sudo scutil --set HostName "0x6D746873"
#sudo scutil --set LocalHostName "0x6D746873"
#sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "0x6D746873"

# Disable the sound effect / chime on boot / startup
# TODO find out how to automate "System Settings -> Sound -> Play sound on startup" setting instead
# See also https://discussions.apple.com/thread/253124369
#sudo nvram SystemAudioVolume=" "

# Change what happens when you open the lid of your MacBook
# See:
# - https://support.apple.com/en-us/120622
# - https://eclecticlight.co/2025/02/03/how-to-change-lid-behaviour-on-macbook-air-and-pro/
# - https://www.macrumors.com/2025/01/30/apple-keep-mac-turning-on-lid-open/
# - https://blog.fefe.de/?ts=99620db9
# %00 = To prevent startup when opening the lid or connecting to power
# %01 = To prevent startup only when opening the lid
# %02 = To prevent startup only when connecting to power
# Run sudo nvram -d BootPreference to reset to default behavior
#sudo nvram BootPreference=%01
# Intel Only, do not use on Apple Silicon
# %00 = To prevent startup only when opening the lid
# %03 = Restore default behavior
#sudo nvramn AutoBoot=%00

# Disable transparency in the menu bar and elsewhere on Yosemite
# cannot be enabled anymore this way on macOS Ventura, see https://github.com/mathiasbynens/dotfiles/issues/1027
#defaults write com.apple.universalaccess reduceTransparency -bool true

# Set highlight color to green
#defaults write NSGlobalDomain AppleHighlightColor -string "0.764700 0.976500 0.568600"

# Set sidebar icon size to medium
# 1 = small
# 2 = medium (default)
# 3 = large
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# Always show scrollbars
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"
# Possible values: `WhenScrolling`, `Automatic` and `Always`

# Disable the over-the-top focus ring animation
#defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false

# Adjust toolbar title rollover delay
#defaults write NSGlobalDomain NSToolbarTitleViewRolloverDelay -float 0

# Disable smooth scrolling
# (Uncomment if you’re on an older Mac that messes up the animation)
#defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false

# Increase window resize speed for Cocoa applications
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable Close windows when quitting an app
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool true

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Remove duplicates in the “Open With” menu (also see `lscleanup` alias)
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# Display ASCII control characters using caret notation in standard text views
# Try e.g. `cd /tmp; unidecode "\x{0000}" > cc.txt; open -e cc.txt`
defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true

# Disable Resume system-wide
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# Set Help Viewer windows to non-floating mode
defaults write com.apple.helpviewer DevMode -bool true

# Fix for the ancient UTF-8 bug in QuickLook (https://mths.be/bbo)
# Commented out, as this is known to cause problems in various Adobe apps :(
# See https://github.com/mathiasbynens/dotfiles/issues/237
#echo "0x08000100:0" > ~/.CFUserTextEncoding

# Reveal IP address, hostname, OS version, etc. when clicking the clock
# in the login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Disable Notification Center and remove the menu bar icon
#launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null

# Disable automatic capitalization as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Set a custom wallpaper image. `DefaultDesktop.jpg` is already a symlink, and
# all wallpapers are in `/Library/Desktop Pictures/`. The default is `Wave.jpg`.
#rm -rf ~/Library/Application Support/Dock/desktoppicture.db
#sudo rm -rf /System/Library/CoreServices/DefaultDesktop.jpg
#sudo ln -s /path/to/your/image /System/Library/CoreServices/DefaultDesktop.jpg

# Set digital clock (default)
defaults write com.apple.menuextra.clock IsAnalog -bool false

# Disable Flash the time separators (Default)
defaults write com.apple.menuextra.clock FlashDateSeparators -bool false

# Show AM / PM when the time format allows
defaults write com.apple.menuextra.clock ShowAMPM -bool true

# Change the Clock in the Menu Bar to show
# Show the Date
# 0 = when space allows (default)
# 1 = always
# 2 = never
defaults write com.apple.menuextra.clock ShowDate -int 0
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.menuextra.clock ShowSeconds -bool true

##############################################################################
# Security                                                                   #
##############################################################################
# Based on:
# https://github.com/drduh/macOS-Security-and-Privacy-Guide
# https://benchmarks.cisecurity.org/tools2/osx/CIS_Apple_OSX_10.12_Benchmark_v1.0.0.pdf

msg "${GREEN}Configuring Security.${NOFORMAT}"

# Enable firewall. Possible values:
#   0 = off
#   1 = on for specific sevices
#   2 = on for essential services
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1

# Enable stealth mode
# Source: https://support.apple.com/kb/PH18642
#sudo defaults write /Library/Preferences/com.apple.alf stealthenabled -int 1

# Enable firewall logging
#sudo defaults write /Library/Preferences/com.apple.alf loggingenabled -int 1

# Do not automatically allow signed software to receive incoming connections
#sudo defaults write /Library/Preferences/com.apple.alf allowsignedenabled -bool false

# Log firewall events for 90 days
#sudo perl -p -i -e 's/rotate=seq compress file_max=5M all_max=50M/rotate=utc compress file_max=5M ttl=90/g' "/etc/asl.conf"
#sudo perl -p -i -e 's/appfirewall.log file_max=5M all_max=50M/appfirewall.log rotate=utc compress file_max=5M ttl=90/g' "/etc/asl.conf"

# Reload the firewall
# (uncomment if above is not commented out)
#launchctl unload /System/Library/LaunchAgents/com.apple.alf.useragent.plist
#sudo launchctl unload /System/Library/LaunchDaemons/com.apple.alf.agent.plist
#sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist
#launchctl load /System/Library/LaunchAgents/com.apple.alf.useragent.plist

# Disable IR remote control
#sudo defaults write /Library/Preferences/com.apple.driver.AppleIRController DeviceEnabled -bool false

# Turn Bluetooth off completely
#sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0
#sudo launchctl unload /System/Library/LaunchDaemons/com.apple.blued.plist
#sudo launchctl load /System/Library/LaunchDaemons/com.apple.blued.plist

# Disable wifi captive portal
#sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false

# Disable remote apple events
#sudo systemsetup -setremoteappleevents off

# Disable remote login
#sudo systemsetup -setremotelogin off

# Disable wake-on modem
#sudo systemsetup -setwakeonmodem off
#sudo pmset -a ring 0

# Disable wake-on LAN
#sudo systemsetup -setwakeonnetworkaccess off
#sudo pmset -a womp 0

# Disable file-sharing via AFP or SMB
#sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
#sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist

# Display login window as name and password
#sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true

# Do not show password hints
#sudo defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0

# Disable guest account login
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

# Automatically lock the login keychain for inactivity after 6 hours
#security set-keychain-settings -t 21600 -l ~/Library/Keychains/login.keychain

# Destroy FileVault key when going into standby mode, forcing a re-auth.
# Source: https://web.archive.org/web/20160114141929/http://training.apple.com/pdf/WP_FileVault2.pdf
#sudo pmset destroyfvkeyonstandby 1

# Enable secure virtual memory
#sudo defaults write /Library/Preferences/com.apple.virtualMemory UseEncryptedSwap -bool true

# Disable Bonjour multicast advertisements
#sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool true

# Disable the crash reporter
#defaults write com.apple.CrashReporter DialogType -string "none"

# Disable diagnostic reports
#sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.SubmitDiagInfo.plist

# Log authentication events for 90 days
#sudo perl -p -i -e 's/rotate=seq file_max=5M all_max=20M/rotate=utc file_max=5M ttl=90/g' "/etc/asl/com.apple.authd"

# Log installation events for a year
#sudo perl -p -i -e 's/format=bsd/format=bsd mode=0640 rotate=utc compress file_max=5M ttl=365/g' "/etc/asl/com.apple.install"

# Increase the retention time for system.log and secure.log
#sudo perl -p -i -e 's/\/var\/log\/wtmp.*$/\/var\/log\/wtmp   \t\t\t640\ \ 31\    *\t\@hh24\ \J/g' "/etc/newsyslog.conf"

# Keep a log of kernel events for 30 days
#sudo perl -p -i -e 's|flags:lo,aa|flags:lo,aa,ad,fd,fm,-all,^-fa,^-fc,^-cl|g' /private/etc/security/audit_control
#sudo perl -p -i -e 's|filesz:2M|filesz:10M|g' /private/etc/security/audit_control
#sudo perl -p -i -e 's|expire-after:10M|expire-after: 30d |g' /private/etc/security/audit_control

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable disk image verification
#defaults write com.apple.frameworks.diskimages skip-verify -bool true
#defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
#defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

msg "${GREEN}Configuring Trackpad, mouse, keyboard, Bluetooth accessories, and input.${NOFORMAT}"

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool false
defaults write com.apple.AppleMultitouchTrackpad Clicking -int 0
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 0
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 0

# Trackpad: map bottom right corner to right-click
#defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
#defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
#defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
#defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Disable “natural” (Lion-style) scrolling
#defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
# 0 = disabled (default)
# 2 = enabled
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2

# Choose what happens when you press the Fn or 🌐︎ key on the keyboard.
# 0 = Nothing (default)
# 1 = Switches between keyboard layouts for writing in other languages (known as input sources).
# 2 = Opens the Character Viewer for entering emoji, symbols, and more.
# 3 = Starts dictation when you press the key twice (you may be asked to enable dictation first).
defaults write com.apple.HIToolbox AppleFnUsageType -int "2"

# Change the behavior of the function keys. The two possible options are:
# false = Use F1, F2, etc. as special keys (default)
# true = Use F1, F2, etc. as standard function keys
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

# Use scroll gesture with the Ctrl (^) modifier key to zoom
# cannot be enabled anymore this way on macOS Ventura, see https://github.com/mathiasbynens/dotfiles/issues/1027
#defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool false
#defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144
# Follow the keyboard focus while zoomed in
#defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

# Disable press-and-hold for keys in favor of key repeat in case of Terminal
defaults write com.apple.terminal ApplePressAndHoldEnabled -bool false
# Disable press-and-hold for keys in favor of key repeat everywhere
#defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Set language and text formats
# Note: if you’re in the US, replace `EUR` with `USD`, `Centimeters` with
# `Inches`, `en_GB` with `en_US`, and `true` with `false`.
defaults write NSGlobalDomain AppleLanguages -array "en" "de"
defaults write NSGlobalDomain AppleLocale -string "en_DE@currency=EUR"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleMetricUnits -bool true

# Show language menu in the top right corner of the boot screen
sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true

# Set the timezone; see `sudo systemsetup -listtimezones` for other values
# See https://github.com/LnL7/nix-darwin/issues/359 explaining the redirect
sudo systemsetup -settimezone "Europe/Berlin" 2>/dev/null 1>&2

# Stop iTunes from responding to the keyboard media keys
#launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2> /dev/null

###############################################################################
# Energy saving                                                               #
###############################################################################

msg "${GREEN}Configuring Energy saving.${NOFORMAT}"

# Enable lid wakeup
sudo pmset -a lidwake 1

# Restart automatically on power loss
sudo pmset -a autorestart 1

# Restart automatically if the computer freezes
#sudo systemsetup -setrestartfreeze on

# Sleep the display after 15 minutes
sudo pmset -a displaysleep 15

# Disable machine sleep while charging
sudo pmset -c sleep 0

# Set machine sleep to 5 minutes on battery
sudo pmset -b sleep 5

# Set standby delay to 24 hours (default is 1 hour)
#sudo pmset -a standbydelay 86400

# Never go into computer sleep mode
#sudo systemsetup -setcomputersleep Off > /dev/null

# Hibernation mode
# 0: Disable hibernation (speeds up entering sleep mode)
# 3: Copy RAM to disk so the system state can still be restored in case of a
#    power failure.
#sudo pmset -a hibernatemode 0

# Remove the sleep image file to save disk space
#sudo rm /private/var/vm/sleepimage
# Create a zero-byte file instead…
#sudo touch /private/var/vm/sleepimage
# …and make sure it can’t be rewritten
#sudo chflags uchg /private/var/vm/sleepimage

###############################################################################
# Screen                                                                      #
###############################################################################

msg "${GREEN}Configuring Screen.${NOFORMAT}"

# Disable screen saver by setting the idle time to 0
defaults -currentHost write com.apple.screensaver idleTime -int 0

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Enable subpixel font rendering on non-Apple LCDs
# Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
defaults write NSGlobalDomain AppleFontSmoothing -int 1

# Enable HiDPI display modes (requires restart)
#sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

###############################################################################
# Screenshots                                                                 #
###############################################################################

msg "${GREEN}Configuring Screenshots.${NOFORMAT}"

# Save screenshots to the desktop
defaults write com.apple.screencapture location -string "${HOME}/Downloads"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Display the thumbnail after taking a screenshot
defaults write com.apple.screencapture "show-thumbnail" -bool true

# Include date and time in screenshot filenames.
defaults write com.apple.screencapture "include-date" -bool true


###############################################################################
# Finder                                                                      #
###############################################################################

msg "${GREEN}Configuring Finder.${NOFORMAT}"

# Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
#defaults write com.apple.finder QuitMenuItem -bool true

# Finder: disable window animations and Get Info animations
defaults write com.apple.finder DisableAllAnimations -bool true

# Set Desktop as the default location for new Finder windows
# For other paths, use `PfLo` and `file:///full/path/here/`
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Show icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Finder: show hidden files by default
#defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
# SCev = search this Mac (default)
# SCcf = search current folder
# SCsp = search previous scope
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Enable spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Remove the spring loading delay for directories
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Automatically open a new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# Empty bin items after 30 days
# false = don't (default)
# true = do
defaults write com.apple.finder "FXRemoveOldTrashItems" -bool false

# See also https://support.apple.com/en-gb/guide/mac-help/mchldaafb302/mac
# Show item info near icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist

# Show item info to the right of the icons on the desktop
/usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:labelOnBottom false" ~/Library/Preferences/com.apple.finder.plist

# Enable snap-to-grid for icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

# Increase grid spacing for icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist

# Increase the size of icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist

# Use column view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Enable AirDrop over Ethernet and on unsupported Macs running Lion
#defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Show the ~/Library folder
chflags nohidden ~/Library

# Show the /Volumes folder
sudo chflags nohidden /Volumes

# Expand the following File Info panes:
# “General”, “Open with”, and “Sharing & Permissions”
defaults write com.apple.finder FXInfoPanesExpanded -dict \
	General -bool true \
	OpenWith -bool true \
	Privileges -bool true

###############################################################################
# Dock, Dashboard, and hot corners                                            #
###############################################################################

msg "${GREEN}Configuring Dock, Dashboard, and hot corners.${NOFORMAT}"

# Enable highlight hover effect for the grid view of a stack (Dock)
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Set the icon size of Dock items to 36 pixels
set +e
tilesize_exists=$(/usr/libexec/PlistBuddy -c "Print :tilesize" ~/Library/Preferences/com.apple.dock.plist 2>&1 | grep -Fc "Does Not Exist")
set -e
if [[ "${tilesize_exists}" == 0 ]]; then
	/usr/libexec/PlistBuddy -c "Set :tilesize 36" ~/Library/Preferences/com.apple.dock.plist
else
	/usr/libexec/PlistBuddy -c "Add :tilesize integer 36" ~/Library/Preferences/com.apple.dock.plist
fi

# Prevent accidental resizing of the Dock
defaults write com.apple.dock size-immutable -bool true

# Change minimize/maximize window effect
defaults write com.apple.dock mineffect -string "scale"

# Minimize windows into their application’s icon
defaults write com.apple.dock minimize-to-application -bool true

# Enable spring loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool true

# Wipe all (default) app icons from the Dock
# This is only really useful when setting up a new Mac, or if you don’t use
# the Dock to launch apps.
defaults write com.apple.dock persistent-apps -array

# Write new list of Dock items
dock_items=(
	/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app
	/System/Applications/Messages.app
	/System/Applications/{Mail,Calendar,Notes}.app
	/System/Applications/Music.app
	/System/Applications/System\ Settings.app
	/Applications/{KeePassXC,Souretree,iTerm}.app
)
for dock_item in "${dock_items[@]}"; do
	if [[ -r "${dock_item}" ]]; then
		defaults write com.apple.dock persistent-apps -array-add \
			"<dict>
				<key>tile-data</key>
				<dict>
					<key>file-data</key>
					<dict>
						<key>_CFURLString</key>
						<string>${dock_item}</string>
						<key>_CFURLStringType</key>
						<integer>0</integer>
					</dict>
				</dict>
			</dict>"
	fi
done

# Wipe all (other) icons from the Dock
# This is only really useful when setting up a new Mac, or if you don’t use
# the Dock to launch apps.
defaults write com.apple.dock persistent-others -array

# Write new list of other Dock items (e.g. adds the Downloads folder to the end)
# arrangement
#  1 -> Name
#  2 -> Date Added
#  3 -> Date Modified
#  4 -> Date Created
#  5 -> Kind
# displayAs
#  0 -> Stack
#  1 -> Folder
#showAs
#  0 -> Automatic
#  1 -> Fan
#  2 -> Grid
#  3 -> List
defaults write com.apple.dock persistent-others -array-add \
	"<dict>
		<key>tile-data</key>
		<dict>
			<key>arrangement</key>
			<integer>2</integer>
			<key>displayas</key>
			<integer>0</integer>
			<key>file-data</key>
			<dict>
				<key>_CFURLString</key>
				<string>file:///Users/${USER}/Downloads/</string>
				<key>_CFURLStringType</key>
				<integer>15</integer>
			</dict>
			<key>file-type</key>
			<integer>2</integer>
			<key>showas</key>
			<integer>0</integer>
		</dict>
		<key>tile-type</key>
		<string>directory-tile</string>
	</dict>"

# Show only open applications in the Dock
#defaults write com.apple.dock static-only -bool true

# Don’t animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0
# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0

# Automatically hide and show the Dock
#defaults write com.apple.dock autohide -bool true

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true

# Don’t show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Disable the Launchpad gesture (pinch with thumb and three fingers)
#defaults write com.apple.dock showLaunchpadGestureEnabled -int 0

# Reset Launchpad, but keep the desktop wallpaper intact
if [[ -d "${HOME}/Library/Application Support/Dock" ]]; then
	find "${HOME}/Library/Application Support/Dock" -maxdepth 1 -name "*-*.db" -delete
fi

# Add iOS & Watch Simulator to Launchpad
#sudo ln -sf "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app" "/Applications/Simulator.app"
#sudo ln -sf "/Applications/Xcode.app/Contents/Developer/Applications/Simulator (Watch).app" "/Applications/Simulator (Watch).app"

# Add a spacer to the left side of the Dock (where the applications are)
#defaults write com.apple.dock persistent-apps -array-add '{tile-data={}; tile-type="spacer-tile";}'
# Add a spacer to the right side of the Dock (where the Trash is)
#defaults write com.apple.dock persistent-others -array-add '{tile-data={}; tile-type="spacer-tile";}'

# Hot corners
# Possible values:
#  0: no-op
#  1: nothing
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center
# 13: Lock Screen
# 14: Quick Note
# Top left screen corner → Mission Control
#defaults write com.apple.dock wvous-tl-corner -int 2
#defaults write com.apple.dock wvous-tl-modifier -int 0
# Top right screen corner → Desktop
#defaults write com.apple.dock wvous-tr-corner -int 4
#defaults write com.apple.dock wvous-tr-modifier -int 0
# Bottom left screen corner → Start screen saver
#defaults write com.apple.dock wvous-bl-corner -int 5
#defaults write com.apple.dock wvous-bl-modifier -int 0
# Bottom right screen corner (defaults to Quick Note)
defaults write com.apple.dock wvous-br-corner -int 1
defaults write com.apple.dock wvous-br-modifier -int 0

###############################################################################
# Spaces, and Mission Control                                                 #
###############################################################################

msg "${GREEN}Configuring Spaces, and Mission Control.${NOFORMAT}"

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# Don’t group windows by application in Mission Control
# (i.e. use the old Exposé behavior instead)
#defaults write com.apple.dock expose-group-by-app -bool false

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Displays have separate Spaces
defaults write com.apple.spaces "spans-displays" -bool false

# Switch to a Space with open windows for the application.
defaults write NSGlobalDomain "AppleSpacesSwitchOnActivate" -bool "true"

###############################################################################
# Safari & WebKit                                                             #
###############################################################################

msg "${GREEN}Configuring Safari & WebKit.${NOFORMAT}"

# Privacy: don’t send search queries to Apple
defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true

# Press Tab to highlight each item on a web page
defaults write com.apple.Safari WebKitTabToLinksPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks -bool true

# Show the full URL in the address bar (note: this still hides the scheme)
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Set Safari’s home page to `about:blank` for faster loading
#defaults write com.apple.Safari HomePage -string "about:blank"

# Prevent Safari from opening ‘safe’ files automatically after downloading
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Allow hitting the Backspace key to go to the previous page in history
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true

# Hide Safari’s bookmarks bar by default
defaults write com.apple.Safari ShowFavoritesBar -bool false

# Hide Safari’s sidebar in Top Sites
#defaults write com.apple.Safari ShowSidebarInTopSites -bool false

# Disable Safari’s thumbnail cache for History and Top Sites
defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2

# Enable Safari’s debug menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

# Make Safari’s search banners default to Contains instead of Starts With
defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false

# Remove useless icons from Safari’s bookmarks bar
defaults write com.apple.Safari ProxiesInBookmarksBar "()"

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Add a context menu item for showing the Web Inspector in web views
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Enable continuous spellchecking
defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true
# Disable auto-correct
defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false

# Disable AutoFill
defaults write com.apple.Safari AutoFillFromAddressBook -bool false
defaults write com.apple.Safari AutoFillPasswords -bool true
defaults write com.apple.Safari AutoFillCreditCardData -bool false
defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false

# Warn about fraudulent websites
defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Disable plug-ins
#defaults write com.apple.Safari WebKitPluginsEnabled -bool false
#defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2PluginsEnabled -bool false

# Disable Java
defaults write com.apple.Safari WebKitJavaEnabled -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles -bool false

# Block pop-up windows
defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically -bool false

# Disable auto-playing video
#defaults write com.apple.Safari WebKitMediaPlaybackAllowsInline -bool false
#defaults write com.apple.SafariTechnologyPreview WebKitMediaPlaybackAllowsInline -bool false
#defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2AllowsInlineMediaPlayback -bool false
#defaults write com.apple.SafariTechnologyPreview com.apple.Safari.ContentPageGroupIdentifier.WebKit2AllowsInlineMediaPlayback -bool false

# Enable “Do Not Track”
#defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true

# Update extensions automatically
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true

###############################################################################
# Mail                                                                        #
###############################################################################

msg "${GREEN}Configuring Mail.${NOFORMAT}"

# Disable send and reply animations in Mail.app
defaults write com.apple.mail DisableReplyAnimations -bool true
defaults write com.apple.mail DisableSendAnimations -bool true

# Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# Add the keyboard shortcut ⌘ + Enter to send an email in Mail.app
defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" "@\U21a9"

# Display emails in threaded mode, sorted by date (oldest at the top)
#defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
#defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "yes"
#defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"

# Disable inline attachments (just show the icons)
defaults write com.apple.mail DisableInlineAttachmentViewing -bool true

# Disable automatic spell checking
defaults write com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"

###############################################################################
# Spotlight                                                                   #
###############################################################################

msg "${GREEN}Configuring Spotlight.${NOFORMAT}"

# Hide Spotlight tray-icon (and subsequent helper)
#sudo chmod 600 /System/Library/CoreServices/Search.bundle/Contents/MacOS/Search
# Disable Spotlight indexing for any volume that gets mounted and has not yet
# been indexed before.
# Use `sudo mdutil -i off "/Volumes/foo"` to stop indexing any volume.
# TOOD see https://blog.christovic.com/2021/02/programatically-adding-spotlight.html
#sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes"

# Change indexing order and disable some search results
# Yosemite-specific search results (remove them if you are using macOS 10.9 or older):
# 	MENU_DEFINITION
# 	MENU_CONVERSION
# 	MENU_EXPRESSION
# 	MENU_SPOTLIGHT_SUGGESTIONS (send search queries to Apple)
# 	MENU_WEBSEARCH             (send search queries to Apple)
# 	MENU_OTHER

# TODO re-enable once I find out why it breaks the System Settins on macOS Sequoia
#defaults write com.apple.spotlight orderedItems -array \
#	'{ "enabled" = 1; "name" = "APPLICATIONS"; }' \
#	'{ "enabled" = 1; "name" = "MENU_EXPRESSION"; }' \
#	'{ "enabled" = 1; "name" = "CONTACT"; }' \
#	'{ "enabled" = 1; "name" = "MENU_CONVERSION"; }' \
#	'{ "enabled" = 1; "name" = "MENU_DEFINITION"; }' \
#	'{ "enabled" = 1; "name" = "DOCUMENTS"; }' \
#	'{ "enabled" = 1; "name" = "EVENT_TODO"; }' \
#	'{ "enabled" = 1; "name" = "DIRECTORIES"; }' \
#	'{ "enabled" = 0; "name" = "FONTS"; }' \
#	'{ "enabled" = 1; "name" = "IMAGES"; }' \
#	'{ "enabled" = 1; "name" = "MESSAGES"; }' \
#	'{ "enabled" = 0; "name" = "MOVIES"; }' \
#	'{ "enabled" = 1; "name" = "MUSIC"; }' \
#	'{ "enabled" = 1; "name" = "MENU_OTHER"; }' \
#	'{ "enabled" = 1; "name" = "PDF"; }' \
#	'{ "enabled" = 0; "name" = "PRESENTATIONS"; }' \
#	'{ "enabled" = 0; "name" = "MENU_SPOTLIGHT_SUGGETIONS"; }' \
#	'{ "enabled" = 1; "name" = "SPREADSHEETS"; }' \
#	'{ "enabled" = 1; "name" = "SYSTEM_PREFS"; }' \
#	'{ "enabled" = 0; "name" = "TIPS"; }' \
#	'{ "enabled" = 0; "name" = "BOOKMARKS"; }'

# Load new settings before rebuilding the index
#sudo killall mds >/dev/null 2>&1
# Make sure indexing is enabled for the main volume
#sudo mdutil -i on / >/dev/null
# Rebuild the index from scratch
#sudo mdutil -E / >/dev/null

###############################################################################
# Terminal & iTerm 2                                                          #
###############################################################################

msg "${GREEN}Configuring Terminal & iTerm 2.${NOFORMAT}"

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# Use Solarized Light theme by default in Terminal.app
# See https://github.com/altercation/solarized/tree/master/osx-terminal.app-colors-solarized
# See https://github.com/jan-warchol/selenized/tree/master/terminals/terminal-app
#osascript <<EOD

#tell application "Terminal"

#	local allOpenedWindows
#	local initialOpenedWindows
#	local windowID
#	set themeName to "Solarized Light xterm-256color"

#	(* Store the IDs of all the open terminal windows. *)
#	set initialOpenedWindows to id of every window

#	(* Open the custom theme so that it gets added to the list
#		of available terminal themes (note: this will open two
#		additional terminal windows). *)
#	do shell script "open '$script_dir/init/" & themeName & ".terminal'"

#	(* Wait a little bit to ensure that the custom theme is added. *)
#	delay 1

#	(* Set the custom theme as the default terminal theme. *)
#	set default settings to settings set themeName

#	(* Get the IDs of all the currently opened terminal windows. *)
#	set allOpenedWindows to id of every window

#	repeat with windowID in allOpenedWindows

#		(* Close the additional windows that were opened in order
#			to add the custom theme to the list of terminal themes. *)
#		if initialOpenedWindows does not contain windowID then
#			close (every window whose id is windowID)

#		(* Change the theme for the initial opened terminal windows
#			to remove the need to close them in order for the custom
#			theme to be applied. *)
#		else
#			set current settings of tabs of (every window whose id is windowID) to settings set themeName
#		end if

#	end repeat

#end tell

#EOD

# Enable “focus follows mouse” for Terminal.app and all X11 apps
# i.e. hover over a window and start typing in it without clicking first
#defaults write com.apple.terminal FocusFollowsMouse -bool true
#defaults write org.x.X11 wm_ffm -bool true

# Enable Secure Keyboard Entry in Terminal.app
# See: https://security.stackexchange.com/a/47786/8918
defaults write com.apple.terminal SecureKeyboardEntry -bool true

# Disable the annoying line marks
defaults write com.apple.Terminal ShowLineMarks -int 0

# Don’t display the annoying prompt when quitting iTerm
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

# Configure Selenized Themes
set +e
selenized_light_exists=$(/usr/libexec/PlistBuddy -c "Print :'Custom Color Presets':selenized-light" ~/Library/Preferences/com.googlecode.iterm2.plist 2>&1 | grep -Fc "Does Not Exist")
selenized_dark_exists=$(/usr/libexec/PlistBuddy -c "Print :'Custom Color Presets':selenized-dark" ~/Library/Preferences/com.googlecode.iterm2.plist 2>&1 | grep -Fc "Does Not Exist")
set -e

if [[ ${selenized_light_exists} == 1 ]]; then
	/usr/libexec/PlistBuddy -c "Add :'Custom Color Presets':selenized-light dict" ~/Library/Preferences/com.googlecode.iterm2.plist
	/usr/libexec/PlistBuddy -c "Merge ${script_dir}/init/selenized-light.itermcolors :'Custom Color Presets':selenized-light" ~/Library/Preferences/com.googlecode.iterm2.plist
fi

if [[ ${selenized_dark_exists} == 1 ]]; then
	/usr/libexec/PlistBuddy -c "Add :'Custom Color Presets':selenized-dark dict" ~/Library/Preferences/com.googlecode.iterm2.plist
	/usr/libexec/PlistBuddy -c "Merge ${script_dir}/init/selenized-dark.itermcolors :'Custom Color Presets':selenized-dark" ~/Library/Preferences/com.googlecode.iterm2.plist
fi

###############################################################################
# Time Machine                                                                #
###############################################################################

msg "${GREEN}Configuring Time Machine.${NOFORMAT}"

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

###############################################################################
# Activity Monitor                                                            #
###############################################################################

msg "${GREEN}Configuring Activity Monitor.${NOFORMAT}"

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Address Book, Dashboard, iCal, TextEdit, and Disk Utility                   #
###############################################################################

msg "${GREEN}Configuring Address Book, Dashboard, iCal, TextEdit, and Disk Utility.${NOFORMAT}"

# Enable the debug menu in Address Book
defaults write com.apple.addressbook ABShowDebugMenu -bool true

# Enable Dashboard dev mode (allows keeping widgets on the desktop)
#defaults write com.apple.dashboard devmode -bool true

# Enable the debug menu in iCal (pre-10.8)
defaults write com.apple.iCal IncludeDebugMenu -bool true

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -bool false
# Open and save files as UTF-8 in TextEdit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# Enable the debug menu in Disk Utility
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true

# Auto-play videos when opened with QuickTime Player
#defaults write com.apple.QuickTimePlayerX MGPlayMovieOnOpen -bool true

###############################################################################
# Mac App Store                                                               #
###############################################################################

msg "${GREEN}Configuring Mac App Store.${NOFORMAT}"

# Enable the WebKit Developer Tools in the Mac App Store
defaults write com.apple.appstore WebKitDeveloperExtras -bool true

# Enable Debug Menu in the Mac App Store
defaults write com.apple.appstore ShowDebugMenu -bool true

# Enable the automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Check for software updates daily, not just once per week
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install System data files & security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

# Automatically download apps purchased on other Macs
defaults write com.apple.SoftwareUpdate ConfigDataInstall -int 1

# Turn on app auto-update
defaults write com.apple.commerce AutoUpdate -bool true

# Allow the App Store to reboot machine on macOS updates
#defaults write com.apple.commerce AutoUpdateRestartRequired -bool true

###############################################################################
# Photos                                                                      #
###############################################################################

msg "${GREEN}Configuring Photos.${NOFORMAT}"

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Messages                                                                    #
###############################################################################

msg "${GREEN}Configuring Messages.${NOFORMAT}"

# Disable automatic emoji substitution (i.e. use plain text smileys)
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false

# Disable smart quotes as it’s annoying for messages that contain code
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false

# Disable continuous spell checking
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false

###############################################################################
# Google Chrome & Google Chrome Canary                                        #
###############################################################################

msg "${GREEN}Configuring Google Chrome & Google Chrome Canary.${NOFORMAT}"

# Disable the all too sensitive backswipe on trackpads
#defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
#defaults write com.google.Chrome.canary AppleEnableSwipeNavigateWithScrolls -bool false

# Disable the all too sensitive backswipe on Magic Mouse
#defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false
#defaults write com.google.Chrome.canary AppleEnableMouseSwipeNavigateWithScrolls -bool false

# Use the system-native print preview dialog
#defaults write com.google.Chrome DisablePrintPreview -bool true
#defaults write com.google.Chrome.canary DisablePrintPreview -bool true

# Expand the print dialog by default
#defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true
#defaults write com.google.Chrome.canary PMPrintingExpandedStateForPrint2 -bool true

###############################################################################
# Finalize                                                                    #
###############################################################################

msg "${GREEN}Done. Note that some of these changes require a logout/restart to take effect. Also restart all your apps.${NOFORMAT}"
