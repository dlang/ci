#!/bin/bash

# Returns the origin target branch to clone

origin_target_branch="${BUILDKITE_PULL_REQUEST_BASE_BRANCH:-$BUILDKITE_BRANCH}"

repo="$1"

if [ -e "$repo" ] ; then
    (>&2 echo "Did you forget to pass in a repository?")
    exit 1
fi

branch=master

if [ "$origin_target_branch" == "master" ] || [ "$origin_target_branch" == "stable" ] ; then
    branch="$origin_target_branch"
else
    # check whether the current branch exists on the to be checked out repo
    branch=$(git ls-remote --exit-code --heads "$repo" "${origin_target_branch}" > /dev/null && echo "$origin_target_branch" || echo "master")
fi
echo "$branch"
