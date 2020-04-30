class GrpcurlBuilder
  attr_accessor :import_path, # @type [String] import_path
                :service_proto_path, # @type [String] service_proto_path
                :data, # @type [Hash] JSON structured data
                :insecure, # @type [Boolean] insecure
                :server_address, # @type [String] server_address
                :service_name, # @type [String] service_name
                :method_name, # @type [String] method_name
                :verbose_output, # @type [Boolean] verbose_output
                :headers, # @type [Hash] headers
                :hints # Array[String] hints

  # @return [GrpcurlBuilder]
  def initialize(params = {})
    @import_path = params.fetch(:import_path, nil)
    @service_proto_path = params.fetch(:service_proto_path, nil)
    @data = params.fetch(:data, nil)
    @insecure = params.fetch(:insecure, true)
    @server_address = params.fetch(:server_address, nil)
    @service_name = params.fetch(:service_name, nil)
    @method_name = params.fetch(:method_name, nil)
    @verbose_output = params.fetch(:verbose_output, false)
    @headers = params.fetch(:headers, Hash.new)
    @hints = params.fetch(:hints, [])
  end

  # Helper to generate GrpcBuilder in format easier for controller
  # @param [Hash] headers
  # @param [Hash] params
  # @return [GrpcurlBuilder]
  def self.from_params(headers, params)
    options = params["options"] || {}
    build_params = {
        import_path: options["import_path"],
        service_proto_path: options["service_proto_path"],
        insecure: options["insecure"],
        verbose_output: options["verbose"],
        server_address: params["server_address"],
        service_name: params["service_name"],
        method_name: params["method_name"],
        data: params["data"],
        headers: headers || Hash.new,
        hints: [] }
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
    grpcurl = add_insecure(grpcurl)
    grpcurl = add_verbose(grpcurl)
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

  # Adds data to grpcurl command (-d)
  def add_data(current_string)
    add_if_present(@data, current_string, " -d '#{@data.to_json}' ")
  end

  # Adds -v tag to grpcurl command
  def add_verbose(current_string)
    add_if_present(@verbose_output, current_string, " -v ")
  end

  # Adds -plaintext tag to grpcurl command
  def add_insecure(current_string)
    log_hint(BuilderHints::INSECURE_FLAG) if @insecure.present?
    add_if_present(@insecure, current_string, " -plaintext ")
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
    return current_string if @headers.nil?
    string_headers = @headers.map { |k, v| " -H '#{k}:#{v}' " }.join("")
    current_string + string_headers
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