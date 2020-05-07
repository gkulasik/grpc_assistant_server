# Utility class for general util type static methods
class Util

  # Helper to convert mostly text to boolean
  # @param [Object] to_eval
  # @return [Boolean]
  def self.eval_to_bool(to_eval)
    ActiveModel::Type::Boolean.new.cast(to_eval)
  end

  # Helper to determine is the string is passed in can be converted to a hash
  # Supports a hash being passed in as well for easier usage.
  # Basically, can the input be converted to a Hash?
  # @param [Hash/String] body
  # @return [Boolean]
  def self.is_json_valid?(body)
    return true if body.is_a? Hash
    begin
      JSON.parse(body).to_h
      true
    rescue
      false
    end
  end

  # Check if the string passed in is a valid ISO timestamp
  # Must contain date and time, fractions of a second are permitted.
  # Ex. "2018-08-18T23:39:21.60Z"
  # @param [String] potential_timestamp
  # @return [Boolean]
  def self.is_iso_timestamp?(potential_timestamp)
    begin
      Time.iso8601(potential_timestamp)
      true
    rescue
      false
    end
  end

  # Check if the string passed in is a date (format expected YYYY-MM-DD)
  # May be an iso timestamp (time will be truncated).
  # Ex. "2018-08-18T23:39:21.60Z" or "2020-01-01"
  # @param [String] potential_date
  # @return [Boolean]
  def self.is_date?(potential_date)
    begin
      Date.iso8601(potential_date)
      true
    rescue
      false
    end
  end
end