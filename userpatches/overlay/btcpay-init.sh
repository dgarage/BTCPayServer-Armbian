#!/bin/bash

set -e

source /opt/btcpay/btcpay-common.sh

if ! [ -f /etc/ssh/ssh_host_rsa_key ]; then
    dpkg-reconfigure openssh-server
    systemctl restart ssh
    echo -e "[ \e[32mOK\e[0m ] SSH Host keys generated"
fi

if ! mountpoint -q "$MOUNT_DIR"; then
    echo -e "[ \e[31mFailed\e[0m ] The mount directory $MOUNT_DIR does not exists, is the external drive plugged?"
    exit 1
fi

cd /root

$SETUP_MODE && rm -rf /root/.not_logged_in_yet
if $SETUP_MODE && [ -f "docker-images.tar" ]; then
    echo "Loading docker images..."
    docker load < "docker-images.tar"
    echo -e "[ \e[32mOK\e[0m ] Docker images loaded."
fi

if $SETUP_MODE && [ -f utxo-snapshot-*.tar ]; then
    BITCOIN_DATA_DIR=/var/lib/docker/volumes/generated_bitcoin_datadir/_data
    rm -rf "$BITCOIN_DATA_DIR"
    source /etc/profile.d/btcpay-env.sh
    echo "Loading UTXO set"
    SNAPSHOT_TAR="$(readlink -f utxo-snapshot-*.tar)"
    pushd . &> /dev/null
    cd btcpayserver-docker/contrib/FastSync
    ./load-utxo-set.sh $SNAPSHOT_TAR
    popd
    echo -e "[ \e[32mOK\e[0m ] UTXO Set preloaded."
fi

if $SETUP_MODE; then
    source /etc/profile.d/btcpay-env.sh
    . btcpay-setup.sh -i --no-systemd-reload
fi