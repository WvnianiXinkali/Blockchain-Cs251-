import requests

from bitcoin.core import b2x, lx, COIN, COutPoint, CMutableTxOut, CMutableTxIn, CMutableTransaction, Hash160
from bitcoin.core.script import (
    CScript, SignatureHash, SIGHASH_ALL, OP_HASH160, OP_EQUAL
)
from bitcoin.core.scripteval import VerifyScript, SCRIPT_VERIFY_P2SH

def P2SH_scriptPubKey(redeem_script):
    return [OP_HASH160, Hash160(CScript(redeem_script)), OP_EQUAL]

def send_from_custom_transaction(
        amount_to_send, txid_to_spend, utxo_index,
        txin_scriptPubKey, txin_scriptSig, txout_scriptPubKey, network):
    txout = create_txout(amount_to_send, txout_scriptPubKey)
    txin = create_txin(txid_to_spend, utxo_index)
    new_tx = create_signed_transaction(txin, txout, txin_scriptPubKey,
                                       txin_scriptSig)
    return broadcast_transaction(new_tx, network)

def create_txin(txid, utxo_index):
    return CMutableTxIn(COutPoint(lx(txid), utxo_index))

def create_txout(amount, scriptPubKey):
    return CMutableTxOut(amount*COIN, CScript(scriptPubKey))

def create_OP_CHECKSIG_signature(txin, txout, txin_scriptPubKey, seckey):
    tx = CMutableTransaction([txin], [txout])
    sighash = SignatureHash(CScript(txin_scriptPubKey), tx,
                            0, SIGHASH_ALL)
    sig = seckey.sign(sighash) + bytes([SIGHASH_ALL])
    return sig

def create_signed_transaction(txin, txout, txin_scriptPubKey,
                              txin_scriptSig):
    tx = CMutableTransaction([txin], [txout])
    txin.scriptSig = CScript(txin_scriptSig)
    VerifyScript(txin.scriptSig, CScript(txin_scriptPubKey),
                 tx, 0, (SCRIPT_VERIFY_P2SH,))
    return tx

def broadcast_transaction(tx, network):
    raw_transaction = b2x(tx.serialize())

    if network == 'btc-test3':
        url = 'https://blockstream.info/testnet/api/tx'
        headers = {'Content-Type': 'text/plain'}
        data = raw_transaction
    elif network == 'bcy-test':
        url = 'https://api.blockcypher.com/v1/bcy/test/txs/push'
        headers = {'content-type': 'application/x-www-form-urlencoded'}
        data = '{"tx": "%s"}' % raw_transaction
    else:
      raise InvalidArgumentException("Network must be one of either 'btc-test3', 'bcy-test'")

    return requests.post(
        url,
        headers=headers,
        data=data)
