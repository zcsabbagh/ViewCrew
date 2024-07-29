import requests
import re
from bs4 import BeautifulSoup
from google.cloud import firestore
import functions_framework


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

query = "3 body problem"
url = get_youtube_trailer_url(query)
print("First non-ad video URL:", url)