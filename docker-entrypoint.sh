#!/usr/bin/env sh
set -ex

# Network switch
if [ "$TESTNET" = true ] || [ "$ELECTRUM_NETWORK" = "testnet" ]; then
  FLAGS='--testnet'
elif [ "$ELECTRUM_NETWORK" = "regtest" ]; then
  FLAGS='--regtest'
elif [ "$ELECTRUM_NETWORK" = "simnet" ]; then
  FLAGS='--simnet'
fi

# Graceful shutdown
trap 'pkill -TERM -P1; electrum stop; exit 0' SIGTERM


# Set config
electrum $FLAGS --offline setconfig rpcuser ${ELECTRUM_USER}
electrum $FLAGS --offline setconfig rpcpassword ${ELECTRUM_PASSWORD}
electrum $FLAGS --offline setconfig rpchost 0.0.0.0
electrum $FLAGS --offline setconfig rpcport 7000

WALLETS_PATH="$(pwd)/.electrum/wallets/default_wallet"

# Check load wallet or create
if [ -f "$WALLETS_PATH" ]; then
  echo "Wallet already exists, creation is skipped!"
else
  echo "Creating wallet.."
  electrum $FLAGS --offline create > /dev/null
fi

# disable walllet change addresses
# (using temporary file because "jq FILE > FILE" is not safe)
jq ". + {use_change:false}" $WALLETS_PATH > $WALLETS_PATH.temp
mv $WALLETS_PATH.temp $WALLETS_PATH

# Run application
electrum $FLAGS daemon -d
electrum $FLAGS load_wallet && \
  echo "Wallet loaded" || \
  (echo "Could not laod wallet" && exit 1)

# Wait forever
while true; do
  tail -f /dev/null & wait ${!}
done
