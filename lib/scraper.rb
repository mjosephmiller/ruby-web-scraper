require 'csv'
require 'mechanize'
require 'pp'

class Scraper
    attr_accessor :doc
    attr_reader :agent

    def initialize
        @agent = Mechanize.new
        @base_url = 'http://www.wegottickets.com/searchresults'
        @doc = @agent.get("#{@base_url}/adv")
    end

    def search(form_field, value)
        form = @doc.forms[1] # advanced search form
        form.field_with(name: form_field).options[value].click
        form.submit
    end

    def events(page_limit = nil)
        events = []
        another_page = true
        page_num = 1
        event_block = ".content.block-group.chatterbox-margin"
        while another_page == true
            next_page_button = @doc.at('#paginate').at('.pagination_link_text.nextlink').children[1].text == 'next' rescue false
            @doc.search(event_block).each do |event|
                event_hash = set_event_hash(event)
                events << event_hash
            end
            if page_limit && page_limit == page_num
                another_page = false
            elsif next_page_button == false
                another_page = false
            else
                page_num += 1
                @doc = @agent.get("#{@base_url}/page/#{page_num}/adv#paginate")
            end
        end
        events
    end

    def set_event_hash(event)
        event_block = '.block.diptych.chatterbox-margin'
        venue_details = '.venue-details'
        price_block = '.block.diptych.text-right'
        missing_info = 'see event' # needed when an event has tickets at various prices
        event_hash = {}
        event_hash[:event_name] = event.at('a.event_link').text
        event_hash[:artist_name] = event.at(event_block).at(venue_details).at('h4 i').text unless event.at(event_block).at(venue_details).at('h4 i').nil?
        event_hash[:venue_name] = event.at(event_block).at(venue_details).at('h4').text.split(': ').last
        event_hash[:city] = event.at(event_block).at(venue_details).at('h4').text.split(': ').first
        event_hash[:date] = event.at(event_block).at(venue_details).search('h4')[1].text
        event_hash[:price] = event.at(price_block).at('.searchResultsPrice').at('strong').text rescue missing_info
        event_hash
    end

    def export_events(*args)
        if args[0][:search]
            form_field = args[0][:search][:form_field]
            value = args[0][:search][:value]
            @doc = search(form_field, value)
        end
        if args[0][:page_limit]
            limit = args[0][:page_limit]
        end
        events_arr = events(limit)
        CSV.open("data.csv", "wb") do |csv|
            events_arr.each do |event|
                event.to_a.each { |elem| csv << elem }
            end
        end
    end
end
