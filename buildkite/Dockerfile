FROM buildkite/agent:ubuntu

ADD travis_get_script /usr/local/bin/get_travis_test_script
RUN apt-get update && apt-get install -y build-essential cmake curl gdb git jq sqlite3 libblas-dev \
    libbz2-dev libcairo-dev libcurl4-gnutls-dev libevent-dev libgcrypt20-dev libgpg-error-dev \
    libgtk-3-0 liblapack-dev liblzo2-dev libopenblas-dev libreadline-dev libssl-dev libxml2-dev \
    libxslt1-dev libzmq3-dev mongodb-server moreutils ninja-build \
    pkg-config python-dev python-yaml python3-nose redis-server \
    rsync unzip wget gnupg lsb-release apt-utils software-properties-common
RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
RUN wget -O /root/libebtree.deb     https://bintray.com/sociomantic-tsunami/dlang/download_file?file_path=libebtree6_6.0.s7-rc5-xenial_amd64.deb
RUN wget -O /root/libebtree-dev.deb https://bintray.com/sociomantic-tsunami/dlang/download_file?file_path=libebtree6-dev_6.0.s7-rc5-xenial_amd64.deb
RUN dpkg -i /root/libebtree*.deb
