module Weather
  class OpenWeathermap

    def self.search_weather_for(link: nil,latitude: nil, longitude: nil)
      api_key = "442eba5b3e3a3ae8ead5698479bcdaa8"
      base_url = "http://api.openweathermap.org/data/2.5/weather"

      if latitude && longitude
        url_param = "lat=#{latitude}&lon=#{longitude}"
      elsif link
        link = link.split("_") # e.g. “-127.717_42.753”
        url_param = "lat=#{link[0]}&lon=#{link[1]}"
      end
      
      # get geolookup info
      # e.g. http://api.openweathermap.org/data/2.5/weather?lat=19.26&lon=-99.8&APPID=442eba5b3e3a3ae8ead5698479bcdaa8
      raw_data = Faraday.get("#{base_url}?#{url_param}&APPID=#{api_key}").body
      geolookup = JSON.parse(raw_data, object_class: OpenStruct)
      if geolookup["cod"] == 200
        w_info_obj = generate_openweathermap_geolookup_object(geolookup)
      else 
        w_info_obj = { error: [geolookup["message"], geolookup["cod"]] }
        return
      end

      # get forcast info for geolookup
      # e.g. http://api.openweathermap.org/data/2.5/forecast?lat=19.26&lon=-99.8&APPID=442eba5b3e3a3ae8ead5698479bcdaa8
      base_url = "http://api.openweathermap.org/data/2.5/forecast"
      raw_data = Faraday.get("#{base_url}?#{url_param}&APPID=#{api_key}").body
      geolookup = JSON.parse(raw_data, object_class: OpenStruct)
      forecast_info_obj = generate_openweathermap_forcast_object(forecasts)
      w_info_obj << forecast_info_obj

      w_info_obj

    end

    def self.generate_openweathermap_forcast_object(forecasts)
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
    
    def self.generate_openweathermap_geolookup_object(geolookup)
      w_info_obj = {}
      w_info_obj[:feels_like] = ""
      w_info_obj[:display_name] = geolookup.display_name
      w_info_obj[:humidity] = geolookup.main.humidity
      w_info_obj[:link] = "#{geolookup.coord.lon}_#{geolookup.coord.lat}"
      
      forecast_day_obj= {}
      # puts geolookup
      forecast_day_obj[:temp] = geolookup.main.temp
      forecast_day_obj[:description] = geolookup.weather.first.description
      w_info_obj[:forcast] << forecast_day_obj

      w_info_obj
    end

  end
end
