# cliquebait
Test your DApps easily with this one weird trick!

## Overview
Cliquebait is a compact, fun, and easy to use Docker image that spins up a single-node Proof of Authority blockchain with Geth. It also generates some accounts and gives them ether, as well as unlocks them for use via Web3.

#### Why?
Cliquebait simplifies integration and accepting testing of smart contract applications by offering a clean ephemeral testing environment that closely resembles a real blockchain network. The key differences are a shorter block time (3 seconds by default) and a VERY high gas limit from the start.

#### But geth and parity have `--dev` now!
Very true! However, `geth` only has `--dev` mode as of v1.7.3, which also introduced slight changes to the JSON-RPC interface. Additionally, without careful configuration to avoid lazy block mining, you lose the ability to test things like waiting for block intervals and such.

## Quickstart
Simply run `docker run --rm -it -p 8545:8545 foamspace/cliquebait:latest` and connect to `http://localhost:8545/` using your Web3 interface of choice!

## Advanced Usage

### Give some ether to an account you control
If you're testing with MetaMask, for example, it's often helpful to have some ether allocated to the account that MetaMask has generated for you instead of having to import an ephemeral account.
You can pass a comma-separated of addresses in the `EXTERNAL_ALLOCS` environment variable to facilitate this. For example:

``docker run --rm -it -p 8545:8545 -e EXTERNAL_ALLOCS=0xAb0B142C3231e58cD7dAc89e91e6a5030E6Bd888` foamspace/cliquebait:latest``

or

``docker run --rm -it -p 8545:8545 -e EXTERNAL_ALLOCS=0x6Af35ddaA6555d357845Fcd5c2C6A322a784c85d,0xAb0B142C3231e58cD7dAc89e91e6a5030E6Bd888,0x7e2A25C20e536B5e8b834Bb84A53bC2F6E2Fc4bB` foamspace/cliquebait:latest``

The mechanism is fairly forgiving, it's case-insensitive and it's OK to omit the `0x` prefix as long as the rest of the address is valid.

### Create more (or less) accounts on startup
Simply supply the `ACCOUNTS_TO_CREATE` environment variable to `docker run`. The value must be numeric, in base 10, and at least 1

For example (creates 10 accounts on startup): `docker run --rm -it -p 8545:8545 -e ACCOUNTS_TO_CREATE=10 foamspace/cliquebait:latest`

### Define value of Wei to allocate to accounts on startup (default value is 1000 Ether)
Add a value of Wei to `DEFAULT_ALLOC_WEI` environment variable to `docker run`. It have to be a hexadecimal value.

For example (adds 222 Ether to each account on startup): `docker run --rm -it -p 8545:8545 -e DEFAULT_ALLOC_WEI=0xC08DE6FCB28B80000 foamspace/cliquebait:latest`

### Tweak the genesis block
One may mount a custom genesis block to `/cliquebait/cliquebait.json` to really fine tune their network's behavior. The only key thing to keep in mind is that the `extraData` field MUST remain the same. Cliquebait supplies the address of an ephemeral "authority" for the network on startup, and for the image to behave properly this must remain as-is.

Alternatively, you may pass in a genesis JSON directly via the `GENESIS_JSON` environment variable. The same rules regarding `extraData` apply!

### Use specific accounts
If you have an account JSON file compatible with geth's keystore, you may embed it into a specially crafted JSON file (see `sample-extra-accounts.json`) and supply it to cliquebait. You may then mount this file as `/extra-accounts.json`, and cliquebait will allocate ether and unlock the account for use in Web3. Note that this involves supplying the password to the account in plaintext, so be careful! If you prefer not to have the account unlocked, you may simply add an `alloc` in the genesis block.

### Persist the blockchain
If you want to keep your chain around for whatever reason, you may mount a volume or local folder to `/cbdata` inside the container. This implies that you won't be able to change the genesis block or change the number of created accounts without clearing the mount target and losing your chain (as these are all done when the blockchain is first fired up). However, this does mean that the accounts that get generated are much more easily accessible, as you can find the keystore directly on your local machine.

For example:

```shell
mkdir ~/my-persisted-cb
docker run --rm -it -p 8545:8545 -v ~/my-persisted-cb:/cbdata foamspace/cliquebait:latest
```

You will then be able to find the keystore Geth is using at `~/my-persisted-cb/ethereum/keystore`. To find the password for a given account,
you may look at `~/my-persisted-cb/_cliquebait/accounts` and `~/my-persisted-cb/_cliquebait/account-passwords`.

