from pymongo import MongoClient
from config import Config

client = None
db = None

def init_db():
    global client, db
    client = MongoClient(Config.MONGO_URI)
    db = client[Config.DB_NAME]
    return db

def get_db():
    if db is None:
        return init_db()
    return db

def close_db():
    if client:
        client.close()