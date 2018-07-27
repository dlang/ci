#!/bin/bash

set -uexo pipefail

# Builds DMD, DRuntime, Phobos, tools and DUB + creates a "distribution" archive for latter usage.
echo "--- Setting build variables"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

origin_repo="$(echo "$BUILDKITE_REPO" | sed "s/.*\/\([^\]*\)[.]git/\1/")"
origin_target_branch="$BUILDKITE_PULL_REQUEST_BASE_BRANCH"
if [ -z "$origin_target_branch" ] ; then
  origin_target_branch="$BUILDKITE_BRANCH"
fi
echo "origin_target_branch: $origin_target_branch"

echo "--- Cloning all core repositories"
for dir in dmd druntime phobos tools dub ; do
    if [ "$origin_repo" == "$dir" ] ; then
      # we have already cloned this repo, so let's use this data
      mkdir -p $dir
      cp -r $(ls -A | grep -v $dir) $dir
    else
      branch=$(git ls-remote --exit-code --heads https://github.com/dlang/$dir "${origin_target_branch}" > /dev/null || echo "master")
      git clone -b "${branch:-master}" --depth 1 https://github.com/dlang/$dir
    fi
done

for dir in dmd druntime phobos ; do
    echo "--- Building $dir"
    make -C $dir -f posix.mak AUTO_BOOTSTRAP=1 --jobs=4
done

echo "--- Building dub"
cd dub
DMD="../dmd/generated/linux/release/64/dmd" ./build.sh
cd ..

echo "--- Building tools"
make -C tools -f posix.mak RELEASE=1 --jobs=4

echo "--- Building distribution"
mkdir -p distribution/{bin,imports,libs}
cp --archive --link dmd/generated/linux/release/64/dmd dub/bin/dub tools/generated/linux/64/rdmd distribution/bin/
cp --archive --link phobos/etc phobos/std druntime/import/* distribution/imports/
cp --archive --link phobos/generated/linux/release/64/libphobos2.{a,so,so*[!o]} distribution/libs/
echo '[Environment]' >> distribution/bin/dmd.conf
echo 'DFLAGS=-I%@P%/../imports -L-L%@P%/../libs -L--export-dynamic -L--export-dynamic -fPIC' >> distribution/bin/dmd.conf

# add buildkite files to the archive
cp -R "$DIR" distribution

XZ_OPT=-0 tar cfJ distribution.tar.xz distribution
