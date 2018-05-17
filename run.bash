#!/bin/bash

VERCOMP='/cliquebait/vercomp.bash'
STRIPPED_GETH_VERSION=`echo $GETH_VERSION | sed s/v//`

export GETHROOT=/cbdata
export CBROOT=$GETHROOT/_cliquebait
export GETHDATADIR="$GETHROOT/ethereum"
export RPCARGS='--rpc --rpcaddr 0.0.0.0 --rpccorsdomain=* --rpcapi "admin,debug,eth,miner,net,personal,shh,txpool,web3" --ws --wsaddr 0.0.0.0 --wsorigins=* --wsapi "admin,debug,eth,miner,net,personal,shh,txpool,web3" '
export DEFAULT_PASSWORD_PATH=${DEFAULT_PASSWORD_PATH:-"/cliquebait/default-password"}
export ACCOUNTS_TO_CREATE=${ACCOUNTS_TO_CREATE:-"5"}

if $VERCOMP $STRIPPED_GETH_VERSION '>=' 1.8.0; then
	echo 'adding --rpcvhosts=* as we are in geth >= v1.8.0'
	export RPCARGS="${RPCARGS} --rpcvhosts=* "
fi


function make_account() {
	mkdir -p /tmp/cliquebait/make_account
	PASSWORD=`cat $DEFAULT_PASSWORD_PATH`
	ADDRESS=`geth account new --keystore /tmp/cliquebait/make_account --password $DEFAULT_PASSWORD_PATH 2>/dev/null | sed 's/Address: {\([A-Fa-f0-9]*\)}/\1/'`
	echo 0x$ADDRESS >> $CBROOT/accounts
	echo $PASSWORD >> $CBROOT/account-passwords
	mv /tmp/cliquebait/make_account/* $CBROOT/keystore
	echo "made account $ADDRESS"
}

function initialize_geth() {
	mkdir -p $GETHROOT

	# Echo back the genesis block, for debugging purposes.
	# It'll get echoed again before the geth node itself runs
	echo "Genesis block is:"
	cat $CBROOT/genesis.json

	# Write it to $GETHROOT/genesis.json
	cp $CBROOT/genesis.json $GETHROOT/genesis.json

	# Run geth init to initialize geth's storage
	# and feed it the genesis block we just persisted
	geth --datadir=$GETHDATADIR init $GETHROOT/genesis.json
}

# $1 = source genesis, $2 = the FULL address (with 0x)
function give_ether_in_genesis() {
	mkdir -p /tmp/cliquebait/give_ether_in_genesis
	BAREADDRESS=`echo $address | sed s/0x//`
	MOREALLOCS="{\"$BAREADDRESS\": {\"balance\": \"0x200000000000000000000000000000000000000000000000000000000000000\"}}"
	cat $1 | jq ".alloc += $MOREALLOCS" > /tmp/cliquebait/give_ether_in_genesis/new_genesis.json
	rm $1
	mv /tmp/cliquebait/give_ether_in_genesis/new_genesis.json $1
	rm -rf /tmp/cliquebait/give_ether_in_genesis
}

# this works because we have DEPLOY_ACCOUNT_ADDRESS in place of the actual hex in the extraData field of the genesis JSON
# that genesis block is specifically set up for a single-signer to be filled in at runtime by substituting
#
# todo: use jq to make sure it operates on extraData field specifically instead of just a dumb sed
#
# $1 = source genesis, $2 = the FULL address (with 0x)
function set_genesis_signer_address() {
	mkdir -p /tmp/cliquebait/set_genesis_signer_address
	BAREADDRESS=`echo $2 | sed s/0x//`
	cat $1 | sed "s/DEPLOY_ACCOUNT_ADDRESS/$BAREADDRESS/" > /tmp/cliquebait/set_genesis_signer_address/new_genesis.json
	rm $1
	mv /tmp/cliquebait/set_genesis_signer_address/new_genesis.json $1
	rm -rf /tmp/cliquebait/set_genesis_signer_address
}


function run_geth_bare() {
	set -e
	set -x
	geth --datadir=$GETHDATADIR $RPCARGS $@
}


function initialize_cliquebait() {
	if [[ "$ACCOUNTS_TO_CREATE" -lt "1" ]]; then
		echo "ACCOUNTS_TO_CREATE must be at least 1 (got $ACCOUNTS_TO_CREATE)"
		exit 1
	fi

	# move the base cliquebait genesis json to our working one
	if [ -z "$GENESIS_JSON" ]; then
	  cp /cliquebait/cliquebait.json $CBROOT/genesis.json
	else
	  echo "Using genesis base from environment variable"
	  echo "$GENESIS_JSON" > $CBROOT/genesis.json
	fi

	# geth init sometimes wipes our keystore, so we have to make a temporary one
	mkdir -p $CBROOT/keystore

	# make a bunch of accounts
	for n in `seq 1 $ACCOUNTS_TO_CREATE`; do make_account; done

	# Pre-seed the miner account first in case we have to seed in more passwords to unlock other accounts as well
	export DEPLOY_ACCOUNT_ADDRESS=`cat $CBROOT/accounts | head -1`

	# Store it for when we run geth
	echo $DEPLOY_ACCOUNT_ADDRESS > $CBROOT/etherbase

	# authorize the miner as the authority in genesis
	set_genesis_signer_address $CBROOT/genesis.json $DEPLOY_ACCOUNT_ADDRESS

	# load extra specified accounts
	if [ -s "/extra-accounts.json" ]; then
		# Add these accounts to the unlock list
		cat /extra-accounts.json | jq -r '"0x" + .[].keystore.address' >> $CBROOT/accounts
		# Seed the passwords to unlock the extra accounts
		cat /extra-accounts.json | jq -r '.[].password' >> $CBROOT/account-passwords

		# Put their blobs in the keystore directory
		for account in `cat extra-accounts.json| jq -c '.[]'`; do
			echo "$account" | jq .keystore > $CBROOT/keystore/0x`echo "$account" | jq -r .keystore.address`.json
		done
	fi

	# give all the loaded accounts tons of ether
	for address in `cat $CBROOT/accounts`; do give_ether_in_genesis $CBROOT/genesis.json $address; done

	# Save our chain ID for when we run geth later
	cat $CBROOT/genesis.json | jq .config.chainId > $CBROOT/chainid

	initialize_geth

	# move the $CBROOT/keystore where it belongs
	# has to happen after initialize_geth as geth init may wipe keystore!
	mv $CBROOT/keystore $GETHDATADIR/

	# finally, touch our "init complete" sentinel
	touch $CBROOT/.cliquebait-initialized
}

mkdir -p $CBROOT
if [ -e $CBROOT/.cliquebait-initialized ]; then
	echo Cliquebait appears to already be initialized, will not init
else
	echo Ephemeral or first-run of Cliquebait, will init
	initialize_cliquebait
fi

# figure out what accounts we need to unlock, and finally run cliquebait!
ACCOUNTS_TO_UNLOCK=`cat $CBROOT/accounts | tr '\n' ',' | sed s/,$//`
run_geth_bare --networkid="$(cat $CBROOT/chainid)" --mine --minerthreads 1 --etherbase $(cat $CBROOT/etherbase) \
              --unlock "$ACCOUNTS_TO_UNLOCK" --password $CBROOT/account-passwords $@
