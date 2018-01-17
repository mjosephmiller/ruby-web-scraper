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

    def search(form_field, value)
        form = @doc.forms[1]
        form.field_with(name: form_field).options[value].click
        form.submit
    end

    def events(page_limit = nil)
        events = []
        another_page = true
        page_num = 1
        while another_page == true
            next_page_button = @doc.at('#paginate').at('.block-group.advance-filled.section-margins.padded.text-center').at('.pagination_link_text.nextlink').children[1].text == 'next' rescue false
            @doc.search(".content.block-group.chatterbox-margin").each do |event|
                event_hash = {}
                event_hash[:event_name] = event.at('a.event_link').text
                event_hash[:artist_name] = event.at('.block.diptych.chatterbox-margin').at('.venue-details').at('h4 i').text unless event.at('.block.diptych.chatterbox-margin').at('.venue-details').at('h4 i').nil?
                event_hash[:venue_name] = event.at('.block.diptych.chatterbox-margin').at('.venue-details').at('h4').text.split(': ').last
                event_hash[:city] = event.at('.block.diptych.chatterbox-margin').at('.venue-details').at('h4').text.split(': ').first
                event_hash[:date] = event.at('.block.diptych.chatterbox-margin').at('.venue-details').search('h4')[1].text
                event_hash[:price] = event.at('.block.diptych.text-right').at('.searchResultsPrice').at('strong').text rescue 'see event info'
                events << event_hash
            end
            if page_limit && page_limit == page_num
                another_page = false
            elsif next_page_button == false
                another_page = false
            else
                page_num += 1
                @doc = @agent.get("http://www.wegottickets.com/searchresults/page/#{page_num}/adv#paginate")
            end
        end
        events
    end

    def export_events(*args)
        unless args[0][:search].nil?
            form_field = args[0][:search][:form_field]
            value = args[0][:search][:value]
            @doc = search(form_field, value)
        end
        unless args[0][:page_limit].nil?
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
