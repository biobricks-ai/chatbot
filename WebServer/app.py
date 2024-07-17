from flask import Flask, request, jsonify, render_template_string
from openai import OpenAI
import os

client = OpenAI(
    api_key=os.environ.get["OPENAI_API_KEY"]
)
import requests
from bs4 import BeautifulSoup
import re

app = Flask(__name__)

html_template = """
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Web Scraper and Analyzer</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/water.css@2/out/water.css">
  </head>
  <body>
    <div class="container">
      <h1>Web Scraper and Analyzer</h1>
      <form action="/scrape" method="post">
        <div class="form-group">
          <label for="url">URL to scrape:</label>
          <input type="text" class="form-control" id="url" name="url" required>
        </div>
        <button type="submit" class="btn btn-primary">Submit</button>
      </form>
      <div style={"width": "100%"}>
        <input type="text">
      </div>
      {% if analysis %}
        <h2>Analysis Result</h2>
        <p>{{ analysis }}</p>
        {% for link in links %}
            <a href={{link}}>
        {% endfor %}
      {% endif %}
    </div>
  </body>
</html>
"""


@app.route("/")
def home():
    return render_template_string(html_template)


@app.route("/scrape", methods=["POST"])
def scrape_and_analyze():
    url = request.form.get("url")
    if not url:
        return jsonify({"error": "URL is required"}), 400

    # Web scraping
    response = requests.get(url)
    if response.status_code != 200:
        return jsonify({"error": "Failed to fetch the URL"}), 400

    soup = BeautifulSoup(response.text, "html.parser")
    text = soup.get_text()
    table = soup.find("table")

    # Use OpenAI API to analyze the text
    openai_response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "user",
                "content": f"Analyze the following table:\n\n{table}. Describe some of its contents briefly and extract some of the links it includes in the Method column. Format those links in a bulleted list.",
            }
        ],
        max_tokens=1500,
    )

    analysis = str(openai_response.choices[0].message.content)

    # links = re.findall("\[.*\]\(.*\)$", analysis)

    return render_template_string(html_template, analysis=analysis)


if __name__ == "__main__":
    app.run(debug=True)
