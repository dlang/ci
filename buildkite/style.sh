#!/bin/bash

PS4="~> " # needed to avoid accidentally generating collapsed output
set -uexo pipefail

echo "--- Setting build variables"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
N=2
MODEL=64
PIC=1

"$DIR/clone_repositories.sh"

origin_repo="$(echo "$BUILDKITE_REPO" | sed "s/.*\/\([^\]*\)[.]git/\1/")"
cd "$origin_repo"

echo "--- Running style testing"
make -f posix.mak style
