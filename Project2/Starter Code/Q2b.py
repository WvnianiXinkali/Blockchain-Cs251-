from sys import exit
from bitcoin.core.script import *

from lib.utils import *
from lib.config import (my_private_key, my_public_key, my_address,
                    faucet_address, network_type)
from Q1 import P2PKH_scriptPubKey
from Q2a import Q2a_txout_scriptPubKey, P2SH_scriptPubKey


######################################################################
# TODO: set these parameters correctly
amount_to_send = 0.00001745 # amount of BTC in the output you're sending minus fee
txid_to_spend = (
        '43cbb10462850fc35c577e71fd7c9bf11f578e6753a03971973c9f9079e12d97')
utxo_index = 0 # index of the output you are spending, indices start at 0
######################################################################

txin_redeemScript = Q2a_txout_scriptPubKey
txin_scriptPubKey = P2SH_scriptPubKey(txin_redeemScript)
######################################################################
# TODO: implement the scriptSig for redeeming the transaction created
# in  Exercise 2a.
x = 5768
y = 3124
txin_scriptSig = [
        # fill this in!
        x,
        y,
        CScript(txin_redeemScript)
]
######################################################################
txout_scriptPubKey = P2PKH_scriptPubKey(faucet_address)

response = send_from_custom_transaction(
    amount_to_send, txid_to_spend, utxo_index,
    txin_scriptPubKey, txin_scriptSig, txout_scriptPubKey, network_type)
print(response.status_code, response.reason)
print(response.text)
