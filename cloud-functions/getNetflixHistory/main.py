from google.cloud import firestore
import functions_framework

db = firestore.Client()


# # # Function to save user's watch history to database

@functions_framework.http
def saveWatchHistory(request):
    """Saves watch history data to Firestore.
    Args:
        request (flask.Request): The request object.
    Returns:
        The response text.
    """
    request_json = request.get_json(silent=True)
    if not request_json:
        return "Invalid JSON", 400

    # Get userId from request or use default value
    user_id = request_json.get("userId", "BYu4pymRieSFI567fZm5ZR6eh5c2")

    consumptions = request_json.get("consumptions", [])

    # Find the most recent watch history entry for the user
    most_recent_query = db.collection("watchHistory").where("userId", "==", user_id).order_by("date", direction=firestore.Query.DESCENDING).limit(1)
    most_recent_docs = list(most_recent_query.stream())
    last_watched_date = most_recent_docs[0].to_dict()["date"] if most_recent_docs else 0

    for consumption in consumptions:
        raw_data = consumption.get("raw", {})
        inferred_data = consumption.get("inferred", {})

        date = raw_data.get("date", 0)  # Get the date from raw_data

        # Only process consumptions with a date more recent than the last watched date
        if date > last_watched_date:
            date_str = raw_data.get("dateStr")
            imdb_id = inferred_data.get("imdbId")
            episode = inferred_data.get("episode")

            # Check if document already exists
            query = db.collection("watchHistory").where("dateStr", "==", date_str).where("imdbId", "==", imdb_id).where("userId", "==", user_id)
            if episode:
                query = query.where("episode", "==", episode)
            existing_docs = query.stream()

            if not any(existing_docs):
                # Create new document
                doc_data = {
                    "userId": user_id,
                    "type": "netflix",
                    "timestamp": firestore.SERVER_TIMESTAMP,
                    "dataType": "Netflix",
                    "date": date,  # Add the date field to the document
                    **raw_data,
                    **inferred_data
                }

                # Add the original document
                db.collection("watchHistory").add(doc_data)

    return request_json


import functions_framework
from google.cloud import firestore
import requests
import json

db = firestore.Client()

# # # Function to schedule daily scrape of Netflix data

@functions_framework.http
def koodosNetflixTrigger(request):
    # API endpoint
    url = "https://www.shelf.im/api/data-mover/netflix"
    
    # API key
    api_key = "YOUR_API_KEY_HERE"
    
    # Headers
    headers = {
        "data-mover-api-key": api_key,
        "Content-Type": "application/json"
    }

    # Query all documents in the "users" collection
    users_ref = db.collection("users")
    docs = users_ref.stream()

    successful_users = []

    for doc in docs:
        user_data = doc.to_dict()
        
        # Check if secureNetflixId is present
        if "netflix_secureNetflixId" in user_data:
            # Prepare the payload
            payload = {
                "user_id": doc.id,
                "email": user_data.get("netflix_email", ""),
                "password": user_data.get("netflix_password", ""),
                "profile_id": user_data.get("netflix_profileId", ""),
                "auth_url": user_data.get("netflix_authURL", ""),
                "netflix_id": user_data.get("netflix_netflixId", ""),
                "secure_netflix_id": user_data.get("netflix_secureNetflixId", ""),
                "country": user_data.get("netflix_country", "")
            }

            # Convert payload to JSON string
            json_payload = json.dumps(payload)

            try:
                # Send POST request
                response = requests.post(url, headers=headers, data=json_payload)
                response.raise_for_status()  # Raise an exception for bad status codes
                print(f"Successfully sent data for user {doc.id}")
                successful_users.append(doc.id)
            except requests.exceptions.RequestException as e:
                print(f"Error sending data for user {doc.id}: {str(e)}")

    return json.dumps({"successful_users": successful_users}), 200


