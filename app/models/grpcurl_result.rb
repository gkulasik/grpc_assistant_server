class GrpcurlResult
  attr_accessor :command, # @type [String] command
                :raw_output, # @type [String] raw_output
                :raw_errors, # @type [String] raw_errors
                :clean_response # @type [String] clean_response


  GRPC_RESPONSE_START_MARKER = 'Response contents:'
  GRPC_RESPONSE_END_MARKER = 'Response trailers received:'

  # Init with hash - accepted params:
  # @param [String] command
  # @param [String] raw_output
  # @param [String] raw_errors
  # @return [GrpcurlResult]
  def initialize(params = {})
    @command = params[:command]
    @raw_output = params[:raw_output]
    @raw_errors = params[:raw_errors]
    @clean_response = params[:raw_errors].present? ? nil : parse_raw_output(params[:raw_output])
  end

  # Helper to get the response/parse again if for some reason initialize did not parse the output the first time.
  # Used due to FactoryBot not initializing the GrpcResult properly.
  # @return [Hash]
  def get_response
    if @clean_response.nil? && !@raw_errors.present?
      parse_raw_output(@raw_output)
    else
      @clean_response
    end
  end

  # Quick consistent success check
  # @return [TrueClass, FalseClass]
  def is_success?
    !@raw_errors.present?
  end

  # @param [String] output
  # @return [Hash] return contents of grpc response (JSON format)
  def parse_raw_output(output)
    if output.nil?
      puts "Nil input"
      return nil
    end
    response_start = output.index(GRPC_RESPONSE_START_MARKER)
    response_end = output.index(GRPC_RESPONSE_END_MARKER)

    if response_start.nil?
      puts "No response start: #{output}"
      return nil
    end
    if response_end.nil?
      puts "No response end: #{output}"
      return nil
    end
    adjusted_response_start = response_start + GRPC_RESPONSE_START_MARKER.length
    adjusted_response_end = response_end - 1
    extracted_json = output[adjusted_response_start..adjusted_response_end]
    begin
      # Add back the outside curly brackets are they are removed by the scan operation
      JSON.parse(extracted_json)
    rescue JSON::ParserError => e
      puts e
      puts "Input: #{output}"
      return nil
    end
  end

  # Convert GrpcResult into an API response with relevant information
  # @return [Hash]
  def to_api_response
    if is_success?
      { success: true, response: get_response, command: @command, full_output: @raw_output }
    else
      { success: false, errors: @raw_errors, command: @command }
    end
  end
end