import requests
import re
from bs4 import BeautifulSoup
from google.cloud import firestore
import functions_framework

db = firestore.Client()

"""
Notes & to-dos:
- Still duplicates documents (meaning we also can't keep track of how many we've watched)
- Need to check on repeat functionality
- Need to check friends / trending functionality
- Need to check top_taste functionality

"""

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
                # Call the functions from main.py with error handling
                series_title = raw_data.get("seriesTitle", "")
                video_title = raw_data.get("videoTitle", "")
                query = series_title if series_title else video_title
                is_series = bool(series_title)
                year = inferred_data.get("year", "")
                title_number = inferred_data.get("imdbId", "")

                try:
                    youtube_trailer_url = get_youtube_trailer_url(query)
                except Exception:
                    youtube_trailer_url = None

                try:
                    tomatometer_score = get_tomatometer_score(query, is_series)
                except Exception:
                    tomatometer_score = None

                try:
                    imdb_rating = get_imdb_rating(title_number)
                except Exception:
                    imdb_rating = None

                try:
                    metacritic_rating = get_metacritic_rating(query, year)
                except Exception:
                    metacritic_rating = None

                # Create new document
                doc_data = {
                    "userId": user_id,
                    "type": "netflix",
                    "timestamp": firestore.SERVER_TIMESTAMP,
                    "dataType": "Netflix",
                    "date": date,  # Add the date field to the document
                    **raw_data,
                    **inferred_data,
                    "youtubeTrailerUrl": youtube_trailer_url,
                    "tomatometerScore": tomatometer_score,
                    "imdbRating": imdb_rating,
                    "metacriticRating": metacritic_rating
                }

                # Add the original document
                db.collection("watchHistory").add(doc_data)

    return request_json

def get_metacritic_rating(query, year=None):
    query = query.replace(" ", "%20")  # Replace spaces in the query with %20 for URL encoding
    url = f"https://www.metacritic.com/search/{query}/"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'}
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.content, "html.parser")
    
    # Find all result blocks
    results = soup.find_all('a', class_='c-pageSiteSearch-results-item')
    
    for result in results:
        # Check if the year matches
        if year:
            year_span = result.find('span', class_='u-text-uppercase')
            if year_span and year_span.text.strip() == str(year):
                rating_div = result.find('div', class_='c-siteReviewScore_medium')
                if rating_div:
                    rating_span = rating_div.find('span')
                    if rating_span:
                        return rating_span.text.strip()
    
    # If no matching year is found, return the first result
    if results:
        first_result = results[0]
        rating_div = first_result.find('div', class_='c-siteReviewScore_medium')
        if rating_div:
            rating_span = rating_div.find('span')
            if rating_span:
                return rating_span.text.strip()
    
    return None


def get_imdb_rating(title_number):
    url = f"https://www.imdb.com/title/{title_number}/"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'}
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.content, "html.parser")
    
    # Extract the content from the meta tag with property 'og:title'
    meta_tag = soup.find('meta', property='og:title')
    if meta_tag and 'content' in meta_tag.attrs:
        content = meta_tag['content']
        # Extract the rating from the content
        rating = content.split('⭐')[1].split('|')[0].strip()
        return rating
    else:
        return None


def get_tomatometer_score(query, isSeries):
    query = query.replace(" ", "%20")  # Replace spaces in the query with %20 for URL encoding
    url = f"https://www.rottentomatoes.com/search?search={query}"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'}
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.content, "html.parser")
    
    # print(soup)

    if not isSeries:
        first_result = soup.find('search-page-result')  # Look for the first search result block

        # print("First result: ", first_result)
        if first_result:
            first_media_row = first_result.find('search-page-media-row')  # Find the first media row
            if first_media_row:
                score = first_media_row.get('tomatometerscore')  # Get the tomatometerscore attribute
                return score if score else None
            else:
                return None
        else:
            return None
    else:
        tv_shows_section = soup.find('search-page-result', {'type': 'tvSeries'})
        if tv_shows_section:
            first_media_row = tv_shows_section.find('search-page-media-row')
            if first_media_row:
                score = first_media_row.get('tomatometerscore')
                return score if score else None
        return None
        


def get_youtube_trailer_url(search_query):
    # Convert search query to YouTube search URL
    search_query = search_query + " trailer netflix"
    base_url = "https://www.youtube.com/results?search_query="
    search_url = base_url + search_query.replace(" ", "+")
    
    # Fetch the search results page
    response = requests.get(search_url)
    if response.status_code != 200:
        raise Exception("Failed to fetch YouTube search results")
    
    # Use regex to find the first /watch URL in the commandMetadata section
    match = re.search(r'\"commandMetadata\":{\"webCommandMetadata\":{\"url\":\"(/watch\?v=[^\"]+)', response.text)
    if match:
        return "https://www.youtube.com" + match.group(1).replace('\\u0026', '&')
    
    raise Exception("No video found")

