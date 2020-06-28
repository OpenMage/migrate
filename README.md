This repo is used to host the Magento CE to OpenMage migration script.

## Generating patch files

To generate patch files for a new version just run the script from the repo root directory:

    $ bash create-patches.sh

## Updating migrate script

    $ sed "s/SCRIPT_COMMIT_SHA_HERE/$(git log -1 --format=%H)/" migrate.sh > index.html
