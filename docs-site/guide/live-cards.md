# Live cards: weather, prices and more

Ask a bot about the weather, a price, an exchange rate or the time somewhere, and it answers with a
**card of real data** and a sentence, not a paragraph pieced together from search results. Every
card says where its numbers came from and when, and keeps itself up to date while you look at it.

## What bots show as cards

| Ask about | You get |
|---|---|
| The weather now, today, tomorrow, a weekday or the week | A weather card with the sky as it is, the hours ahead, rain chance, wind, UV and sunset; switch between Now, Today, Tomorrow and 7 days |
| Air quality, sunrise and sunset, the moon | Air quality with its band and pollutants; a sun and moon card with golden hour and the moon's phase |
| Weather warnings (US) | The alerts in force, with what to do |
| A stock, an index or a coin (AAPL, PSEi, Bitcoin) | A price card with a chart you can scrub, ranges from 1 day to 5 years, the day's and year's range; several at once make a watchlist |
| Market movers, the market today | Top gainers, losers and most active; major indexes, gold, oil and bitcoin |
| Changing money (USD to PHP) | A converter you can type into and swap, with the 30-day trend |
| The time in other places, or a meeting time across zones | A world clock that keeps ticking |
| Public holidays | The next ones, with long weekends marked |
| Earthquakes, typhoons and storms | A map and list, nearest first |
| A word, a person, a place or a thing | A dictionary card (with pronunciation) or an encyclopedia summary |
| A book | Its cover, author, year and rating |
| Flight prices ("cheapest flight Manila to Tokyo March 12–19") | A fares card with real prices, airlines, times and stops; sort by cheapest, fastest or direct, and **Book** opens the booking page |
| Scores and standings (NBA, EPL, LaLiga, F1 and more) | Today's games with live scores, or the table |
| A recipe, product, film or event link | A card from the page's own data: a recipe's real ingredients scale with the servings you pick |

Bots also make cards from what they know or found: recipes, comparisons, pros and cons, steps,
timelines, loan, savings, tip and unit calculators, dice and pickers, translations, contacts,
quizzes, nutrition labels and countdowns. Those say **Written by the bot; it may be wrong** unless
they name their source.

Ask for a **morning brief** or a **trip at a glance** and several cards come together in one grid.
Your daily morning brief starts with one.

## What you can do with a card

- **Refresh:** cards on screen update on their own (weather every half hour, prices every minute
  while markets are open). Tap the refresh button for the latest now. This doesn't use the bot or
  your credits.
- **Other views:** tap Today, Tomorrow or 7 days on a weather card, or 1D to 5Y on a price.
- **⋯ menu:** pin the card to your widgets (it keeps updating there by itself), copy it as text,
  share it as a picture, or report wrong data.

**Flight fares** come from Kiwi.com first and from Google Flights when Kiwi has nothing. A Kiwi
search is free. On Casama Cloud, a Google Flights search that finds fares costs **$0.05 of
credits** and shows in the reply's usage; each plan has a few a day (Free 3, Plus 20, Pro 50, Max
100). Fares are checked again on the booking site before you pay, and Casama doesn't sell tickets.

Prices from stock markets are delayed by about 15 minutes, and cards say so. Nothing on a card is
financial advice, and no card buys or sells anything.

## Home city and units

Open **Settings > Cards**:

- **Home city** is used when you ask without naming a place ("will it rain later?"). Only a city is
  kept, never your address. Without one, bots use your time zone's main city.
- **Units** for temperature, wind, rain and distance. Until you choose, they follow your time zone.
- **Red means up** shows rising prices in red, as markets in China, Japan and Korea do.
- **Data sources** lists the services behind the cards, with their credits.

## Privacy

When a card is made or refreshed, the data service gets only what is looked up: a place rounded to
about a kilometre, a ticker, a currency, a word, or a trip (places, dates, how many travellers). It never gets your name, account or chat. See
[Privacy and security](/guide/privacy).

## Self-hosting

Live cards work with no keys: weather, rates, crypto, earthquakes, storms, holidays and reference
come from free public services. Servers that bill people need their own keys for a few of them,
because some free services are for non-commercial use only. See `LIVE_*` in `.env.example`.

Flight fares work with no key through Kiwi.com's MCP server. To add Google Flights, set
`LIVE_SERPAPI_KEY` (a SerpApi key) and keep `LIVE_SERPAPI_MONTHLY_CAP` under your SerpApi plan;
`LIVE_FARES=off` turns fares off.
