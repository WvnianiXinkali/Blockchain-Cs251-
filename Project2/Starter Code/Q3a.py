from sys import exit
from bitcoin.core import Hash160
from bitcoin.core.script import *
from bitcoin.wallet import CBitcoinSecret

from lib.utils import *
from lib.config import (my_private_key, my_public_key, my_address,
                    faucet_address, network_type)
from Q1 import send_from_P2PKH_transaction

cust1_private_key = CBitcoinSecret(
    'cTRWhfb2eWz2aVoyg3R2e2vj7KcFMW4KY22gTfwFVzacQH9ccztX') #mhQmwVGMU4Km68hL3kSxu18PAreB7TCubY
cust1_public_key = cust1_private_key.pub
cust2_private_key = CBitcoinSecret(
    'cVcn4RhUpDgEGKKz5KDhaWF4VLyMXdo1PpZ6xp4DYGv3WDBwFVVf') #n4D3T1H7QWtHaYU3xCoKAwdbiTm1gYuoKe
cust2_public_key = cust2_private_key.pub
cust3_private_key = CBitcoinSecret(
    'cSTh8T7ZAMBQF6pk82KrU4YRmaNhWjx6J4amHoyYoMeUKRkc1GMx') #mkRvjNJTtJLmyheumynDCg4B5A9i7SCWhW
cust3_public_key = cust3_private_key.pub


######################################################################
# TODO: Complete the scriptPubKey implementation for Exercise 3

# You can assume the role of the bank for the purposes of this problem
# and use my_public_key and my_private_key in lieu of bank_public_key and
# bank_private_key.

Q3a_txout_scriptPubKey = [
    my_public_key,
    OP_CHECKSIGVERIFY,
    OP_1,
    cust1_public_key,
    cust2_public_key,
    cust3_public_key,
    OP_3,
    OP_CHECKMULTISIG,
]
######################################################################

if __name__ == '__main__':
    ######################################################################
    # TODO: set these parameters correctly
    amount_to_send = 0.00002745 # amount of BTC in the output you're sending minus fee
    txid_to_spend = (
        '4b751e2af8c67d64d5893c8bbea3d4262f9077d199ecb1851a672320177e730a')
    utxo_index = 4 # index of the output you are spending, indices start at 0
    ######################################################################

    response = send_from_P2PKH_transaction(amount_to_send, txid_to_spend, 
        utxo_index, P2SH_scriptPubKey(Q3a_txout_scriptPubKey), my_private_key, network_type)
    print(response.status_code, response.reason)
    print(response.text)
