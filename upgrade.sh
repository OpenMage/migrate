#!/bin/bash
set -e
# OpenMage LTS migration script (for Magento CE only)
#
# See https://www.openmage.org/magento-lts/migration-guide.html for full instructions.
#
# This script is meant for quick and easy install via:
#   $ curl -fsSL https://migrate.openmage.org | sh

SCRIPT_COMMIT_SHA="030eb956e582bd5943f78fff5f8859950b47aee8"

nightly=1.9.4.x
_nightly=nightly
stable=v20.0.0
_stable=$stable

# The channel to install from:
#   * nightly
#   * test
#   * stable
#   * edge (deprecated)
DEFAULT_CHANNEL_VALUE="stable"
if [ -z "$CHANNEL" ]; then
	CHANNEL=$DEFAULT_CHANNEL_VALUE
fi

DEFAULT_DOWNLOAD_URL="https://migrate.openmage.org"
if [ -z "$DOWNLOAD_URL" ]; then
	DOWNLOAD_URL=$DEFAULT_DOWNLOAD_URL
fi
DRY_RUN=${DRY_RUN:-}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

is_dry_run() {
	if [ -z "$DRY_RUN" ]; then
		return 1
	else
		return 0
	fi
}

do_install() {
	echo "# Executing OpenMage migrate script..."

	case "$(grep '$_currentEdition' app/Mage.php | awk '{print $5}' | sed 's/self:://' | sed 's/;//')" in
		EDITION_COMMUNITY)
			installed=$(grep -A 8 'function getVersionInfo' app/Mage.php | tail -n 6 | awk '{print $3}' | sed "s/[',]//g" | grep -v '^$' | paste -sd '.' -)
			echo "Detected that you have installed Magento Commuinity Edition $installed"
			patchfile=$(find patches/ -maxdepth 1 -name '*.patch' | grep $installed | tail -1)
			if [ -z "$patchfile" ]; then
				echo "Patch file for Magento Commuinity Edition $installed not found"
			else
				read -p "Confirm the patch file "$patchfile" is correct and press enter to continue." input
				git apply --3way --ignore-space-change --ignore-whitespace $patchfile
				echo "Patch applied, make sure to resolve conflicts, test and commit the migration."
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
