#!/bin/bash

PS4="~> " # needed to avoid accidentally generating collapsed output
set -uexo pipefail

echo "--- Setting build variables"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export PATH="$PWD/distribution/bin:${PATH:-}"
# set HOME to separate concurrent ~/.dub user paths
export HOME="$PWD"
export LIBRARY_PATH="$PWD/distribution/libs:${LIBRARY_PATH:-}"
export LD_LIBRARY_PATH="$PWD/distribution/libs:${LD_LIBRARY_PATH:-}"
export DETERMINISTIC_HINT=1

# Make sure there are no overlaps of the build files by putting them in the current directory
rm -rf tmp && mkdir tmp
export TMP=$PWD/tmp
export TMPDIR=$PWD/tmp
export TEMP=$PWD/tmp

export DC=dmd
export DMD=dmd

# At the moment all workers are x86_64
export ARCH=x86_64
