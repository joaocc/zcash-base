FROM phusion/baseimage:0.9.19

# from https://github.com/sneak/zcash/Dockerfile

ENV HOME   /var/lib/zcash \
    GITSRC /usr/local/src/zcash \
    GITURL https://github.com/sneak/zcash

# homedir is a data volume
VOLUME [ "/var/lib/zcash" ]

# install build deps
RUN \
    echo "# create user and set homedir" && \
    useradd -s /bin/bash -m -d /var/lib/zcash zcash && \
    \
    echo "# install build deps" && \
    apt-get update && \
    apt-get install -y \
        autoconf \
        automake \
        bsdmainutils \
        build-essential \
        g++-multilib \
        git \
        libc6-dev \
        libtool \
        m4 \
        ncurses-dev \
        pkg-config \
        python \
        time \
        unzip \
        wget \
        zlib1g-dev \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    \
    echo "# add source" && \
    git clone --depth 1 ${GITURL} ${GITSRC} && \
    \
    echo "# download dependencies" && \
    cd ${GITSRC}/depends && \
    make download-linux && \
    \
    echo "# build and install to /usr/local/bin" && \
    echo "# FIXME build and run tests here too" && \
    mkdir -p /etc/zcash && \
    ln -s /etc/zcash $HOME/.zcash-params && \
    cd ${GITSRC} && \
    bash ./zcutil/fetch-params.sh && \
    chmod a+rx /etc/zcash && \
    chmod a+r /etc/zcash/* && \
    time ./zcutil/build.sh -j$(nproc) && \
    make install && \
    cp -av ./depends/x86_64-unknown-linux-gnu/bin/* /usr/local/bin && \
    \
    \
    echo "# create cache dir and set ownership" && \
    mkdir /var/cache/zcash && \
    chown zcash:zcash -R /var/cache/zcash && \
    \
    echo "# set ownership on keys" && \
    chmod a+rX -R /etc/zcash && \
    \
    echo "set ownership on homedir contents" && \
    chown zcash:zcash -R /var/lib/zcash && \
    \
    echo "# set up service to run on container start" && \
    mkdir -p /etc/service/zcash && \
    cp ${GITSRC}/contrib/init/zcashd.run /etc/service/zcash/run && \
    chmod +x /etc/service/zcash/run && \
    \
    \
    echo "cleanup" && \
    rm /var/lib/zcash/.zcash-params && \
    cd / && \
    rm -rf ${GITSRC} && \
    rm -rf /var/lib/zcash/.ccache && \
    \
    echo "# remove build deps" && \
    apt-get remove -y \
        autoconf \
        automake \
        bsdmainutils \
        build-essential \
        g++-multilib \
        git \
        libc6-dev \
        libtool \
        m4 \
        ncurses-dev \
        pkg-config \
        python \
        unzip \
        wget \
        zlib1g-dev \
    && \
    apt-get autoremove -y && \
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /var/cache/* \
        /usr/include \
        /usr/local/include \


# ports: RPC & P2P
EXPOSE 8232 8233
