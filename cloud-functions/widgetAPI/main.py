import functions_framework
from google.cloud import firestore
from datetime import datetime

db = firestore.Client()

@functions_framework.http
def getLatestWidget(request):
    """Retrieves the most recent watch history entry from Firestore.
    Args:
        request (flask.Request): The request object.
    Returns:
        A JSON response with the formatted watch history data.
    """
    # Query the watchHistory collection for the document with the biggest date
    request_json = request.get_json(silent=True)
    friends = request_json.get('friends', ["otzDXhl6qScZFZWGQVBW"]) if request_json and request_json.get('friends') else ["otzDXhl6qScZFZWGQVBW"]

    query = db.collection("watchHistory").where("userId", "in", friends).order_by("date", direction=firestore.Query.DESCENDING).limit(1)
    docs = query.stream()

    for doc in docs:
        data = doc.to_dict()
        
        # Calculate time ago
        now = datetime.now()
        watch_time = datetime.fromtimestamp(data['date'] / 1000)  # Convert milliseconds to seconds
        time_diff = now - watch_time
        if time_diff.days > 0:
            time_ago = f"{time_diff.days} days ago"
        elif time_diff.seconds // 3600 > 0:
            time_ago = f"{time_diff.seconds // 3600} hours ago"
        else:
            time_ago = f"{time_diff.seconds // 60} minutes ago"

        user_id = data.get('userId', '')
        user_doc = db.collection("users").document(user_id).get()
        user_data = user_doc.to_dict() if user_doc.exists else {}

        # Format the response
        response = {
            "postID": doc.id,
            "title": data.get('title', ''),
            "seriesTitle": data.get('seriesTitle', ''),
            "timeAgo": time_ago,
            "previewImage": data.get('image', ''),
            "season": f"Season {data.get('season', '')}",
            "episode": f"Episode {data.get('episode', '')}",
            "profileImageURL": user_data.get('profileImageURL', ''),
            "profile": None
        }

        return response

    # If no documents found
    return {"error": "No watch history found"}, 404