class ServiceController < ApplicationController
  # See get_grpc_headers comment for more information
  # GRPC_REQUEST_HEADER_PREFIX - Prefix for request headers (both rpc request and reflect) (like Authorization)
  # GRPC_RPC_HEADER_PREFIX - Prefix for rpc request only headers
  # GRPC_REFLECT_HEADER_PREFIX - Prefix for reflect only headers
  GRPC_REQUEST_HEADER_PREFIX = "HTTP_GRPC_REQ_" # -H
  GRPC_RPC_HEADER_PREFIX = "HTTP_GRPC_RPC_" # -rpc-header
  GRPC_REFLECT_HEADER_PREFIX = "HTTP_GRPC_REFLECT_" # -reflect-header
  HEADER_TYPES = [GRPC_REQUEST_HEADER_PREFIX, GRPC_RPC_HEADER_PREFIX, GRPC_REFLECT_HEADER_PREFIX]

  # GRPC_METADATA_PREFIX - Prefix for request metadata like service_address, import_path, or gas_options
  GRPC_METADATA_PREFIX = "HTTP_GRPC_META_"

  # Execute a given grpcurl command given input, returns command and result
  # Route: service_execute
  # Path: POST /service/:service_name/execute/:method_name
  def execute
    metadata_headers = get_grpc_headers(GRPC_METADATA_PREFIX, request.headers.to_h, true)
    builder = GrpcurlBuilder.from_params(metadata_headers, extract_all_headers(request.headers.to_h), service_params.to_h, request.body.read)
    if builder.valid?
      result = GrpcurlExecutor.execute(builder)
      status = result.is_success? ? :ok : :bad_request
      respond_to do |format|
        # JSON format allows easier automation/FE *initial* integration
        format.json {
          begin
            render json: result.to_json_response, status: status
          rescue
            alert_msg = "Response parsing error. Response is not JSON. Original response: \n\n"
            render plain: alert_msg + result.to_text_response, status: :bad_request
          end
        }
        format.all { render plain: result.to_text_response, status: status }
      end
    else
      render json: { errors: builder.errors }, status: :bad_request
    end
  end

  # Get a grpcurl command given input, returns command only (no execution)
  # Route: service_command
  # Path: POST /service/:service_name/command/:method_name
  def command
    metadata_headers = get_grpc_headers(GRPC_METADATA_PREFIX, request.headers.to_h, true)
    builder = GrpcurlBuilder.from_params(metadata_headers, extract_all_headers(request.headers.to_h), service_params.to_h, request.body.read)
    if builder.valid?
      render plain: builder.build(BuilderMode::COMMAND), status: :ok
    else
      render json: { errors: builder.errors }, status: :bad_request
    end
  end

  # Helper to get all GRPC related headers.
  # @return [Hash<Hash<String, String>>]
  def extract_all_headers(headers)
    request_headers_map = {}
    HEADER_TYPES.each do |header_type|
      request_headers_map[header_type] = get_grpc_headers(header_type, headers)
    end
    request_headers_map
  end

  # Helper to get grpc and gas headers.
  # Postman prefixes headers with HTTP_ and in order to differentiate from other HTTP headers we add GRPC_ or GAS_ to the prefix (making HTTP_GRPC_.../HTTP_GAS_)
  # This gets all those headers and strips them down to the actual header name without  prefix (so HTTP_GRPC_AUTHORIZATION -> auth-code becomes AUTHORIZATION -> auth-code).
  # Provides option to auto upcase (useful for metadata headers)
  # @param [Hash] headers_hash
  # @return [Hash]
  def get_grpc_headers(with_prefix, headers_hash, upcase_sym = false)
    headers_hash.select { |k, v| k.include? with_prefix }.map do |k, v|
      key = k.gsub(with_prefix, "")
      adjusted_key = upcase_sym ? key.upcase.to_sym : key
      [adjusted_key, v]
    end.to_h
  end

  # Permit only certain params but then allow all data from :data to allow variable data to be submitted to grpc servers.
  # @return [ActionController::Parameters]
  def service_params
    allowed_params = params.permit(:options,
                                   :service,
                                   :server_address,
                                   :service_name,
                                   :method_name,
                                   :data,
                                   options: [:verbose, :import_path, :service_proto_path, :plaintext])
    allowed_params[:data] = params[:data]
    allowed_params.permit!
  end

end
