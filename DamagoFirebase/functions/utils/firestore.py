from firebase_admin import firestore

def get_db():
    return firestore.client()
