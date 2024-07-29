import requests
from bs4 import BeautifulSoup

# def get_tomatometer_score(query):
#     query = query.replace(" ", "%20")  # Replace spaces in the query with %20 for URL encoding
#     url = f"https://www.rottentomatoes.com/search?search={query}"
#     headers = {
#         'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'}
#     response = requests.get(url, headers=headers)
#     soup = BeautifulSoup(response.content, "html.parser")
    
#     # print(soup)
#     first_result = soup.find('search-page-result')  # Look for the first search result block
    
#     # print("First result: ", first_result)
#     if first_result:
#         first_media_row = first_result.find('search-page-media-row')  # Find the first media row
#         if first_media_row:
#             score = first_media_row.get('tomatometerscore')  # Get the tomatometerscore attribute
#             return score if score else None
#         else:
#             return None
#     else:
#         return None

# # Example usage
# query = "Bad Boys"
# score = get_tomatometer_score(query)
# print(f"Tomatometer score for '{query}': {score}")

# def get_imdb_rating(title_number):
#     url = f"https://www.imdb.com/title/{title_number}/"
#     headers = {
#         'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'}
#     response = requests.get(url, headers=headers)
#     soup = BeautifulSoup(response.content, "html.parser")
    
#     # Extract the content from the meta tag with property 'og:title'
#     meta_tag = soup.find('meta', property='og:title')
#     if meta_tag and 'content' in meta_tag.attrs:
#         content = meta_tag['content']
#         # Extract the rating from the content
#         rating = content.split('⭐')[1].split('|')[0].strip()
#         return rating
#     else:
#         return None

# # https://www.imdb.com/title/tt0085210/?ref_=fn_al_tt_5
# title_number = "tt0085210"
# rating = get_imdb_rating(title_number)
# print(f"IMDb rating for title '{title_number}': {rating}")


# def get_metacritic_rating(query, year=None):
#     query = query.replace(" ", "%20")  # Replace spaces in the query with %20 for URL encoding
#     url = f"https://www.metacritic.com/search/{query}/"
#     headers = {
#         'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'}
#     response = requests.get(url, headers=headers)
#     soup = BeautifulSoup(response.content, "html.parser")
#     print(soup)
    
#     # Find all result blocks
#     results = soup.find_all('a', class_='c-pageSiteSearch-results-item')
    
#     for result in results:
#         # Check if the year matches
#         if year:
#             year_span = result.find('span', class_='u-text-uppercase')
#             if year_span and year_span.text.strip() == str(year):
#                 rating_div = result.find('div', class_='c-siteReviewScore_medium')
#                 if rating_div:
#                     rating_span = rating_div.find('span')
#                     if rating_span:
#                         return rating_span.text.strip()
    
#     # If no matching year is found, return the first result
#     if results:
#         first_result = results[0]
#         rating_div = first_result.find('div', class_='c-siteReviewScore_medium')
#         if rating_div:
#             rating_span = rating_div.find('span')
#             if rating_span:
#                 return rating_span.text.strip()
    
#     return None

# # Example usage
# query = "bad boys"
# year = 1995
# rating = get_metacritic_rating(query, year)
# print(f"Metacritic rating for '{query}' ({year}): {rating}")


# https://www.themoviedb.org/



from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup

# Setup Chrome options
chrome_options = Options()
chrome_options.add_argument("--headless")  # Ensure GUI is off
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")

# Set path to chromedriver as per your configuration
webdriver_service = Service('/Users/zane/Downloads/chromedriver-mac-arm64/chromedriver')  # Change this to your chromedriver path

# Choose Chrome Browser
driver = webdriver.Chrome(service=webdriver_service, options=chrome_options)




def get_first_non_ad_youtube_url(query):
    # Open YouTube
    driver.get("https://www.youtube.com")

    # Find the search box and search for the query
    search_box = driver.find_element(By.NAME, "search_query")
    search_box.send_keys(query)
    search_box.send_keys(Keys.RETURN)

    # Wait for search results to load
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.ID, "contents"))
    )

    # Parse the page source with BeautifulSoup
    soup = BeautifulSoup(driver.page_source, 'html.parser')
    # print(soup)

    video_links = []
    for a in soup.find_all('a', href=True):
        href = a['href']
        if '/watch?v=' in href and not href.startswith('/ads/'):
                video_links.append("https://www.youtube.com" + href)
    print(video_links)
    
    # for link in video_links:
    #     # Check if the link is an ad by checking for 'aria-label'
    #     if 'aria-label' not in link.attrs:
    #         first_non_ad_url = "https://www.youtube.com" + link['href']
    #         break
    
    # return first_non_ad_url

# Example usage
query = "Bad boys: ride or die movie trailer"
url = get_first_non_ad_youtube_url(query)
print("First non-ad video URL:", url)

# Close the browser
driver.quit()


# import requests
# from bs4 import BeautifulSoup

# def get_tmdb_poster(query):
#     # Encode the query for URL
#     query = requests.utils.quote(query)
#     url = f"https://www.themoviedb.org/search?query={query}"
    
#     headers = {
#         'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
#         'Accept-Language': 'en-US,en;q=0.9',
#         'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
#         'Referer': 'https://www.themoviedb.org/',
#         'X-Forwarded-For': '8.8.8.8'  # This is a Google DNS IP, which is US-based
#     }
    
#     response = requests.get(url, headers=headers)
#     soup = BeautifulSoup(response.content, "html.parser")
    
#     # Find the first search result
#     first_result = soup.find('div', class_='card v4 tight')
    
#     if first_result:
#         # Find the poster image
#         poster_img = first_result.find('img', class_='poster')
#         if poster_img and 'src' in poster_img.attrs:
#             poster_url = poster_img['src']
#             # Convert to full resolution URL
#             poster_url = poster_url.replace('/w94_and_h141_bestv2', '/original')
#             return poster_url
    
#     return None

# # Example usage
# query = "Find me falling"
# poster_url = get_tmdb_poster(query)
# print(f"TMDB poster URL for '{query}': {poster_url}")