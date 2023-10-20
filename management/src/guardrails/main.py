#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import types
from json import loads
from base64 import b64decode

# from google.cloud import logging as gclogger
# from google.cloud.logging.handlers import StructuredLogHandler
# from google.cloud.logging_v2.handlers import setup_logging

# from event_manager import EventManager

# client = gclogger.Client()
# client.setup_logging()
# handler = StructuredLogHandler()
# setup_logging(handler)

logging.getLogger().setLevel(logging.INFO)
logging.basicConfig(
    format="%(asctime)s [%(threadName)-0.12s] [%(levelname)-0.7s]  %(message)s"
)

# event_manager = EventManager()


def event_handler(event, context):
    if "data" in event:
        try:
            data_str = b64decode(event["data"]).decode("utf-8")
            data = loads(data_str)
            logging.info(f"Triggered by ${data_str}")
            # event_manager.process_event(data)
        except Exception as error:
            logging.error(f"Unhandled exception {error}")
            raise
    else:
        logging.error("No data found in event")
