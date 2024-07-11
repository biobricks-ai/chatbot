from flask import Flask
from pymongo import MongoClient
import json


app = Flask(__name__)
mongo_client = MongoClient("mongodb://localhost:27017")


@app.route("/")
def home():
    return json.dumps(mongo_client.server_info())
