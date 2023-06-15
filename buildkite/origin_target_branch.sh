#!/bin/bash

# Returns the origin target branch to clone

repo="$1"
if [ -e "$repo" ] ; then
    (>&2 echo "Did you forget to pass in a repository?")
    exit 1
fi
if [ $# -eq 2 ]; then
    origin_target_branch="$2"
else
    if [[ "${BUILDKITE_PULL_REQUEST_REPO:-}" =~ github\.com/dlang/ ]]; then
        # PR from official dlang repo - try same-named branches for the other repos
        origin_target_branch="$BUILDKITE_BRANCH"
    else
        origin_target_branch="${BUILDKITE_PULL_REQUEST_BASE_BRANCH:-$BUILDKITE_BRANCH}"
    fi
fi

if [ "$origin_target_branch" == "master" ] || [ "$origin_target_branch" == "stable" ] ; then
    branch="$origin_target_branch"
else
    # check whether the target branch exists for the given repo or fallback to master if it doesn't
    branch=$(git ls-remote --exit-code --heads "$repo" "$origin_target_branch" > /dev/null && echo "$origin_target_branch" || echo 'master')
fi
echo "$branch"
