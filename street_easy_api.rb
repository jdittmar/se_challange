require 'rubygems'
require 'json'
require 'net/http'

module StreetEasyApi

	class TopListingSearch

		def initialize(base_url_options={}, params = {}, response_requirements={})
			@base_url_options = base_url_options
			@params = params
			@response_requirements = response_requirements
		end

		def run_API_request()
			parsed_api_response = {}

			if(! ENV.has_key?('API_KEY')	)
				return {'error' => 'API key not defined!'}
			end

			@response_requirements['number_records'] ||= 20

			
			@base_url_options['city'] ||= 'nyc'
			@base_url_options['listing_type'] ||= 'sales'
			
			@params['key'] = ENV['API_KEY']
			@params['format'] ||= 'json'
			@params['order'] ||= 'price_desc'
			@params['area'] ||= 'soho-manhattan'

			base_url = "http://streeteasy.com/#{@base_url_options['city']}/api/#{@base_url_options['listing_type']}"

			# check how many listings there are
			total_number_listings = get_number_listings(base_url)
			if(total_number_listings.has_key?('error'))
				return total_number_listings
			end
			# add warning if there are fewer than expected
			if(total_number_listings['count'] < @response_requirements['number_records'])
				parsed_api_response['warnings'] ||= []
				parsed_api_response['warnings'] << "Warning! Fewer than #{@response_requirements['number_records']} #{@base_url_options['listing_type']} lsitings found on streeteasy."
			end

			batch_size=20
			offset = 0
			parsed_api_response[@base_url_options['listing_type']] = []
			while(parsed_api_response[@base_url_options['listing_type']].size < @response_requirements['number_records'])
				response = get_listings(base_url, @params,batch_size,offset)
				return response if response.has_key?('error')

				response['listings'].each do |listing|
					data = {'url' => listing['url'],
									'unit' => listing['addr_unit'],
									'price' => listing['price'],
									'listing_class' => @base_url_options['listing_type'].capitalize,
									'address' => listing['addr_street']
								}
					parsed_api_response[@base_url_options['listing_type']] << data
					break if parsed_api_response[@base_url_options['listing_type']].size >= @response_requirements['number_records']
				end
			end
			return parsed_api_response
		end




		private

		def get_listings(base_url, params, limit, offset)
			params['limit'] = limit
			params['offset'] = offset
			http = "#{base_url}/search"
			begin
				response = Net::HTTP.get(URI("#{http}?#{parameterize(params)}"))
			rescue => err
				return {'error' => "Exception: #{err}"}
			end
			return params['format'] == 'json' ? JSON.parse(response) : response
		end

		def get_number_listings(base_url)
			http = "#{base_url}/data"
			begin
				response = Net::HTTP.get(URI("#{http}?#{parameterize(@params)}"))
			rescue => err
				return {'error' => "Exception: #{err}"}
			end
			response = @params['format'] == 'json' ? JSON.parse(response) : response
			return {'count' => response['listing_count']}
		end

		def parameterize(params)
			URI.encode(params.collect{|k,v| "#{k}=#{v}"}.join('&'))
		end

	end

end
