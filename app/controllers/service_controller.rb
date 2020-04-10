class ServiceController < ApplicationController
  GRPC_HEADER_PREFIX = "HTTP_GRPC_"

  # Route: service_execute
  # Path: POST /service/execute
  def execute
    # TODO pass to grpccurl and return result as JSON
  end

  # Route: service_command
  # Path: POST /service/command
  def command
    headers = get_grpc_headers(request.headers)
    builder = GrpcurlBuilder.from_params(headers, params)
    if builder.valid?
      render :json => { command: builder.build }
    else
      render :json => { errors: builder.errors }, status: :bad_request
    end
  end

  def get_grpc_headers(headers_hash)
    headers_hash.select { |k, v| k.include? GRPC_HEADER_PREFIX }.map { |k, v| [k.gsub(GRPC_HEADER_PREFIX, ""), v] }.to_h
  end

end
