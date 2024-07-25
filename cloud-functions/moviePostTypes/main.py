from google.cloud import firestore
import functions_framework
from datetime import datetime, timedelta
import time
import random


db = firestore.Client()

"""
Notes & to-dos:
- Still duplicates documents (meaning we also can't keep track of how many we've watched)
- Need to check on repeat functionality
- Need to check friends / trending functionality
- Need to check top_taste functionality

"""


@functions_framework.http
def createDailyPosts(request):
    """Creates repeated posts for users.
    Args:
        request (flask.Request): The request object.
    Returns:
        The response text.
    """
    
    users_with_netflix_auth = get_users_with_netflix_auth()
    if not users_with_netflix_auth:
        return "No users with Netflix auth found", 404
    
    total_posts_created = 0
    throwback_posts = 0
    repeated_posts = 0
    match_posts = 0
    recent_posts = 0
    liked_posts = 0
    trending_posts, trending_series_str = create_trending_posts()
    
    for user in users_with_netflix_auth:
        user_doc_ref = db.collection("users").document(user)
        user_doc = user_doc_ref.get()
        if not user_doc.exists:
            print(f"User document for {user} does not exist. Skipping.")
            continue

        user_doc_ref.update({"feed": []})

        throwback_posts += create_throwback_posts_for_user(user)
        repeated_posts += create_repeated_posts_for_user(user)
        match_posts += create_match_posts_for_user(user)
        liked_posts += create_liked_not_liked_posts_for_user(user)

        # add trending posts to the user's feed
        if trending_posts:
            user_feed = user_doc_ref.get().to_dict().get("feed", [])
            user_feed.extend(trending_posts)
            user_doc_ref.update({"feed": user_feed})

        
        # Check if the user's feed has less than 10 posts and fill it if necessary
        recent_posts += fill_feed_with_recent_posts(user)
        shuffle_user_feed(user)
        
    
    total_posts_created = throwback_posts + repeated_posts + match_posts + recent_posts
    
    return (f"Created {total_posts_created} posts for {len(users_with_netflix_auth)} users successfully. "
            f"Breakdown: {throwback_posts} throwback, {repeated_posts} repeated, "
            f"{match_posts} match, {liked_posts} liked, and {recent_posts} recent posts. "
            f"Trending shows: {trending_series_str}."), 200



def shuffle_user_feed(user):
    user_doc_ref = db.collection("users").document(user)
    user_doc = user_doc_ref.get()
    if not user_doc.exists:
        print(f"User document for {user} does not exist. Skipping.")
        return 0  # Return 0 as no posts were shuffled

    current_feed = user_doc.to_dict().get("feed", [])
    if not current_feed:
        print(f"No posts in the feed for user {user}. Skipping.")
        return 0  # Return 0 as no posts were shuffled

    random.shuffle(current_feed)
    user_doc_ref.update({"feed": current_feed})

    return len(current_feed) 


"""
Section 1: 
Create posts for users or their friends who repeated shows in last week
"""

def create_repeated_posts_for_user(user):
    new_post_ids = []
    
    # Query all watch history for the user, excluding documents with a post_type
    watch_history_query = db.collection("watchHistory").where("userId", "==", user)
    watch_history_docs = watch_history_query.stream()
    
    # Group watch history by series title
    series_watch_count = {}
    for doc in watch_history_docs:
        watch_data = doc.to_dict()
        # Skip documents that already have a post_type
        if "post_type" in watch_data:
            continue
        series_title = watch_data.get("seriesTitle")
        if series_title:
            if series_title not in series_watch_count:
                series_watch_count[series_title] = {"count": 0, "latest_doc": None}
            series_watch_count[series_title]["count"] += 1
            if not series_watch_count[series_title]["latest_doc"] or watch_data["date"] > series_watch_count[series_title]["latest_doc"].to_dict()["date"]:
                series_watch_count[series_title]["latest_doc"] = doc
    
    # Create posts for repeated shows
    for series_title, data in series_watch_count.items():
        if data["count"] > 1:
            latest_doc = data["latest_doc"]
            watch_data = latest_doc.to_dict()
            new_watch_data = watch_data.copy()
            new_watch_data.update({
                "post_type": "repeated_show",
                "numberEpisodes": data["count"],
                "originalPost": latest_doc.id
            })
            
            new_watch_ref = db.collection("watchHistory").document()
            new_watch_ref.set(new_watch_data)
            new_post_ids.append(new_watch_ref.id)
    
    if new_post_ids:
        update_user_and_friends_feed(user, new_post_ids)

    return len(new_post_ids) if new_post_ids else 0

        



"""
Section 2: 
Create posts for users or their friends watched X years ago
"""
def create_throwback_posts_for_user(user):
    new_post_ids = []
    current_timestamp = int(time.time() * 1000)  # Convert to milliseconds
    DAYS_AGO = 365


    for num in range(1, 6):  # Loop for 1, 2, 3, 4, 5 weeks ago
        # Calculate the timestamp for X weeks ago
        x_weeks_ago_timestamp = current_timestamp - num * DAYS_AGO * 24 * 60 * 60 * 1000  # Convert to milliseconds

        # Define a broader range around X weeks ago
        lower_bound_timestamp = x_weeks_ago_timestamp - 1 * 24 * 60 * 60 * 1000  # Convert to milliseconds
        upper_bound_timestamp = x_weeks_ago_timestamp + 1 * 24 * 60 * 60 * 1000  # Convert to milliseconds

        watch_history_docs = (
            db.collection("watchHistory")
            .where("userId", "==", user)
            .where("date", ">=", lower_bound_timestamp)
            .where("date", "<=", upper_bound_timestamp)
            .stream()
        )

        for doc in watch_history_docs:
            watch_data = doc.to_dict()
            # Skip documents that already have a post_type
            if "post_type" in watch_data:
                continue
            
            new_watch_data = watch_data.copy()
            new_watch_data.update({
                "post_type": "throwback",
                "originalDocument": doc.id,
                "years_ago": num
            })
            
            new_watch_ref = db.collection("watchHistory").document()
            new_watch_ref.set(new_watch_data)
            new_post_ids.append(new_watch_ref.id)

            update_user_and_friends_feed(user, new_post_ids)

    return len(new_post_ids) if new_post_ids else 0

"""
Section 3: 
Create posts for users or their friends who matched with each other
"""
def create_match_posts_for_user(user):
    new_post_ids = []
    current_timestamp = int(time.time() * 1000)  # Convert to milliseconds
    DAYS_AGO = 365 * 4
    lower_bound_timestamp = current_timestamp - DAYS_AGO * 24 * 60 * 60 * 1000  # Convert to milliseconds

    watch_history_docs = (
        db.collection("watchHistory")
        .where("userId", "==", user)
        .where("date", ">=", lower_bound_timestamp)
        .stream()
    )

    user_ref = db.collection("users").document(user)
    user_doc = user_ref.get()
    if user_doc.exists:
        user_data = user_doc.to_dict()
        friends_ids = get_limited_friends(user_data)
    else:
        friends_ids = []

    if not friends_ids:
        print(f"User {user} has no friends. Skipping match posts.")
        return 0

    for doc in watch_history_docs:
        watch_data = doc.to_dict()
        # Skip documents that already have a post_type
        if "post_type" in watch_data:
            continue
        title = watch_data.get("title")
        series_title = watch_data.get("seriesTitle")

        if series_title:
            friend_watch_history_docs = (
                db.collection("watchHistory")
                .where("userId", "in", friends_ids)
                .where("seriesTitle", "==", series_title)
                .stream()
            )
        else:
            friend_watch_history_docs = (
                db.collection("watchHistory")
                .where("userId", "in", friends_ids)
                .where("title", "==", title)
                .stream()
            )

        for friend_doc in friend_watch_history_docs:
            friend_watch_data = friend_doc.to_dict()
            # Skip friend documents that already have a post_type
            if "post_type" in friend_watch_data:
                continue
            new_post_data = watch_data.copy()
            new_post_data.update({
                "post_type": "match",
                "createdDate": current_timestamp,
                "originalDocument": doc.id,
                "matchedUsers": [user, friend_doc.id]
            })

            new_post_ref = db.collection("watchHistory").document()
            new_post_ref.set(new_post_data)
            new_post_ids.append(new_post_ref.id)

    if new_post_ids:
        update_user_and_friends_feed(user, new_post_ids)
    
    return len(new_post_ids) if new_post_ids else 0


"""
Section 4: 
Create posts for users of shows trending on the app
"""
def create_trending_posts():
    current_timestamp = int(time.time() * 1000)  # Convert to milliseconds
    DAYS_AGO = 7
    last_week_timestamp = current_timestamp - DAYS_AGO * 24 * 60 * 60 * 1000  # Convert to milliseconds

    trending_docs = db.collection("watchHistory").where("date", ">=", last_week_timestamp).stream()

    series_count = {}
    sample_docs = {}

    for doc in trending_docs:
        data = doc.to_dict()
        series_title = data.get("seriesTitle")
        if series_title:
            if series_title not in series_count:
                series_count[series_title] = 0
                sample_docs[series_title] = doc.id
            series_count[series_title] += 1

    top_series = sorted(series_count.items(), key=lambda x: x[1], reverse=True)[:3]

    new_post_ids = []
    trending_series_titles = []
    for series_title, _ in top_series:
        sample_doc_id = sample_docs[series_title]
        sample_doc = db.collection("watchHistory").document(sample_doc_id).get()
        sample_data = sample_doc.to_dict()

        new_post_data = {
            "seriesTitle": sample_data.get("seriesTitle"),
            "movieID": sample_data.get("movieID"),
            "image": sample_data.get("image"),
            "estRating": sample_data.get("estRating"),
            "imdbId": sample_data.get("imdbId"),
            "year": sample_data.get("year"),
            "post_type": "app_trending"
        }

        new_post_ref = db.collection("watchHistory").document()
        new_post_ref.set(new_post_data)
        new_post_ids.append(new_post_ref.id)
        trending_series_titles.append(series_title)

    trending_series_str = ", ".join(trending_series_titles)
    return new_post_ids, trending_series_str



"""
Section 5:
Create fan / not a fan posts for users or their friends
"""
def create_liked_not_liked_posts_for_user(user):
    new_post_ids = []
    watch_history_query = db.collection("watchHistory") \
        .where("userId", "==", user) \
        .order_by("date", direction=firestore.Query.DESCENDING) \
        .limit(10) \
        .stream()

    for doc in watch_history_query:
        watch_data = doc.to_dict()
        index = watch_data.get("index")
        duration = watch_data.get("duration")

        if index is None or duration is None:
            continue

        percent_watched = int((index / duration) * 100)

        if percent_watched < 10:
            new_watch_data = watch_data.copy()
            new_watch_data.update({
                "post_type": "not_liked",
                "originalDocument": doc.id,
                "percentWatched": percent_watched
            })
            new_watch_ref = db.collection("watchHistory").document()
            new_watch_ref.set(new_watch_data)
            new_post_ids.append(new_watch_ref.id)

        elif percent_watched > 90:
            new_watch_data = watch_data.copy()
            new_watch_data.update({
                "post_type": "liked",
                "originalDocument": doc.id,
                "percentWatched": percent_watched
            })
            new_watch_ref = db.collection("watchHistory").document()
            new_watch_ref.set(new_watch_data)
            new_post_ids.append(new_watch_ref.id)

    if new_post_ids:
        update_user_and_friends_feed(user, new_post_ids)

    return len(new_post_ids) if new_post_ids else 0
    



"""
Section 0: Helper functions
"""
def update_user_and_friends_feed(user, new_post_ids):
    if not new_post_ids:
        print(f"No new posts to add for user {user}")
        return

    user_ref = db.collection("users").document(user)
    user_doc = user_ref.get()
    if user_doc.exists:
        user_data = user_doc.to_dict()
        friends_ids = get_limited_friends(user_data)
        for friend_id in friends_ids:
            friend_ref = db.collection("users").document(friend_id)
            friend_doc = friend_ref.get()
            if friend_doc.exists:
                friend_data = friend_doc.to_dict()
                current_feed = friend_data.get("feed", [])
                updated_feed = list(set(current_feed + new_post_ids))
                friend_ref.set({"feed": updated_feed}, merge=True)
        
        current_user_feed = user_data.get("feed", [])
        updated_user_feed = list(set(current_user_feed + new_post_ids))
        user_ref.set({"feed": updated_user_feed}, merge=True)
    else:
        print(f"User document for {user} does not exist.")


def get_users_with_netflix_auth():
    user_ids = []
    users_query = db.collection("users").where("netflix_authURL", "!=", "").stream()
    for user_doc in users_query:
        user_ids.append(user_doc.id)
    return user_ids

def get_lower_bound_for_last_48_hours():
    current_timestamp = int(time.time())
    lower_bound_timestamp = current_timestamp - (48 * 60 * 60)  # 48 hours in seconds
    return lower_bound_timestamp

def get_date_range_for_years_ago(years):
    now = datetime.now()
    target_date = now.replace(year=now.year - years)
    start_date = target_date - timedelta(days=1)
    end_date = target_date + timedelta(days=1)
    return int(start_date.timestamp()), int(end_date.timestamp())

def get_watch_history_years_ago(user_id, start_timestamp, end_timestamp):
    watch_history_query = (
        db.collection("watchHistory")
        .where("userId", "==", user_id)
        .where("date", ">=", start_timestamp)
        .where("date", "<=", end_timestamp)
        .stream()
    )
    return list(watch_history_query)

def get_watch_history_for_user(user_id, start_timestamp, end_timestamp):
    watch_history_query = (
        db.collection("watchHistory")
        .where("userId", "==", user_id)
        .where("date", ">=", start_timestamp)
        .where("date", "<=", end_timestamp)
        .stream()
    )
    return list(watch_history_query)

def get_limited_friends(user_data, limit=10):
    return user_data.get("friends", [])[:limit]

def get_date_range_for_month_ago():
    now = datetime.now()
    one_month_ago = now - timedelta(days=1)
    start_date = one_month_ago - timedelta(days=1)
    end_date = one_month_ago + timedelta(days=1)
    return int(start_date.timestamp()), int(end_date.timestamp())

def get_watch_history_month_ago(user_id, start_timestamp, end_timestamp):
    watch_history_query = (
        db.collection("watchHistory")
        .where("userId", "==", user_id)
        .where("date", ">=", start_timestamp)
        .where("date", "<=", end_timestamp)
        .stream()
    )
    return list(watch_history_query)

"""
Section 6: Fill the rest of the user's feed with the most recent posts
"""
def fill_feed_with_recent_posts(user):
    user_doc_ref = db.collection("users").document(user)
    user_doc = user_doc_ref.get()
    if not user_doc.exists:
        print(f"User document for {user} does not exist. Skipping.")
        return 0  # Return 0 as no posts were added
    current_feed = user_doc.to_dict().get("feed", [])
    if len(current_feed) >= 10:
        return 0  # Return 0 as no posts were added

    user_data = user_doc.to_dict()
    friends = get_limited_friends(user_data)
    all_recent_posts = []

    # Get recent posts from the user
    user_watch_history_query = db.collection("watchHistory") \
        .where("userId", "==", user) \
        .order_by("date", direction=firestore.Query.DESCENDING) \
        .limit(20)
    user_watch_history_docs = user_watch_history_query.stream()
    all_recent_posts.extend([(doc.id, doc.to_dict()) for doc in user_watch_history_docs])

    # Get recent posts from friends
    for friend in friends:
        friend_watch_history_query = db.collection("watchHistory") \
            .where("userId", "==", friend) \
            .order_by("date", direction=firestore.Query.DESCENDING) \
            .limit(20)
        friend_watch_history_docs = friend_watch_history_query.stream()
        all_recent_posts.extend([(doc.id, doc.to_dict()) for doc in friend_watch_history_docs])

    # Sort all recent posts by date
    all_recent_posts.sort(key=lambda x: x[1]["date"], reverse=True)

    # Fetch originalDocument fields for current feed
    current_feed_docs = db.collection("watchHistory").where("originalDocument", "in", current_feed).stream()
    current_feed_originals = {doc.id: doc.to_dict().get("originalDocument") for doc in current_feed_docs}

    # Fill the user's feed with the most recent posts
    posts_to_add = [post for post in all_recent_posts if post[0] not in current_feed and post[0] not in current_feed_originals.values()]
    new_posts = posts_to_add[:10 - len(current_feed)]
    updated_feed = current_feed + [post[0] for post in new_posts]
    user_doc_ref.update({"feed": updated_feed})

    return len(new_posts)  # Return the number of new posts added