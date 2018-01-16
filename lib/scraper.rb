require 'HTTParty'
require 'Nokogiri'
require 'Open-uri'
require 'csv'

class Scraper
    attr_accessor :parse_page
    attr_accessor :doc

    def initialize
        @doc = HTTParty.get('http://www.wegottickets.com/searchresults/all')
    end

    def scrape_current_page
        @parse_page = Nokogiri::HTML(@doc)
    end

    def events
        events = []
        another_page = true
        page_num = 1
        while another_page == true && page_num <= 3
            scrape_current_page
            next_page_button = @parse_page.css("#paginate").css('.block-group.advance-filled.section-margins.padded.text-center').css('a').text.include? 'next'
            @parse_page.css(".content.block-group.chatterbox-margin").each do |event|
                event_hash = {}
                event_hash[:event_name] = event.css('a.event_link').text
                event_hash[:artist_name] = event.css('.block.diptych.chatterbox-margin').css('.venue-details').css('h4 i').text unless event.css('.block.diptych.chatterbox-margin').css('.venue-details').css('h4 i').text.empty?
                event_hash[:venue_name] = event.css('.block.diptych.chatterbox-margin').css('.venue-details').css('h4').first.text.split(': ').last
                event_hash[:city] = event.css('.block.diptych.chatterbox-margin').css('.venue-details').css('h4').first.text.split(': ').first
                event_hash[:date] = event.css('.block.diptych.chatterbox-margin').css('.venue-details').css('h4')[1].text
                event_hash[:price] = event.css('.block.diptych.text-right').css('.searchResultsPrice').css('strong').text
                events << event_hash
            end
            page_num += 1
            if next_page_button == false
                another_page = false
            else
                @doc = HTTParty.get("http://www.wegottickets.com/searchresults/page/#{page_num}/all#paginate")
            end
        end
        events
    end

    def export_events
        events_arr = events
        CSV.open("data.csv", "wb") do |csv|
            events_arr.each do |event|
                event.to_a.each { |elem| csv << elem }
            end
        end
    end
end
