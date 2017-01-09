class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include SimpleCaptcha::ControllerHelpers
  
 # used for display message in application.html.erb
  def bootstrap_class_for flash_type
    case flash_type
    when "success"
      "alert-success" # Green
    when "error"
      "alert-danger" # Red
    when "alert"
      "alert-warning" # Yellow
    when "notice"
      "alert-info" # Blue
    else
      flash_type.to_s
    end
  end
end
