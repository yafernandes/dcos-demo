import os
import socket

from flask import Flask, Response, request
from flask_api import status
from kafka import KafkaConsumer

import ifaddr

app = Flask(__name__)


@app.route('/')
@app.route('/where')
def where():
    hostname = socket.gethostname()
    return f'Website running at host {hostname}\n'

@app.route('/health')
def health():
    return ('', status.HTTP_204_NO_CONTENT)

@app.route('/headers')
def headers():
    result = ""
    for header in request.headers:
        result = result + f'{header[0]}:\t{header[1]}\n'
    return Response(result, mimetype='text/plain')


@app.route('/crash')
def crash():
    func = request.environ.get('werkzeug.server.shutdown')
    if func is None:
        raise RuntimeError('Not running with the Werkzeug Server')
    func()
    return Response("Crashing server...\n", mimetype='text/plain')

@app.route('/ips')
def ips():
    result = ""
    for adapter in ifaddr.get_adapters():
        result = result + f'IPs of network adapter {adapter.nice_name}\n'
        for ip in adapter.ips:
            result = result + f'  - {ip.ip}/{ip.network_prefix}\n'

    return Response(result, mimetype='text/plain')

@app.route('/environment')
def environment():
    result = ""
    for env in os.environ:
        result = result + f'{env}: {os.environ.get(env)}\n'

    return Response(result, mimetype='text/plain')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=float(os.getenv('DW_PORT', '80')))
