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

### MetaMask
With few tweaks you will be able to run `cliquebait` together with [`MetaMask`](https://metamask.io/).

Here are two common questions and answers for doing that:

#### How to add a MetaMask account to `cliquebait`?
Create a `cliquebait.json` in your project folder and add following content to it (_Note:_ Replace `METAMASK_ACCOUNT_ADDRESS` with the address of your MetaMask account).

```
{
  "config": {
    "chainId": 420123,
    "homesteadBlock": 1,
    "eip150Block": 2,
    "eip150Hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "eip155Block": 3,
    "eip158Block": 3,
    "byzantiumBlock": 4,
    "clique": {
      "period": 1,
      "epoch": 30000
    }
  },
  "nonce": "0x0",
  "timestamp": "0x59dbb35a",
  "extraData": "0x0000000000000000000000000000000000000000000000000000000000000000DEPLOY_ACCOUNT_ADDRESS0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "gasLimit": "0x8000000",
  "difficulty": "0x1",
  "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "coinbase": "0x0000000000000000000000000000000000000000",
  "alloc": {
      "METAMASK_ACCOUNT_ADDRESS": {
        "balance": "0x200000000000000000000000000000000000000000000000000000000000000"
      }
  },
  "number": "0x0",
  "gasUsed": "0x0",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000"
}

```

Run `cliquebait` pointing to the `cliquebait.json` you created before ^ (_Note:_ Replace `YOUR_PROJECT_FOLDER` with the absolute path to your `cliquebait.json` ).

```
sudo docker run --rm -it -p 8545:8545 -v YOUR_PROJECT_FOLDER/cliquebait.json:/cliquebait/cliquebait.json foamspace/cliquebait:latest
```

Don't forget to connect MetaMask to `http://localhost:8545/` as described in [MetaMask Help -> Using a Local Node](https://metamask.helpscoutdocs.com/article/29-using-a-local-node).



#### How to import the primary account created by `cliquebait` to MetaMask?
Run `cliquebait` as described in [Quickstart](#quickstart):

```
sudo docker run --rm -it -p 8545:8545 foamspace/cliquebait:latest
```

Check the `CONTAINER ID` of your running docker container:
```
sudo docker ps
CONTAINER ID        IMAGE                         COMMAND                  CREATED             STATUS              PORTS                                          NAMES
16270c43261f        foamspace/cliquebait:latest   "/cliquebait/run.bash"   31 minutes ago      Up 31 minutes       0.0.0.0:8545->8545/tcp, 30303/tcp, 30303/udp   mystifying_pike
```

With that `CONTAINER ID` you can grab the private key of the primary (first) account as follow (Note: Replace `CLIQUEBAIT_CONTAINER_ID` with the `CONTAINER ID` you have checked before ^)
```
sudo docker exec -i -t CLIQUEBAIT_CONTAINER_ID /bin/bash -c "cd /gethdata/ethereum/keystore/ && ls . | head -1 | xargs cat"
```

The output will be similar like this:

```
{"address":"744832f58aec17a643083472c4a09c01b259c4a8","crypto":{"cipher":"aes-128-ctr","ciphertext":"489bde555f6a4838131f54b21955d7cea4a9f8b00f495c5e9e713fb47edb5f5a","cipherparams":{"iv":"6d6d4e37f5bd27cb7fae9ddbfce33660"},"kdf":"scrypt","kdfparams":{"dklen":32,"n":262144,"p":1,"r":8,"salt":"8d172aa5007ce7e6583e062a3f8f63248f3a4a90e8ece4e658cb1b097d10c9d4"},"mac":"a6a3ba2f2dddfd582d5b7bd50523f0a03f08fc17028b722dc688c89350406dc6"},"id":"ab500276-d669-444c-8869-fb621099b09d","version":3}
```

Copy that `JSON` output (everything from `{"address": ...` to `... "version":3}` and save it as a `primary-account.json` file anywhere on your machine. You do need that `primary-account.json` file to import the primary account at MetaMask as described in [MetaMask Help -> Import Accounts](https://metamask.helpscoutdocs.com/article/19-importing-accounts).

After a successful import of the primary account make sure that MetaMask is connected to `http://localhost:8545/` as described in [MetaMask Help -> Using a Local Node](https://metamask.helpscoutdocs.com/article/29-using-a-local-node).
