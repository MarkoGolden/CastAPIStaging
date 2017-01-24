require 'faraday'
require 'json'
require 'ostruct'
require 'date'
require 'optparse'

class WeatherController < ApplicationController
	
	def retrieve_info
		if params[:latitude] && params[:longitude]
			geolookup = JSON.parse(HTTP.get("http://api.wunderground.com/api/c86d37088090cd44/geolookup/q/#{params[:latitude]},#{params[:longitude]}.json"))

			unless geolookup["response"]["error"]
				w_id = geolookup["location"]["l"]

				conditions = JSON.parse(HTTP.get("http://api.wunderground.com/api/c86d37088090cd44/conditions#{w_id}.json"))
				ten_day_forecast = JSON.parse(HTTP.get("http://api.wunderground.com/api/c86d37088090cd44/forecast10day#{w_id}.json"))

				w_info_obj = generate_weather_object(conditions, ten_day_forecast)
			else
				geolookup["response"]["error"]["query_for"] = "geolookup"
				w_info_obj = { error: geolookup["response"]["error"] }
			end
		elsif params[:link]
			w_id = params[:link]
			conditions = JSON.parse(HTTP.get("http://api.wunderground.com/api/c86d37088090cd44/conditions#{w_id}.json"))
			ten_day_forecast = JSON.parse(HTTP.get("http://api.wunderground.com/api/c86d37088090cd44/forecast10day#{w_id}.json"))
			unless conditions["response"]["error"] || ten_day_forecast["response"]["error"]
				w_info_obj = generate_weather_object(conditions, ten_day_forecast)
			else
				conditions["response"]["error"]["query_for"] = "conditions"
				ten_day_forecast["response"]["error"]["query_for"] = "ten_day_forecast"
				w_info_obj = { error: [conditions["response"]["error"], ten_day_forecast["response"]["error"]] }
			end
		end

		render json: w_info_obj
	end


	def retrieve_weathermap
		if params[:latitude] && params[:longitude]
			raw_data = Faraday.get("http://api.openweathermap.org/data/2.5/weather?lat=#{params[:latitude]}&lon=#{params[:longitude]}&APPID=442eba5b3e3a3ae8ead5698479bcdaa8").body
			# puts raw_data
			geolookup = JSON.parse(raw_data, object_class: OpenStruct)
			if geolookup["cod"] == 200
				w_info_obj = generate_openweathermap_geolookup_object(geolookup)
			else 
				w_info_obj = { error: [geolookup["message"], geolookup["cod"]] }
			end
		elsif params[:city]
			raw_data = Faraday.get("http://api.openweathermap.org/data/2.5/forecast?q=#{params[:city]}&units=imperial&APPID=442eba5b3e3a3ae8ead5698479bcdaa8").body
  			forecasts = JSON.parse(raw_data, object_class: OpenStruct)
  			# puts raw_data
			w_info_obj = generate_openweathermap_forcast_object(forecasts)
		elsif params[:link]
			link = params[:link].split("_") # e.g. “-127.717_42.753”
			raw_data = Faraday.get("http://api.openweathermap.org/data/2.5/forecast?lat=#{link[0]}&lon=#{link[1]}'&APPID=442eba5b3e3a3ae8ead5698479bcdaa8").body
			puts raw_data
  			forecasts = JSON.parse(raw_data, object_class: OpenStruct)
  			# puts raw_data
			w_info_obj = generate_openweathermap_forcast_object(forecasts)
		end

		render json: w_info_obj
	end

	def retrieve_products
		time = Time.now.to_s
		time[10] = "T"
		time = time.gsub(":","%3A")
		time = time[0..-7]
		time += ".000Z"

		# Signiture query
		req = HTTP.get("https://webservices.amazon.com/onca/xml?AWSAccessKeyId=AKIAJPDWGVF6KZSVOROQ&AssociateTag=AKIAILVKPSLJF5ZV5IUQ&ItemPage=2&Keywords=normal%20skin%20&Operation=ItemSearch&ResponseGroup=Small%2C%20Images%2C%20OfferSummary&SearchIndex=Beauty&Service=AWSECommerceService&Timestamp=#{time}&Version=2013-08-01")

		puts "*" * 50
		# "http://webservices.amazon.co.uk/onca/xml?
		# AWSAccessKeyId=AKIAIOSFODNN7EXAMPLE&
		# Actor=Johnny%20Depp&
		# AssociateTag=mytag-20&
		# Operation=ItemSearch&
		# Operation=ItemSearch&
		# ResponseGroup=ItemAttributes%2COffers%2CImages%2CReviews%2CVariations&
		# SearchIndex=DVD&
		# Service=AWSECommerceService&
		# Sort=salesrank&
		# Timestamp=2014-08-18T17%3A34%3A34.000Z&
		# Version=2013-08-01"

		puts time
		# "http://webservices.amazon.co.uk/onca/xml?
		# AWSAccessKeyId=AKIAIOSFODNN7EXAMPLE&
		# Actor=Johnny%20Depp&
		# AssociateTag=mytag-20&
		# Operation=ItemSearch&
		# Operation=ItemSearch&
		# ResponseGroup=ItemAttributes%2COffers%2CImages%2CReviews%2CVariations&
		# SearchIndex=DVD&
		# Service=AWSECommerceService
		# &Sort=salesrank&
		# Timestamp=2014-08-18T17%3A34%3A34.000Z&
		# Version=2013-08-01&
		# Signature=Gv4kWyAAD3xgSGI86I4qZ1zIjAhZYs2H7CRTpeHLD1o%3D"

		puts "*" * 50


		# res = Hash.from_xml(req).to_json
		render json: req
	end

	def autocomplete_query
		base_uri = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=#{params[:query]}&components=country:us&types=(cities)&key=AIzaSyAT6xjriSoF7inEqOq4wka5mU15O_hjj2A"
		
		uri = URI.escape(base_uri)
		locations = JSON.parse(HTTP.get(uri))
		
		location_obj = generate_autocomplet_object(locations)    

		render json: location_obj
	end

		protected

	def generate_weather_object(conditions, ten_day_forecast)
		w_info_obj = {}

		w_info_obj[:feels_like] = conditions["current_observation"]["feelslike_f"]
		w_info_obj[:display_name] = conditions["current_observation"]["display_location"]["full"]
		w_info_obj[:humidity] = conditions["current_observation"]["relative_humidity"]
		w_info_obj[:link] = "zmw:" + conditions["current_observation"]["display_location"]["zip"] + "." + conditions["current_observation"]["display_location"]["magic"] + "." + conditions["current_observation"]["display_location"]["wmo"]
		w_info_obj[:name] = conditions["current_observation"]["display_location"]["city"] + ", " + conditions["current_observation"]["display_location"]["country"]
		w_info_obj[:precipitation] = conditions["current_observation"]["precip_today_metric"]
		w_info_obj[:temp_current] = conditions["current_observation"]["temp_f"]
		w_info_obj[:temp_max] = ten_day_forecast["forecast"]["simpleforecast"]["forecastday"][0]["high"]["fahrenheit"]
		w_info_obj[:temp_min] = ten_day_forecast["forecast"]["simpleforecast"]["forecastday"][0]["low"]["fahrenheit"]
		w_info_obj[:uvIndex] = conditions["current_observation"]["UV"]
		w_info_obj[:weather] = conditions["current_observation"]["weather"]
		w_info_obj[:wind] = "#{conditions["current_observation"]["wind_mph"]} MPH #{conditions["current_observation"]["wind_dir"]}"
		w_info_obj[:forcast] = []

		ten_day_forecast["forecast"]["simpleforecast"]["forecastday"].each do |day|
			forecast_day_obj = {}
			forecast_day_obj[:conditions] = day["conditions"]
			forecast_day_obj[:image_url] = day["icon_url"]
			forecast_day_obj[:short_name] = day["date"]["weekday_short"]
			forecast_day_obj[:temp_max] = day["high"]["fahrenheit"]
			forecast_day_obj[:temp_min] = day["low"]["fahrenheit"]

			w_info_obj[:forcast] << forecast_day_obj
		end

		w_info_obj
	end

	def generate_openweathermap_forcast_object(forecasts)
		w_info_obj = {}
		w_info_obj[:forcast] = []
		forecasts.list.map do |forecast|
	      forecast_day_obj= {}
	      # puts forecast
	      forecast_day_obj[:datetime] = forecast.dt_txt
	      forecast_day_obj[:temp] = forecast.main.temp
	      forecast_day_obj[:description] = forecast.weather.first.description
	      w_info_obj[:forcast] << forecast_day_obj
	    end

		w_info_obj
	end
	
	def generate_openweathermap_geolookup_object(geolookup)
		w_info_obj = {}
		w_info_obj[:forcast] = []
		forecast_day_obj= {}
		# puts geolookup
		forecast_day_obj[:temp] = geolookup.main.temp
    	forecast_day_obj[:description] = geolookup.weather.first.description
      	w_info_obj[:forcast] << forecast_day_obj

		w_info_obj
	end

	def generate_autocomplet_object(locations)
		locations_obj = []

		locations["predictions"].each do |location|
			puts "location = #{location}"
			state = location['description'].split(",")
			
			if state[1] == nil || state[2] == nil
				next
			end
			location_name = state[0] + ', ' + state[1].lstrip
			locations_obj << { display_name: location_name, link: location['l']}
		end

		locations_obj
	end

end
