require 'rubygems'
require 'json'
require 'open-uri'
#due to google API usage terms it's not possible to cache the query results

Trip_data = Struct.new(:name, :lat, :lng)

API_KEY = ARGV[1]

def auto_complete_results(keyword)
  url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?" + 
  "input=#{keyword}&types=(cities)&language=en_US" +
  "&key=#{API_KEY}"

  response = JSON.parse(open(url).read)["predictions"]
  response.map { |result| result["description"] }
end

def geocoding_url(city)
  city = URI.encode(city)
  "https://maps.googleapis.com/maps/api/geocode/json?"+
  "address=#{city}&key=#{API_KEY}"
end

#in rails this would done in a before_save callback due to the API call limit
#being shorter and the response time is also longer
#for this reason this ideally should be moved to a sidekiq worker
def location_geocoding_map(city)
    url = geocoding_url(city.split(",")[0])
    response = JSON.parse(open(url).read)["results"].first["geometry"]["location"]
    Trip_data.new(city, response["lat"], response["lng"])
end

def process_trip_data(auto_complete_results)
  auto_complete_results.map { |city| location_geocoding_map(city) }
end

unless ARGV[0].nil? || ARGV[1].nil?
  puts "-----CITIES-------"
  results = auto_complete_results(ARGV[0])
  puts results
  puts ""
  puts "-----GEOLOCATIONS----"
  puts process_trip_data(results)
else
  puts "Usage: ruby places_client.rb <keyword> <API key>"
end

