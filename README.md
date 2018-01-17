# README

This is a Ruby script that can scrape events from [WeGotTickets](http://www.wegottickets.com/).

I aimed to implement a scraper that:
* can navigate a search on the website
* can scrape a list of all events
* can export events to CSV and display:
    - artist name(s)
    - city name
    - venue name
    - date
    - price

### How To Set Up Locally
In your terminal run:
```sh
    $ git clone https://github.com/mjosephmiller/ruby-web-scraper.git
    $ cd ruby-web-scraper
```
run the following command to install all required gems:
```sh
    $ bundle install
```
then:
```sh
    $ irb
```
then (optional):
```sh
    $ require  './lib/scraper.rb'
```
then:
```sh
    $ scraper = Scraper.new
```
then:
```sh
    $ scraper.export_events(search: { form_field: 'adv_genre', value: 8 })
```
to run the tests...in a new terminal window:
```sh
    $ ruby test/scraper_test.rb
```
