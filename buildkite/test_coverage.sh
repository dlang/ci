#!/bin/bash

PS4="~> " # needed to avoid accidentally generating collapsed output
set -uexo pipefail

echo "--- Setting build variables"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
N=2
MODEL=64
PIC=1

"$DIR/clone_repositories.sh"

echo "--- Running the testsuite with COVERAGE=1"

origin_repo="$(echo "$BUILDKITE_REPO" | sed "s/.*\/\([^\]*\)[.]git/\1/")"
cd "$origin_repo"

if [ -f coverage.sh ] ; then
    wget "https://codecov.io/bash" -O codecov.sh
    ./coverage.sh
else
    echo "WARNING: no coverage.sh script found."
fi
