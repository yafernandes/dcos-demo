import os
import random
import socket
import sys
import time

from kafka import KafkaProducer, KafkaClient
from kafka.admin import KafkaAdminClient, NewTopic

bootstrap_server = os.getenv('KP_BOOTSTRAP_SERVER', 'broker.kafka.l4lb.thisdcos.directory:9092')
# bootstrap_server = os.getenv('KP_BOOTSTRAP_SERVER', '192.168.1.225:9092')
topic_name = os.getenv('KP_TOPIC', 'page_views')
delay = float(os.getenv('KP_DELAY_BETWEEN_MESSAGES', '0.0007'))
num_partitions = int(os.getenv('KP_NUMBER_OF_PARTITIONS', '3'))
hostname = socket.gethostname()

sys.stdout.write(f'Using {bootstrap_server} as bootstrap.\n')
sys.stdout.write(f'Topic is {topic_name}.\n')
sys.stdout.write(f'Message delay is {delay}.\n')
sys.stdout.write(f'Number of partitions is {num_partitions}.\n')
sys.stdout.flush()

admin = KafkaAdminClient(bootstrap_servers = bootstrap_server)
topic = NewTopic(topic_name, num_partitions, 1)
try:
    admin.create_topics([topic])
except:
    pass

producer = KafkaProducer(bootstrap_servers = bootstrap_server)
sys.stdout.write('Starting infinite loop.\n')
sys.stdout.flush()
while True:
    user = random.randint(1, 25)
    page = random.randint(1, 10)
    producer.send(
        topic_name, key=f'user{user}'.encode(), value=f'{{"producer": "{hostname}", name": "user{user}", "view":"page{page}"}}'.encode())
    if (delay > 0):
        time.sleep(delay)
