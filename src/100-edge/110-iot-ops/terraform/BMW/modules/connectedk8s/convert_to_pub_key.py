import json
from Crypto.Util import asn1
from Crypto.PublicKey import RSA
from base64 import b64encode
import sys


def get_public_key(key_pair):
    pubKey = key_pair.publickey()
    seq = asn1.DerSequence([pubKey.n, pubKey.e])
    enc = seq.encode()
    return b64encode(enc).decode('utf-8')


key_pair = RSA.importKey(sys.argv[1])
print(json.dumps({
    'public_key': get_public_key(key_pair)
}))