"""Local-development stand-in for a Foundry Local /v1/predict deployment.

Accepts one JSON tensor item and returns {"score": <mean>} in the same items
envelope. Not for production use.
"""

import base64
import json
from http.server import BaseHTTPRequestHandler, HTTPServer


class PredictHandler(BaseHTTPRequestHandler):
    def do_POST(self) -> None:  # noqa: N802
        try:
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", "0"))))
            tensor = json.loads(base64.b64decode(body["items"][0]["data"]))
            values = [value for row in tensor for value in row]
            outputs = {"score": round(sum(values) / len(values), 6)}
        except (KeyError, IndexError, TypeError, ValueError, ZeroDivisionError):
            self.send_response(400)
            self.end_headers()
            return
        item = {
            "content_type": "application/json",
            "encoder": "base64",
            "data": base64.b64encode(json.dumps(outputs).encode()).decode(),
        }
        raw = json.dumps({"items": [item]}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def log_message(self, format: str, *args: object) -> None:  # noqa: A002
        pass


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8000), PredictHandler).serve_forever()  # noqa: S104
