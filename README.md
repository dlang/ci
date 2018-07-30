# dlangci

CI pipelines for dlang.

[![Build status](https://badge.buildkite.com/7e4ed28182279b460ce787dbc36ba2f5a142843225a9c9ecb8.svg?branch=master)](https://buildkite.com/dlang/ci)

How to build a project locally
------------------------------

Typically all you need to reproduce a failure is to clone a specific repository locally and run its testsuite with your respective DMD compiler:

```
dub test --compiler=$HOME/dlang/dmd/generated/linux/release/64/dmd
```

However, for adding new projects it can be interesting to test what's happening on Buildkite locally.
This can be done with:

```
REPO_FULL_NAME="dlang/tools" ./buildkite/build_project.sh
```

However, be sure to download the `distribution.tgz` and extract it in `distribution` before running (otherwise the default `dmd` will be used by `build_project.sh`).
Alternatively, to use your locally build `dmd`, simply make sure that it has a higher priority in your `$PATH`:

```
export PATH="$HOME/dlang/dmd/generated/linux/release/64:$PATH"
```
