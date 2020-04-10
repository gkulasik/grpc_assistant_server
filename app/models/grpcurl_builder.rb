class GrpcurlBuilder
  attr_accessor :import_path, # @type [String] import_path
                :service_proto_path, # @type [String] service_proto_path
                :data, # @type [String] JSON data
                :insecure, # @type [Boolean] insecure
                :server_address, # @type [String] server_address
                :service_name, # @type [String] service_name
                :method_name, # @type [String] method_name
                :verbose_output, # @type [Boolean] verbose_output
                :headers # @type [Hash] headers


  def initialize(params = {})
    @import_path = params.fetch(:import_path, nil)
    @service_proto_path = params.fetch(:service_proto_path, nil)
    @data = params.fetch(:data, nil)
    @insecure = params.fetch(:insecure, true)
    @server_address = params.fetch(:server_address, nil)
    @service_name = params.fetch(:service_name, nil)
    @method_name = params.fetch(:method_name, nil)
    @verbose_output = params.fetch(:verbose_output, false)
    @headers = params.fetch(:headers, Hash.new())
  end

  def self.from_params(headers, params)
    options = params["options"] || {}
    data = params["data"]
    build_params = {
        import_path: options["import_path"],
        service_proto_path: options["service_proto_path"],
        insecure: options["insecure"],
        server_address: options["server_address"],
        service_name: options["service_name"],
        method_name: options["method_name"],
        verbose_output: options["verbose"],
        data: data,
        headers: headers || Hash.new()}
    GrpcurlBuilder.new(build_params)
  end

  def valid?
    errors.empty?
  end

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

  def build
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

  def add_if_present(variable, original_string, to_append)
    if variable.present?
      original_string + to_append
    else
      original_string
    end
  end

  def add_import_path(current_string)
    add_if_present(@import_path, current_string, " -import-path #{@import_path} ")
  end

  def add_service_proto_path(current_string)
    add_if_present(@service_proto_path, current_string, " -proto #{@service_proto_path} ")
  end

  def add_data(current_string)
    add_if_present(@data, current_string, " -d #{@data} ")
  end

  def add_verbose(current_string)
    add_if_present(@verbose_output, current_string, " -v ")
  end

  def add_insecure(current_string)
    add_if_present(@insecure, current_string, " -plaintext ")
  end

  def add_server_address(current_string)
    add_if_present(@server_address, current_string, " #{@server_address} ")
  end

  def add_service_name(current_string)
    add_if_present(@service_name, current_string, " #{@service_name}")
  end

  def add_method_name(current_string)
    add_if_present(@method_name, current_string, "/#{@method_name} ")
  end

  def add_headers(current_string)
    return current_string if @headers.nil?
    string_headers = @headers.map { |k, v| " -H '#{k}:#{v}' " }.join("")
    current_string + string_headers
  end

end