#!/bin/bash

sudo apt-get update
sudo apt-get install -y apt-transport-https sudo
sudo sh -c 'echo deb https://apt.buildkite.com/buildkite-agent stable main > /etc/apt/sources.list.d/buildkite-agent.list'
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 32A37959C2FA5C3C99EFBC32A79206696452D198
sudo apt-get update && sudo apt-get install -y buildkite-agent

# add token (see buildkite)
sudo systemctl enable buildkite-agent@1 && systemctl start buildkite-agent@1
sudo systemctl enable buildkite-agent@2 && systemctl start buildkite-agent@2

apt-get install -y build-essential curl gdb git jq libblas-dev libbz2-dev libcairo-dev libclang-3.8-dev libcurl4-gnutls-dev libevent-dev libgcrypt20-dev libgpg-error-dev libgtk-3-0 liblapack-dev liblzo2-dev libreadline-dev libssl-dev libxml2-dev libxslt1-dev libzmq3-dev mongodb-server moreutils pkg-config python-dev python-yaml python3-yaml python3-nose redis-server rsync unzip binutils-gold clang
#libssl1.0-dev

pip3 install meson

wget https://bintray.com/sociomantic-tsunami/dlang/download_file?file_path=d1to2fix_0.10.0-alpha1-xenial_amd64.deb -O d1tod2.deb
dpkg -i d1tod2.deb && rm d1tod2.deb
wget https://bintray.com/sociomantic-tsunami/dlang/download_file?file_path=libebtree6_6.0.s7-rc5-xenial_amd64.deb -O libebtree6.deb
dpkg -i libebtree6.deb && rm libebtree6.deb
wget https://bintray.com/sociomantic-tsunami/dlang/download_file?file_path=libebtree6-dev_6.0.s7-rc5-xenial_amd64.deb -O libebtree6-dev.deb
dpkg -i libebtree6-dev.deb && rm libebtree6-dev.deb

# ld.gold as default linker
update-alternatives --install "/usr/bin/ld" "ld" "/usr/bin/ld.gold" 20
update-alternatives --install "/usr/bin/ld" "ld" "/usr/bin/ld.bfd" 10
