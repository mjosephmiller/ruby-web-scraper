require 'minitest/autorun'
require './lib/scraper'

class ScraperTest < Minitest::Test
    def setup
        @scraper = Scraper.new
    end

    def test_scraper_initializes_with_a_doc
        assert_equal '200', @scraper.doc.response.code
    end

    def test_scrape_current_page_returns_parsed_doc
        response = @scraper.scrape_current_page
        assert_equal Nokogiri::HTML::Document, response.class
    end

    def test_events_returns_an_array_of_events
        @scraper.scrape_current_page
        events = @scraper.events
        assert events.is_a? Array
        required = [:event_name, :venue_name, :city, :date, :price]
        # optional :artist_name
        required.each do |key|
            refute events.first[key].nil?
        end
    end

    def test_export_events
        @scraper.export_events
        csv_sample =  IO.readlines('data.csv')[0]
        assert csv_sample.include? 'event_name'
    end
end
