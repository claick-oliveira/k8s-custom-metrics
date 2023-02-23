# -*- coding: utf-8 -*-
import datetime
import time
import os

from google.cloud import pubsub

PROJECT_ID = os.getenv('GOOGLE_CLOUD_PROJECT')
SUBSCRIPTION_NAME = "example-subscription"
SUBSCRIPTION = f"projects/{PROJECT_ID}/subscriptions/{SUBSCRIPTION_NAME}"


def main():
    print(f"Pulling messages from {SUBSCRIPTION_NAME}...")
    with pubsub.SubscriberClient() as subscriber:
        future = subscriber.subscribe(SUBSCRIPTION, callback)
        try:
            future.result()
        except KeyboardInterrupt:
            future.cancel()


def callback(message):
    print(f"[{datetime.datetime.now()}] Processing: {message.message_id}")
    time.sleep(30)
    print(f"[{datetime.datetime.now()}] Processed: {message.message_id}")
    message.ack()


if __name__ == '__main__':
    main()
