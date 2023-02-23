# -*- coding: utf-8 -*-
import os

from google.cloud import pubsub

PROJECT_ID = os.getenv('GOOGLE_CLOUD_PROJECT')
TOPIC_NAME = "example-topic"
TOPIC = f"projects/{PROJECT_ID}/topics/{TOPIC_NAME}"


def main():
    print(f"Publishing messages to {TOPIC_NAME}...")
    while True:
        with pubsub.PublisherClient() as publisher:
            future = publisher.publish(
              TOPIC,
              b'My Message!',
              spam='messages'
            )
            try:
                future.result()
            except KeyboardInterrupt:
                future.cancel()


if __name__ == '__main__':
    main()
