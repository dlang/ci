#!/bin/bash

PS4="~> " # needed to avoid accidentally generating collapsed output
set -uexo pipefail

# Builds DMD, DRuntime, Phobos, tools and DUB + creates a "distribution" archive for latter usage.
echo "--- Setting build variables"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

origin_repo="$(echo "$BUILDKITE_REPO" | sed "s/.*\/\([^\]*\)[.]git/\1/")"
origin_target_branch="${BUILDKITE_PULL_REQUEST_BASE_BRANCH:-$BUILDKITE_BRANCH}"
echo "origin_target_branch: $origin_target_branch"

echo "--- Cloning all core repositories"
repositories=(dmd druntime phobos tools dub)
for dir in "${repositories[@]}" ; do
    # repos cloned via the project tester can't be considered as existent
    if [ "$origin_repo" == "$dir" ] && [ "${REPO_FULL_NAME:-x}" == "x" ]  ; then
    # we have already cloned this repo, so let's use this data
        mkdir -p "$dir"
        for f in ./* ; do
            case "$f" in
                ./.git) ;;
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
    if [ ! -d "$origin_repo" ] ; then
        if [ "$origin_target_branch" == "master" ] || [ "$origin_target_branch" == "stable" ] ; then
            branch="$origin_target_branch"
        else
            branch=$(git ls-remote --exit-code --heads "https://github.com/dlang/$dir" "${origin_target_branch}" > /dev/null && echo "$origin_target_branch" || echo "master")
        fi
        git clone -b "${branch:-master}" --depth 1 "https://github.com/dlang/$dir"
    fi
done

for dir in dmd druntime phobos ; do
    echo "--- Building $dir"
    make -C $dir -f posix.mak AUTO_BOOTSTRAP=1 --jobs=4
done
