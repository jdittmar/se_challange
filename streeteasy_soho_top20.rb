#!/usr/bin/ruby

require_relative 'street_easy_api'

# Write a Ruby script to download the top 20 most expensive sales and 
# rentals in Soho from streeteasy.com and produce a json file containing that data.

# Data inside the json file should have a format similar to:

# 	[{
# 		'listing_class': 'Sale',
# 		'address': '13 Crosby Street',
# 		'unit': 'Floor 2',
# 		'url': 'http://streeteasy.com/nyc/sale/1234567',
# 		'price': 55000000
# 	}]

sales = StreetEasyApi::TopListingSearch.new(	{'city' => 'nyc', 'listing_type' => 'sales'},
																					{'area' => 'soho'},
																					{'number_records' => 20}
																				).run_API_request
rentals = StreetEasyApi::TopListingSearch.new(	{'city' => 'nyc', 'listing_type' => 'rentals'},
																					{'area' => 'soho'},
																					{'number_records' => 20}
																				).run_API_request

File.open("output.json","w") do |f|
  f.write(sales.merge!(rentals).to_json)
end

