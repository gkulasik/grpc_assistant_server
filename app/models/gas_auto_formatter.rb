# GAS specific class that can perform helpful auto-formatting
class GasAutoFormatter

  # Takes a JSON string and performs all the available formatting operations on
  # it (those specified through format_options)
  # If input is not valid JSON then the input (json_as_string) will be returned unmodified.
  # @param [String] json_as_string
  # @param [Hash] format_options
  # @return [String] Return json string back - formatted or not (if failed)
  def self.format(json_as_string, format_options)
    if Util.is_json_valid?(json_as_string)
      # Convert to hash for processing
      json = JSON.parse(json_as_string)
      # Process all the auto formatters
      json = format_dates(json, format_options)
      # Return back to string form after processing
      json.to_json
    else
      puts 'Invalid JSON string passed into GasAutoFormatter.format'
      json_as_string
    end
  end

  # Format dates (handles both Date and Timestamps (iso)).
  # Convert if the value is a date/timestamp, leave all other values unchanged. Keys not modified at all either.
  # @param [Hash] json
  # @param [Hash] format_options
  # @return [Hash] updated json
  def self.format_dates(json, format_options)
    return json unless Util.eval_to_bool(format_options[GasFormatType::AUTO_DATE_FORMAT])
    json = json.transform_values do |value|
      adjusted_value = if Util.is_date?(value) # Date check also picks up full timestamps
                         if Util.is_iso_timestamp?(value)
                           parsed_timestamp = Time.iso8601(value)
                           # Ref for Timestamp format: https://developers.google.com/protocol-buffers/docs/reference/csharp/class/google/protobuf/well-known-types/timestamp
                           # Ref for strftime formatter: https://apidock.com/ruby/DateTime/strftime
                           # %s is seconds since 1970-01-01, %9N is fractional seconds to 9 places (nano second)
                           {
                               seconds: parsed_timestamp.strftime('%s').to_i,
                               nanos: parsed_timestamp.strftime('%9N').to_i
                           }
                         else
                           parsed_timestamp = Date.iso8601(value)
                           # Ref for Date format: https://github.com/googleapis/googleapis/blob/master/google/type/date.proto
                           {
                               year: parsed_timestamp.year,
                               month: parsed_timestamp.month,
                               day: parsed_timestamp.day
                           }
                         end
                       else
                         value
                       end
      adjusted_value
    end
    json
  end
end