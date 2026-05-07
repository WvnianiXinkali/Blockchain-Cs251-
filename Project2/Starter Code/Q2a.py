from sys import exit
from bitcoin.core import Hash160
from bitcoin.core.script import *

from lib.utils import *
from lib.config import (my_private_key, my_public_key, my_address,
                    faucet_address, network_type)
from Q1 import send_from_P2PKH_transaction


first_half = 8892
second_half = 2644
######################################################################
# TODO: Complete the scriptPubKey implementation for Exercise 2
Q2a_txout_scriptPubKey = [
        # fill this in!
        OP_2DUP,
        OP_ADD,
        first_half,
        OP_EQUALVERIFY,
        OP_SUB,
        second_half,
        OP_EQUAL
    ]
######################################################################

if __name__ == '__main__':
    ######################################################################
    # TODO: set these parameters correctly
    amount_to_send = 0.00002745 # amount of BTC in the output you're sending minus fee
    txid_to_spend = (
        '4b751e2af8c67d64d5893c8bbea3d4262f9077d199ecb1851a672320177e730a')
    utxo_index = 5 # index of the output you are spending, indices start at 0
    ######################################################################

    response = send_from_P2PKH_transaction(
        amount_to_send, txid_to_spend, utxo_index,
        P2SH_scriptPubKey(Q2a_txout_scriptPubKey), my_private_key, network_type)
    print(response.status_code, response.reason)
    print(response.text)
