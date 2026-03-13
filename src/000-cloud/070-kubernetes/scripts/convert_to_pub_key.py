import json
import sys
from base64 import b64encode

from Crypto.PublicKey import RSA
from Crypto.Util import asn1


def get_public_key(key_pair):
    pub_key = key_pair.publickey()
    seq = asn1.DerSequence([pub_key.n, pub_key.e])
    enc = seq.encode()
    return b64encode(enc).decode('utf-8')

key_pair = RSA.importKey(sys.argv[1])
print(json.dumps({
    'public_key': get_public_key(key_pair)
}))
