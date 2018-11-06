#!/usr/bin/env bash

set -xueo pipefail
trap 'echo build script failed at line $LINENO' ERR
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TODAY=$(date +'%Y-%m-%d')
: ${BRANCH:=master}

# build binaries
if [ ! -d installer ]; then
    git clone https://github.com/dlang/installer.git --origin upstream
fi
pushd installer/create_dmd_release

git reset --hard --quiet
git clean -ffdxq
git fetch upstream $("./$DIR/origin_target_branch.sh" https://github.com/dlang/installer.git "$BRANCH") --quiet
git checkout FETCH_HEAD --quiet

mkdir build
LATEST=$(wget -q -O - http://downloads.dlang.org/releases/LATEST)
rdmd build_all.d v$LATEST $BRANCH
rm -f build/*.zip # only keep lzma archives

# sign binaries
for file in build/*; do
    gpg --detach-sign --no-use-agent $file
done

# upload binaries
mv build dmd-$BRANCH-$TODAY
aws --profile ddo s3 sync dmd-$BRANCH-$TODAY/ s3://downloads.dlang.org/nightlies/dmd-$BRANCH-$TODAY/ --acl public-read --cache-control max-age=604800

# create redirects from dmd-$BRANCH/* to dmd-$BRANCH-2018-10-12/*
for file in $(ls dmd-$BRANCH-$TODAY); do
    echo -n | aws --profile ddo s3 cp - s3://downloads.dlang.org/nightlies/dmd-$BRANCH/$file --acl public-read --cache-control max-age=604800 --website-redirect http://downloads.dlang.org/nightlies/dmd-$BRANCH-$TODAY/$file
done
echo -n | aws --profile ddo s3 cp - s3://downloads.dlang.org/nightlies/dmd-$BRANCH --acl public-read --cache-control max-age=604800 --website-redirect http://downloads.dlang.org/nightlies/dmd-$BRANCH-$TODAY
echo -n $BRANCH-$TODAY | aws --profile ddo s3 cp - s3://downloads.dlang.org/nightlies/dmd-$BRANCH/LATEST --acl public-read --cache-control max-age=604800
popd

# update downloads.dlang.org/nightlies page with new index.html files
if [ ! -d downloads.dlang.org ]; then
    git clone https://github.com/dlang/downloads.dlang.org.git --origin upstream
fi
pushd downloads.dlang.org

git reset --hard --quiet
git clean -ffdxq
git fetch upstream master --quiet
git checkout FETCH_HEAD --quiet

make -C src
rm -rf ddo
./src/build-gen-index -c s3_index -c generate
aws --profile ddo s3 sync ./ddo/nightlies/ s3://downloads.dlang.org/nightlies/ --acl public-read --cache-control max-age=604800
popd
