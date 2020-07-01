#!/bin/bash

set -e

if ! [[ -d patches ]]; then
  ( \
    git clone -n https://github.com/OpenMage/magento-lts.git patches; \
    cd patches; \
    git remote add mirror https://github.com/OpenMage/magento-mirror.git; \
    git remote update; \
  )
fi

cd patches
git fetch --all
git config diff.renameLimit 100000

read -p "Create patches for which OpenMage LTS version? (e.g. v19.4.4) " target
echo "Will create patches for all versions to $target"
git log -1 $target | head -n 3
read -p "Confirm the commit above is correct and press enter to continue." input
targethash=$(git rev-parse $target)

for tag in $(git ls-remote --tags mirror | awk '{print $2}' | grep -vE "alpha|beta|rc|{}"); do
  taghash=$(git ls-remote --tags mirror | grep -vE "alpha|beta|rc" | grep $tag | tail -1 | awk '{print $1}')
  echo "Creating patch for $tag..$target ($taghash..$targethash)..."
  git diff --binary $taghash..$targethash > magento-ce-${tag##*/}-openmage-lts-$target.patch
done

# Sync to S3
# TODO

# Generate the new migrate script
cd ../
sed "s/SCRIPT_COMMIT_SHA_HERE/$(git log -1 --format=%H)/" migrate.sh > upgrade.sh
echo "Execute 'bash upgrade.sh' to upgrade to OpenMage $target."