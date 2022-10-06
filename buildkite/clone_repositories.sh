#!/bin/bash

PS4="~> " # needed to avoid accidentally generating collapsed output
set -uexo pipefail

# Builds DMD, DRuntime, Phobos, tools and DUB + creates a "distribution" archive for latter usage.
echo "--- Setting build variables"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

origin_repo="$(echo "$BUILDKITE_REPO" | sed "s/.*\/\([^\]*\)[.]git/\1/")"

echo "--- Cloning all core repositories"
repositories=(dmd druntime phobos tools dub)

# For PRs to dlang/ci, clone itself too, s.t. the code below can be tested
if [ "${REPO_FULL_NAME:-none}" == "dlang/ci" ] ; then
    repositories+=(ci)
fi

for dir in "${repositories[@]}" ; do
    if [ "$origin_repo" == "$dir" ] ; then
    # we have already cloned this repo, so let's use this data
        mkdir -p "$dir"
        find . -maxdepth 1 -mindepth 1 | while read -r f ; do
            case "$f" in
                ./.git)
                    # for some commands a real "git" repository is required
                    cp -r "$f" "$dir"
                    ;;
                ./buildkite-ci-build) ;;
                ./buildkite) ;;
                ./distribution) ;;
                ./tmp) ;;
                "./${dir}") ;;
                *)
                    mv "$f" "$dir"
                    ;;
            esac
        done
    fi
done

for dir in "${repositories[@]}" ; do
    if [ ! -d "$dir" ] ; then
        repo="https://github.com/dlang/$dir"
        branch=$("$DIR/origin_target_branch.sh" "$repo")
        echo "target_branch: $branch"
        git clone -b "${branch:-master}" --depth 1 "$repo" --quiet
    fi
done
