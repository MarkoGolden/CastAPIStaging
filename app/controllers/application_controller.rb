class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  # def render *args
  #   @api_loger = ApiLog.new
  #   @api_loger.request = request.url
  #   @api_loger.response = args[0][:json].to_s
  #   @api_loger.save!
  #   super
  # end

end
