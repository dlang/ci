#!/bin/bash

PS4="~> " # needed to avoid accidentally generating collapsed output
set -uexo pipefail

if [ "${BUILDKITE_PULL_REQUEST:-false}" != "false" ]; then
    if ! $(git remote | grep -q upstream) ; then
        git remote add upstream "${BUILDKITE_REPO}";
    fi
    git fetch -q upstream "+refs/pull/${BUILDKITE_PULL_REQUEST}/merge:";
    git checkout -f FETCH_HEAD;
fi
