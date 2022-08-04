import json
import sys
import ssl
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from subprocess import check_output

class Client:
    def __init__(self, keyFile, serviceUrl, insecure=False):
        self.keyFile = keyFile
        self.serviceUrl = serviceUrl
        self.insecure = insecure

    def call(self, method, params=None):
        req = {
            'jsonrpc': '2.0',
            'id': None,
            'method': method,
        }
        if params is not None:
            req['params'] = params
        req = json.dumps(req).encode('utf-8')

        signature = check_output(
            ['ssh-keygen', '-q', '-Y', 'sign', '-f', self.keyFile, '-n', 'api', '-'],
            input=req).decode('utf-8')

        # print(req)
        # print(signature)

        context = ssl.create_default_context()
        if self.insecure:
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
        try:
            res = urlopen(Request(self.serviceUrl,
                                  data=req,
                                  headers={
                                      'Authorization': 'SSH ' + signature.replace('\n', ''),
                                      'Content-Type': 'application/json',
                                  },
                                  method='POST'),
                          context=context)
        except HTTPError as exn:
            print(json.dumps({
                'http': exn.code,
                'reason': exn.reason,
            }), file=sys.stderr)
            sys.exit(1)

        if res.status == 200:
            res = json.loads(res.read().decode('utf-8'))
            if 'result' in res:
                return res['result']
            else:
                print(json.dumps(res), file=sys.stderr)
                sys.exit(1)
        elif res.status >= 200 and res.status <= 299:
            return None
        else:
            print(json.dumps({
                'http': res.status,
                'reason': res.reason,
            }), file=sys.stderr)
            sys.exit(1)
