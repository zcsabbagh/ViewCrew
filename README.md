Today's social media tells you very little about very many people. I'm building View Crew to help you learn more about the few that you care about.  I'm starting with streaming data, i.e. letting you see what your friends are watching on services like Netflix, Hulu, etc, but then plan on doing other verticals (calendar, spending, music, health).

A bit about the tech stack of this project:
- Frontend fully in Swift
- Backend functions in Python, hosted on GCP
- Authentication uses Prelude
- Movie genre extraction uses Claude
- Image caching uses the SDWebImage library
- To overcome the lack of a Netflix API, I scraped the user's cookies & login info on the frontend using WebKit, and then scraped their profile's CSV.

Given the incredible lack of documentation on scraping with WebKit and WidgetKit (especially regarding widget memory consumption), this project taught me lots and lots and lots about debugging 😁

Download the App here: https://apps.apple.com/us/app/view-crew-streaming-widget/id6569239199

<img width="895" alt="Screenshot 2024-07-24 at 1 03 35 PM" src="https://github.com/user-attachments/assets/0dc79adf-1efa-4ecd-8be7-98d78b0a6272">

