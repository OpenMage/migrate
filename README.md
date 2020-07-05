This repo is used to host the Magento CE to OpenMage migration script.

## Prerequisites

In order to upload the generated patch files to S3, AWS CLI v2 needs to be installed: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

## Generating patch files

To generate patch files for a new version just run the script from the repo root directory:

    $ export AWS_ACCESS_KEY_ID=
    $ export AWS_SECRET_ACCESS_KEY=
    $ bash create-patches.sh

## Updating migrate script

    $ sed "s/SCRIPT_COMMIT_SHA_HERE/$(git log -1 --format=%H)/" migrate.sh > index.html
