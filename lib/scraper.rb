require 'csv'
require 'mechanize'
require 'pp'

class Scraper
    attr_accessor :parse_page
    attr_accessor :doc
    attr_accessor :agent

    def initialize
        @agent = Mechanize.new
        @doc = @agent.get('http://www.wegottickets.com/searchresults/adv')
    end

    def search
        form = @doc.forms[1]
        form.field_with(name: 'adv_genre').options[8].click
        form.submit
    end

    def events
        events = []
        another_page = true
        page_num = 1
        while another_page == true && page_num >= 1
            next_page_button = @doc.at('#paginate').at('.block-group.advance-filled.section-margins.padded.text-center').at('.pagination_link_text.nextlink').children[1].text == 'next' rescue false
            @doc.search(".content.block-group.chatterbox-margin").each do |event|
                event_hash = {}
                event_hash[:event_name] = event.at('a.event_link').text
                event_hash[:artist_name] = event.at('.block.diptych.chatterbox-margin').at('.venue-details').at('h4 i').text unless event.at('.block.diptych.chatterbox-margin').at('.venue-details').at('h4 i').nil?
                event_hash[:venue_name] = event.at('.block.diptych.chatterbox-margin').at('.venue-details').at('h4').text.split(': ').last
                event_hash[:city] = event.at('.block.diptych.chatterbox-margin').at('.venue-details').at('h4').text.split(': ').first
                event_hash[:date] = event.at('.block.diptych.chatterbox-margin').at('.venue-details').search('h4')[1].text
                event_hash[:price] = event.at('.block.diptych.text-right').at('.searchResultsPrice').at('strong').text rescue '0.00'
                events << event_hash
            end
            page_num += 1
            if next_page_button == false
                another_page = false
            else
                @doc = @agent.get("http://www.wegottickets.com/searchresults/page/#{page_num}/adv#paginate")
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
