class GrpcurlBuilder
  attr_accessor :import_path, # @type [String] import_path
                :service_proto_path, # @type [String] service_proto_path
                :data, # @type [String] JSON structured data (or Hash)
                :plaintext, # @type [Boolean] plaintext
                :server_address, # @type [String] server_address
                :service_name, # @type [String] service_name
                :method_name, # @type [String] method_name
                :verbose_output, # @type [Boolean] verbose_output
                :max_message_size, # @type [Int] max_message_size
                :connect_timeout, # @type [Int] connect_timeout
                :max_time, # @type [Int] max_time
                :headers, # @type [Hash] headers
                :hints, # [Array<String>] hints
                :assistant_options # [Hash<String, String>] assist_options

  # @return [GrpcurlBuilder]
  def initialize(params = {})
    @import_path = params.fetch(:import_path, nil)
    @service_proto_path = params.fetch(:service_proto_path, nil)
    @data = params.fetch(:data, nil)
    @plaintext = params.fetch(:plaintext, true)
    @server_address = params.fetch(:server_address, nil)
    @service_name = params.fetch(:service_name, nil)
    @method_name = params.fetch(:method_name, nil)
    @verbose_output = params.fetch(:verbose_output, false)
    @headers = params.fetch(:headers, Hash.new)
    @hints = params.fetch(:hints, [])
    @max_message_size = params.fetch(:max_message_size, nil)
    @connect_timeout = params.fetch(:connect_timeout, nil)
    @max_time = params.fetch(:max_time, nil)

    begin
      @assistant_options = params.fetch(:assistant_options, '')
                               .split(';')
                               .map { |option| { option.split(':')[0] => option.split(':')[1] } }
                               .reduce({}, :merge)
    rescue
      log_hint(BuilderHints::INVALID_ASSISTANT_OPTIONS) unless params.fetch(:assistant_options, '').nil?
      @assistant_options = {}
    end

  end

  # Helper to generate GrpcBuilder in format easier for controller
  # @param [Hash] metadata
  # @param [Hash] request_headers
  # @param [String] body
  # @return [GrpcurlBuilder]
  def self.from_params(metadata, request_headers, params, body)
    build_params = {
        import_path: metadata[BuilderMetadata::IMPORT_PATH],
        service_proto_path: metadata[BuilderMetadata::SERVICE_PROTO_PATH],
        plaintext: Util.eval_to_bool(metadata[BuilderMetadata::PLAINTEXT]),
        verbose_output: Util.eval_to_bool(metadata[BuilderMetadata::VERBOSE]),
        server_address: metadata[BuilderMetadata::SERVER_ADDRESS],
        service_name: params["service_name"],
        method_name: params["method_name"],
        max_message_size: metadata[BuilderMetadata::MAX_MESSAGE_SIZE],
        max_time: metadata[BuilderMetadata::MAX_TIME],
        connect_timeout: metadata[BuilderMetadata::CONNECT_TIMEOUT],
        data: body,
        headers: request_headers || Hash.new,
        hints: [],
        assistant_options: metadata[BuilderMetadata::ASSISTANT_OPTIONS] }
    GrpcurlBuilder.new(build_params)
  end

  # @return [TrueClass, FalseClass]
  def valid?
    errors.empty?
  end

  # Simple error checking, only three fields are truly required
  # @return [Array<String>]
  def errors
    errors = []
    unless @method_name.present?
      errors << "method_name is not set"
    end
    unless @service_name.present?
      errors << "service_name is not set"
    end
    unless @server_address.present?
      errors << "server_address is not set"
    end
    errors
  end

  # Builds the grpcurl command
  # Allow for different command configuration between a command or execute,
  # potential to also support system differences (mac vs linux vs windows) - tbd
  # @param [BuilderMode] builder_mode
  # @return [String]
  def build(builder_mode = BuilderMode::COMMAND)
    grpcurl = "grpcurl "
    # Tags
    grpcurl = add_import_path(grpcurl, builder_mode)
    grpcurl = add_service_proto_path(grpcurl)
    grpcurl = add_headers(grpcurl)
    grpcurl = add_rpc_headers(grpcurl)
    grpcurl = add_reflect_headers(grpcurl)
    grpcurl = add_plaintext(grpcurl)
    grpcurl = add_verbose(grpcurl, builder_mode)
    grpcurl = add_max_message_size(grpcurl)
    grpcurl = add_max_time(grpcurl)
    grpcurl = add_connect_timeout(grpcurl)
    grpcurl = add_data(grpcurl)
    # Address
    grpcurl = add_server_address(grpcurl)
    # Symbol (service call)
    grpcurl = add_service_name(grpcurl)
    grpcurl = add_method_name(grpcurl)
    grpcurl
  end

  private

  # General appending method
  # @param [Object] variable
  # @param [String] original_string
  # @param [String] to_append
  # @return [String]
  def add_if_present(variable, original_string, to_append)
    if variable.present?
      original_string + to_append
    else
      original_string
    end
  end

  # Adds -import-path tag to grpcurl command
  def add_import_path(current_string, builder_mode)
    adjusted_import_path = if @import_path.present?
                             path_has_leading_slash = @import_path[0] == '/'
                             log_hint(BuilderHints::IMPORT_PATH_LEADING) if path_has_leading_slash
                             builder_mode == BuilderMode::EXECUTE && path_has_leading_slash ? @import_path[1..-1] : @import_path
                           else
                             @import_path
                           end
    add_if_present(@import_path, current_string, " -import-path '#{adjusted_import_path}' ")
  end

  # Adds -proto tag to grpcurl command
  def add_service_proto_path(current_string)
    if @service_proto_path.present?
      path_has_leading_slash = @service_proto_path[0] == '/'
      log_hint(BuilderHints::SERVICE_PROTO_PATH_LEADING) if path_has_leading_slash
    end

    add_if_present(@service_proto_path, current_string, " -proto '#{@service_proto_path}' ")
  end

  # Adds -v tag to grpcurl command for verbose output
  # Execute always have verbose output for additional debugging and to allow proper parsing of the response
  def add_verbose(current_string, builder_mode)
    variable_override = if builder_mode == BuilderMode::EXECUTE
                          true
                        else
                          @verbose_output
                        end
    add_if_present(variable_override, current_string, " -v ")
  end

  # Adds -plaintext tag to grpcurl command (no TLS - useful for local)
  def add_plaintext(current_string)
    log_hint(BuilderHints::PLAINTEXT_FLAG) if @plaintext.present?
    add_if_present(@plaintext, current_string, " -plaintext ")
  end

  # Adds -max-msg-sz tag to grpcurl command (default 4,194,304 = 4mb)
  # Should be INT in bytes
  def add_max_message_size(current_string)
    add_if_present(@max_message_size, current_string, " -max-msg-sz #{@max_message_size} ")
  end

  # Adds -max-time tag to grpcurl command
  # Should be INT or Float in seconds
  def add_max_time(current_string)
    add_if_present(@max_time, current_string, " -max-time #{@max_time} ")
  end

  # Adds -connect-timeout tag to grpcurl command (default 10)
  # Should be INT in seconds
  def add_connect_timeout(current_string)
    add_if_present(@connect_timeout, current_string, " -connect-timeout #{@connect_timeout} ")
  end

  # Adds server address to the grpcurl command
  def add_server_address(current_string)
    add_if_present(@server_address, current_string, " #{@server_address} ")
  end

  # Adds service name to the grpcurl command
  def add_service_name(current_string)
    add_if_present(@service_name, current_string, " #{@service_name}")
  end

  # Adds method name to the grpcurl command
  # Using / syntax instead of . as a default - this was arbitrarily chosen.
  def add_method_name(current_string)
    adjusted_method_name = if @method_name.present? && (@method_name[0] == '/' || @method_name[0] == '.')
                             log_hint(BuilderHints::METHOD_NAME_LEADING)
                             "#{@method_name} "
                           else
                             "/#{@method_name} "
                           end
    add_if_present(@method_name, current_string, adjusted_method_name)
  end

  # Adds -H headers to the grpcurl command
  def add_headers(current_string)
    return current_string if @headers.nil? || @headers[ServiceController::GRPC_REQUEST_HEADER_PREFIX].nil?
    string_headers = @headers[ServiceController::GRPC_REQUEST_HEADER_PREFIX].map { |k, v| " -H '#{k}:#{v}' " }.join("")
    current_string + string_headers
  end

  # Adds -rpc-header headers to the grpcurl command
  def add_rpc_headers(current_string)
    return current_string if @headers.nil? || @headers[ServiceController::GRPC_RPC_HEADER_PREFIX].nil?
    string_headers = @headers[ServiceController::GRPC_RPC_HEADER_PREFIX].map { |k, v| " -rpc-header '#{k}:#{v}' " }.join("")
    current_string + string_headers
  end

  # Adds -reflect-header headers to the grpcurl command
  def add_reflect_headers(current_string)
    return current_string if @headers.nil? || @headers[ServiceController::GRPC_REFLECT_HEADER_PREFIX].nil?
    string_headers = @headers[ServiceController::GRPC_REFLECT_HEADER_PREFIX].map { |k, v| " -reflect-header '#{k}:#{v}' " }.join("")
    current_string + string_headers
  end

  # Adds data to grpcurl command (-d)
  def add_data(current_string)
    data_in_string_form = @data.is_a?(Hash) ? @data.to_json : @data.to_s
    formatted_data = if Util.is_json_valid?(data_in_string_form)
                       GasAutoFormatter.format(data_in_string_form, @assistant_options)
                     else
                       log_hint(BuilderHints::INVALID_JSON)
                       data_in_string_form
                     end
    adjusted_data = @data.present? ? formatted_data.squish : "" # remove white space/formatting
    add_if_present(@data, current_string, " -d '#{adjusted_data}' ")
  end

  # Helper to log hints on usage
  # Can be returned in the response, logs the hint as well
  # @param [String] hint - to add to hints
  def log_hint(hint)
    unless @hints.include?(hint)
      puts "HINT: #{hint}"
      @hints << hint
    end
  end

end