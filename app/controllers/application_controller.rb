class ApplicationController < ActionController::API
  # Allow specifying formats (like JSON vs plain text)
  include ActionController::MimeResponds
end
