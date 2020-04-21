class GrpcurlBuilder
  attr_accessor :import_path, # @type [String] import_path
                :service_proto_path, # @type [String] service_proto_path
                :data, # @type [Hash] JSON structured data
                :insecure, # @type [Boolean] insecure
                :server_address, # @type [String] server_address
                :service_name, # @type [String] service_name
                :method_name, # @type [String] method_name
                :verbose_output, # @type [Boolean] verbose_output
                :headers # @type [Hash] headers

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
  end

  # Helper to generate GrpcBuilder in format easier for controller
  # @param [Hash] headers
  # @param [Hash] params
  # @return [GrpcurlBuilder]
  def self.from_params(headers, params)
    options = params["options"] || {}
    data = params["data"]
    build_params = {
        import_path: options["import_path"],
        service_proto_path: options["service_proto_path"],
        insecure: options["insecure"],
        verbose_output: options["verbose"],
        server_address: params["server_address"],
        service_name: params["service_name"],
        method_name: params["method_name"],
        data: data,
        headers: headers || Hash.new }
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
  # @return [String]
  def build()
    grpcurl = "grpcurl "
    # Tags
    grpcurl = add_import_path(grpcurl)
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
  def add_import_path(current_string)
    add_if_present(@import_path, current_string, " -import-path #{@import_path} ")
  end

  # Adds -proto tag to grpcurl command
  def add_service_proto_path(current_string)
    add_if_present(@service_proto_path, current_string, " -proto #{@service_proto_path} ")
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
  # Using / syntax instead of . - this was arbitrarily chosen and may change or be made configurable.
  def add_method_name(current_string)
    add_if_present(@method_name, current_string, "/#{@method_name} ")
  end

  # Adds -H headers to the grpcurl command
  def add_headers(current_string)
    return current_string if @headers.nil?
    string_headers = @headers.map { |k, v| " -H '#{k}:#{v}' " }.join("")
    current_string + string_headers
  end

end