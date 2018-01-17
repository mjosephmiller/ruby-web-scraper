require 'minitest/autorun'
require './lib/scraper'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'test/vcr_cassettes'
  c.hook_into :webmock
end

class ScraperTest < Minitest::Test
    def setup
        VCR.use_cassette('we_got_tickets/get', match_requests_on: %i[method uri headers body]) do
            @scraper = Scraper.new
        end
    end

    def test_scraper_initializes_with_a_doc
        assert_equal '200', @scraper.doc.code
    end

    def test_search_takes_two_arguments_and_filters_results
        VCR.use_cassette('we_got_tickets/search', match_requests_on: %i[method uri headers body]) do
            response = @scraper.search('adv_genre', 1)
            assert_equal "Genre: Cabaret/Burlesque", response.at('#queryFeedback').text.strip
            assert_equal '(22 events found)', response.at('#resultsCount').text.strip
        end
    end

    def test_events_returns_an_array_of_events
        VCR.use_cassette('we_got_tickets/search', match_requests_on: %i[method uri headers body]) do
            page_limit = 1
            @scraper.search('adv_genre', 1)
            events = @scraper.events(page_limit)
            assert events.is_a? Array
            required = [:event_name, :venue_name, :city, :date, :price]
            # optional :artist_name
            required.each do |key|
                refute events.first[key].nil?
            end
        end
    end

    def test_export_events_without_search_query
        VCR.use_cassette('we_got_tickets/search', match_requests_on: %i[method uri headers body]) do
            @scraper.export_events(page_limit: 1)
        end
        csv_sample =  IO.readlines('data.csv')
        assert_equal "venue_name,Leighton House", csv_sample[1].strip
    end

    def test_export_events_with_search_query
        VCR.use_cassette('we_got_tickets/search', match_requests_on: %i[method uri headers body]) do
            @scraper.export_events(search: { form_field: 'adv_genre', value: 1 }, page_limit: 1)
        end
        csv_sample =  IO.readlines('data.csv')
        assert_equal 'venue_name,Bethnal Green Working Mens Club', csv_sample[1].strip
    end
end
