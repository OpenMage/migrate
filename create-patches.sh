#!/bin/bash

set -e

if ! [ -d patches ]; then
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
  outfile=magento-ce-${tag##*/}-openmage-lts-$target.patch
  if ! [[ -f $outfile.gz ]]; then
    echo "Creating patch for $tag..$target ($taghash..$targethash)..."
    git diff --binary $taghash..$targethash > $outfile
    sha1sum $outfile > $outfile.sha1
    gzip $outfile
  fi
done

cd ../

# Sync to S3
aws s3 cp patches s3://openmage.migrationpatches/ --recursive --exclude "*" --include "*-$target.patch.gz" --include "*-$target.patch.sha1" --profile openmage.migrationpatches
