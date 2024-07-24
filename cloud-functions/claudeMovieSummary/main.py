from google.cloud import firestore
import functions_framework
import anthropic
import json

db = firestore.Client()

"""
Notes & to-dos:
- Still duplicates documents (meaning we also can't keep track of how many we've watched)
- Need to check on repeat functionality
- Need to check friends / trending functionality
- Need to check top_taste functionality

"""

@functions_framework.http
def getMovieCategories(request):
    """Saves watch history data to Firestore.
    Args:
        request (flask.Request): The request object.
    Returns:
        The response text.
    """
  
    request_json = request.get_json(silent=True)
    if not request_json:
        return "Invalid JSON", 400

    movies = request_json.get("movies", "")
    # userId = request_json.get("userId", "")

    client = anthropic.Anthropic(
        # defaults to os.environ.get("ANTHROPIC_API_KEY")
        api_key="YOUR_API_KEY_HERE",
    )


    message = client.messages.create(
        model="claude-3-haiku-20240307",
        max_tokens=1000,
        temperature=0,
        system="You are a movie critic AI. I want you to extract the genres / categories that best define the following movies, including some niche categories.",
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": "Here's an example. The list: Blade Runner, Forrest Gump, Darjeeling Limited, Bad Boys, Sherlock Holmes would return {\"categories\": [\"Science\", \"Fiction\", \"Family Drama\", \"Artistic\"].\n\nI've watched these movies: {{movies}}.\n\nAnalyze these movies, pick 4-7 categories that describe them, and output in JSON format with key \"categories\" (list). Only output the JSON.\n"
                    }
                ]
            }
        ]
    )
    

    print(message.content)

    # Parse the JSON string
    categories_json = json.loads(message.content[0].text)
    
    # Extract the categories array
    categories_array = categories_json["categories"]

    # Join the categories into a comma-separated string
    categories_string = ", ".join(categories_array)

    return categories_string