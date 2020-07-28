#!/bin/sh
set -e
# OpenMage LTS migration script (for Magento CE only)
#
# See https://www.openmage.org/magento-lts/migration-guide.html for full instructions.
#
# This script is meant for quick and easy install via:
#   $ curl -fsSL https://migrate.openmage.org | sh

SCRIPT_COMMIT_SHA="SCRIPT_COMMIT_SHA_HERE"

nightly=1.9.4.x
stable=v20.0.1

# The channel to install from:
#   * nightly
#   * test
#   * stable
#   * edge (deprecated)
DEFAULT_CHANNEL_VALUE="stable"
if [ -z "$CHANNEL" ]; then
	CHANNEL=$DEFAULT_CHANNEL_VALUE
fi

case $CHANNEL in
	stable)
		version=$stable
		;;
	nightly)
		version=$nightly
		;;
	*)
		echo "Unknown channel: $CHANNEL"
		exit 1
esac

DEFAULT_DOWNLOAD_URL="https://openmage.migrationpatches.s3.amazonaws.com/"
if [ -z "$DOWNLOAD_URL" ]; then
	DOWNLOAD_URL=$DEFAULT_DOWNLOAD_URL
fi
DRY_RUN=${DRY_RUN:-}

is_dry_run() {
	if [ -z "$DRY_RUN" ]; then
		return 1
	else
		return 0
	fi
}

do_install() {
	if ! [ -d var ]; then
		echo "Please run this script from the Magento root directory."
		exit 1
	fi
	if ! command -v git >/dev/null; then
		echo "The 'git' command is required as 'patch' does not support binary diffs."
		exit 1
	fi

	if ! [ -f app/Mage.php ]; then
		echo "Please run this script in the Magento root directory. (could not find app/Mage.php)"
		exit 1
	fi
	if grep -qF 'getOpenMageVersionInfo' app/Mage.php; then
		echo "It appears you have already upgraded this Magento CE installation to OpenMage LTS."
		exit 1
	fi

	cat << 'BANNER'
 _____                 ___  ___                   _    _____ _____ 
|  _  |                |  \/  |                  | |  |_   _/  ___|
| | | |_ __   ___ _ __ | .  . | __ _  __ _  ___  | |    | | \ `--. 
| | | | '_ \ / _ \ '_ \| |\/| |/ _` |/ _` |/ _ \ | |    | |  `--. \
\ \_/ / |_) |  __/ | | | |  | | (_| | (_| |  __/ | |____| | /\__/ /
 \___/| .__/ \___|_| |_\_|  |_/\__,_|\__, |\___| \_____/\_/ \____/ 
      | |                             __/ |                        
      |_|                            |___/                         
BANNER
	echo "
This script will download the appropriate patch for your Magento installation
and update the core source code to OpenMage LTS $version.

DO NOT continue if you do not have an easily restorable backup!

DO NOT run this migration on production unless the result has been thoroughly
tested in a development environment for compatibility issues.

Migration will begin in 20 seconds. Press CTRL+C to abort.
"
	sleep 20

	case "$(grep '$_currentEdition' app/Mage.php | awk '{print $5}' | sed 's/self:://' | sed 's/;//')" in
		EDITION_COMMUNITY)
			installed=$(grep -A 8 'function getVersionInfo' app/Mage.php | tail -n 6 | awk '{print $3}' | sed "s/[',]//g" | grep -v '^$' | paste -sd '.' -)
			echo "Detected that you have installed Magento Commuinity Edition $installed"
			patchfile=magento-ce-$installed-openmage-lts-$version.patch
			url="$DOWNLOAD_URL$patchfile"
			patchfile=var/$patchfile
			if ! [ -f "$patchfile" ]; then
				echo "Downloading patch for Magento CE $installed to OpenMage LTS $version..."
				if command -v wget >/dev/null; then
					wget --no-hsts --no-check-certificate $url.gz -O $patchfile.gz
					wget --no-hsts --no-check-certificate $url.sha1 -O $patchfile.sha1
				elif command -v curl >/dev/null; then
					curl --insecure $url.gz -o $patchfile.gz
					curl --insecure $url.sha1 -o $patchfile.sha1
				else
					echo "Command not found, please install curl or wget within your PATH."
					exit 1
				fi
				echo "Extracting and verifying patch file..."
				gunzip $patchfile.gz
				checksum=$(<$patchfile sha1sum - | awk '{print $1}')
				if [ "$(awk '{print $1}' $patchfile.sha1)" != "$checksum" ]; then
					rm $patchfile $patchfile.sha1
					echo "Downloaded file was corrupt, please try again."
					exit 1
				fi
			fi
			
			echo "Performing dry-run patch..."
			if git --git-dir=/dev/null apply --ignore-whitespace --check $patchfile; then
				if is_dry_run; then
					echo "Dry-run was successful!"
				else
					echo "Dry run was successful! Applying patch..."
					git --git-dir=/dev/null apply --ignore-whitespace $patchfile
					echo ""
					echo "All done! Please refresh your cache to complete the migration."
				fi
			else
				echo "Unable to apply the patch. The following command failed:"
				echo ""
				echo "    git --git-dir=/dev/null apply --ignore-whitespace --check $patchfile"
				echo ""
				echo "If you need to restore any files, the original source code may be found at:"
				echo ""
				echo "    https://github.com/OpenMage/magento-mirror"
				echo ""
			fi
			;;
		*)
			echo "We're sorry, but the edition you have installed is not supported by this migration script."
			exit 1
			;;
        esac

	# TODO

}

# wrapped up in a function so that we have some protection against only getting
# half the file during "curl | sh"
do_install
