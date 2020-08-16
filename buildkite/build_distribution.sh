#!/bin/bash

PS4="~> " # needed to avoid accidentally generating collapsed output
set -uexo pipefail

# Builds DMD, DRuntime, Phobos, tools and DUB + creates a "distribution" archive for latter usage.
echo "--- Setting build variables"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"$DIR/clone_repositories.sh"

echo "--- Building dmd"
dmd/src/bootstrap.sh

for dir in druntime phobos ; do
    echo "--- Building $dir"
    make -C $dir -f posix.mak --jobs=4
done

echo "--- Building dub"
pushd dub
# enable experimental build cache improvements https://github.com/dlang/dub/pull/1589
sed -i 's|bool m_filterVersions = false;|bool m_filterVersions = true;|' source/dub/commandline.d
DMD="../dmd/generated/linux/release/64/dmd" ./build.sh
popd

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

# final cleanup
git clean -ffdxq --exclude "distribution.tar.xz" .
