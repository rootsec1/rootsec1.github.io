+++ 
date = 2019-11-18T00:36:47+05:30
title = "Demand drivers for commodities"
description = ""
slug = ""
authors = []
tags = ["android", "machine-learning", "mobile-app-dev", "python", "flask"]
categories = []
externalLink = ""
series = []
+++

# Demand Drivers for Commodities: A Real-Time Mobile Application

[android screen-recording](https://drive.google.com/file/d/1M5c3jQ2jxJe5HZhuiwGrOAGTnC2MIrAM/view?usp=sharing)

[link to published research paper](https://ijcrt.org/papers/IJCRT2005523.pdf)

## Introduction

The objective of our mobile application was to provide real-time information about commodity prices in India. To achieve this, we developed a system that scraped multiple sources on the web, including NewsAPI and other news websites, to gather the latest articles and news related to commodities. This data, combined with information from the Twitter API, allowed us to perform sentiment analysis and generate sentiment scores for each commodity and news article.

## Tech Stack

To implement our application, we utilized the following technologies:

- **Android**: The front-end of the application was built using Android, allowing us to provide a user-friendly and intuitive interface to our users.
- **Python**: We used Python for the back-end development, enabling us to leverage its powerful libraries and frameworks for data processing and analysis.
- **Flask**: The Flask framework was chosen for building the back-end API. Its simplicity and flexibility made it an ideal choice for our project.

## Data Collection and Processing

Our application relied on data from various sources to provide real-time commodity prices and sentiment analysis. Here's an overview of the data collection and processing pipeline:

1. **Web Scraping**: We developed a web scraping module that collected articles and news related to commodities from different sources. We utilized libraries like Beautiful Soup and Scrapy to extract relevant data from websites in real-time.

2. **NewsAPI Integration**: In addition to web scraping, we integrated NewsAPI to retrieve articles and news related to commodities. NewsAPI provided a convenient way to access a wide range of news sources, enriching our data collection process.

3. **Twitter API Integration**: We utilized the Twitter API to collect real-time tweets related to commodities. By leveraging the power of social media data, we aimed to capture the sentiment of the market regarding specific commodities.

4. **Sentiment Analysis**: Once we obtained the news articles and tweets, we performed sentiment analysis to gauge market sentiment for each commodity and news article. Natural Language Processing (NLP) techniques, including text preprocessing, feature extraction, and machine learning models, were employed to assign sentiment scores.

## Backend Development with Flask

The backend of our application was built using Flask, a lightweight web framework for Python. Flask allowed us to create a robust and scalable API to handle requests and serve data to the front-end. Here's a code snippet that demonstrates the basic structure of our Flask application:

```python
import requests
import tweepy
from textblob import TextBlob

# Function to scrape news articles

def scrape_news_articles(): # Web scraping code to collect news articles # ...
return news_articles

# Function to fetch tweets

def fetch_tweets(keyword): # Authenticate with Twitter API
auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_token_secret)
api = tweepy.API(auth)

    # Fetch tweets based on keyword
    tweets = api.search(q=keyword, lang='en', count=100)

    return tweets

# Function to perform sentiment analysis

def perform_sentiment_analysis(text): # Preprocess the text data # ...

    # Perform sentiment analysis using TextBlob
    sentiment = TextBlob(text).sentiment.polarity

    return sentiment

@app.route('/commodity', methods=['GET'])
def get_commodity_prices(): # Retrieve commodity prices from a database or external API # ...
return jsonify(commodity_prices)

@app.route('/sentiment', methods=['POST'])
def perform_sentiment_analysis():
data = request.get_json()
articles = data['articles']

    sentiment_scores = {}
    for article in articles:
        text = article['text']
        sentiment = perform_sentiment_analysis(text)
        sentiment_scores[article['id']] = sentiment

    return jsonify(sentiment_scores)
```

In the code snippets above, we added functions to scrape news articles, fetch tweets based on a keyword, and perform sentiment analysis using the TextBlob library. These functions can be integrated into the backend Flask application to gather data and generate sentiment scores for the commodity news articles.
