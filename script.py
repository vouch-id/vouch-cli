import argparse
import jsonrpc

class Script:
    def __init__(self, method, keyFile='keyFile'):
        self.method = method
        self.parser = argparse.ArgumentParser()
        self.parser.add_argument('--insecure', action=argparse.BooleanOptionalAction)
        self.parser.add_argument('serviceUrl')
        self.keyFile = keyFile
        if keyFile:
            self.parser.add_argument(keyFile)
        self._args = None

    def args(self):
        if self._args is None:
            self._args = self.parser.parse_args()
        return self._args

    def run(self, params=None):
        args = self.args()
        return jsonrpc.Client(getattr(args, self.keyFile) if self.keyFile else None,
                              args.serviceUrl,
                              insecure=args.insecure).call(
                                  self.method,
                                  params)
