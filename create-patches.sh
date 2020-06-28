#!/bin/bash

set -e

if ! [[ -d patches ]]; then
  ( \
    git clone -n https://github.com/OpenMage/magento-lts.git patches; \
    cd patches; \
    git remote add mirror https://github.com/OpenMage/magento-mirror.git; \
  )
fi

git fetch --all
git config diff.renameLimit 10000

cd patches
read -p "Create patches for which OpenMage LTS version? (e.g. v19.4.3) " target
echo "Will create patches for all versions to $target"
git log -1 $target | head -n 3
read -p "Confirm the commit above is correct and press enter to continue." input

for tag in $(git ls-remote --tags mirror | awk '{print $2}' | grep -vE "alpha|beta|rc|{}"); do
  echo "Creating patch for $tag..."
  git diff --binary $tag..$openmage > magento-ce-${tag##*/}-openmage-lts-$target.patch
done

# Sync to S3
# TODO
