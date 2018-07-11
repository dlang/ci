#!/bin/bash

cat << 'EOF'
steps:
  - command: |
      uname -a
      make --version
      \${SHELL} --version || true
      c++ --version
      ld -v
      ! command -v gdb &>/dev/null || gdb --version
      dmd --version || true
    label: "Print envs"

  - command: |
        git clean -ffdxq .
        # make sure the entire CI folder is loaded
        if [ ! -d buildkite ] ; then
           mkdir -p buildkite && cd buildkite
           wget https://github.com/dlang/ci/archive/master.tar.gz
           tar xvfz master.tar.gz --strip-components=2 ci-master/buildkite
           rm -rf master.tar.gz
        else
            cd buildkite
        fi
        ./build_distribution.sh
    label: "Build"
    artifact_paths: "distribution.tar.xz"

  - wait
EOF

################################################################################
# Add your project here.
# By default, the Project Tester will perform your Travis 'script' tests.
# If a different action is preferred, set it in buildkite/build_project.sh
################################################################################
projects=(
    "vibe-d/vibe.d+libevent-examples"
    "vibe-d/vibe.d+vibe-core-examples"
    "vibe-d/vibe.d+libevent-tests"
    "vibe-d/vibe.d+vibe-core-tests"
    "vibe-d/vibe.d+libevent-base"
    "vibe-d/vibe.d+vibe-core-base"
    "vibe-d/vibe.d+libasync-base"
    "sociomantic-tsunami/ocean"
    "dlang/dub"
    "vibe-d/vibe-core+epoll"
    "vibe-d/vibe-core+select"
    "higgsjs/Higgs"
    "rejectedsoftware/ddox"
    "BlackEdder/ggplotd"
    "eBay/tsv-utils-dlang"
    "dlang-community/D-Scanner"
    "dlang-tour/core"
    "d-widget-toolkit/dwt"
    "rejectedsoftware/diet-ng"
    "mbierlee/poodinis"
    "dlang/tools"
    "atilaneves/unit-threaded"
    "d-gamedev-team/gfm"
    "dlang-community/DCD"
    "weka-io/mecca"
    "CyberShadow/ae"
    "libmir/mir-algorithm"
    "dlang-community/D-YAML"
    "libmir/mir-random"
    "dlang-community/libdparse"
    "BBasile/iz"
    "dlang-community/dfmt"
    "libmir/mir"
    "s-ludwig/taggedalgebraic"
    "s-ludwig/std_data_json"
    "repeatedly/mustache-d"
    "nomad-software/dunit"
    "msoucy/dproto"
    "lgvz/imageformats"
    "kyllingstad/zmqd"
    "ikod/dlang-requests"
    "economicmodeling/containers"
    "dlang/undeaD"
    "atilaneves/automem"
    "ariovistus/pyd"
    "PhilippeSigaud/Pegged"
    "Netflix/vectorflow"
    "DlangScience/scid"
    "kaleidicassociates/excel-d"
    "dlang-bots/dlang-bot"
    "DerelictOrg/DerelictSDL2"
    "DerelictOrg/DerelictGLFW3"
    "DerelictOrg/DerelictGL3"
    "DerelictOrg/DerelictFT"
    "Abscissa/libInputVisitor"
)
# Add all projects that require more than 3GB of memory to build
declare -A memory_req
memory_req["BlackEdder/ggplotd"]=high
memory_req["BBasile/iz"]=high
memory_req["dlang-community/D-Scanner"]=high
memory_req["vibe-d/vibe-core+select"]=high
memory_req["vibe-d/vibe-core+epoll"]=high
memory_req["vibe-d/vibe.d+vibe-core-base"]=high
memory_req["vibe-d/vibe.d+libevent-base"]=high
memory_req["vibe-d/vibe.d+libasync-base"]=high
memory_req["libmir/mir-algorithm"]=high
memory_req["sociomantic-tsunami/ocean"]=high
# Force long-running tasks to be on the low-end machines
memory_req["vibe-d/vibe.d+libevent-examples"]=low
memory_req["vibe-d/vibe.d+vibe-core-examples"]=low
memory_req["vibe-d/vibe.d+libevent-tests"]=low
memory_req["vibe-d/vibe.d+vibe-core-tests"]=low


for project_name in "${projects[@]}" ; do
    project="$(echo "$project_name" | sed "s/\([^+]*\)+.*/\1/")"
cat << EOF
  - command: |
      export REPO_URL="https://github.com/${project}"
      export REPO_DIR="$(basename "$project")"
      export REPO_FULL_NAME="${project_name}"
      ./buildkite/build_project.sh
    label: "${project_name}"
    env:
      DETERMINISTIC_HINT: 1
      DC: dmd
      DMD: dmd
EOF

if [ "${memory_req["$project_name"]:-x}" != "x" ] ; then
cat << EOF
    agents:
      - "memory=${memory_req["$project_name"]}"
EOF
fi

done
