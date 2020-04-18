require 'test_helper'

class GrpcurlBuilderTest < ActiveSupport::TestCase

  DEFAULT_IMPORT_PATH = '/import/path'
  DEFAULT_PROTO_PATH = '/proto/path/example.proto'
  DEFAULT_DATA = {test: "json data"}
  DEFAULT_SERVER_ADDRESS = 'test.example.com:443'
  DEFAULT_SERVICE_NAME = "com.example.protos.test.ExampleService"
  DEFAULT_METHOD_NAME = 'FooMethod'
  DEFAULT_HEADERS = { "Authorization" => "auth-token" }

  DEFAULT_PRESENT_ERROR = 'Option PRESENT did not return expected result'
  DEFAULT_OMITTED_ERROR = 'Option OMITTED did not return expected result'

  test "Init via constructor" do
    builder = GrpcurlBuilder.new(import_path: DEFAULT_IMPORT_PATH,
                                 service_proto_path: DEFAULT_PROTO_PATH,
                                 data: DEFAULT_DATA,
                                 insecure: false,
                                 server_address: DEFAULT_SERVER_ADDRESS,
                                 service_name: DEFAULT_SERVICE_NAME,
                                 method_name: DEFAULT_METHOD_NAME,
                                 verbose_output: true,
                                 headers: DEFAULT_HEADERS)
    assert_equal DEFAULT_IMPORT_PATH, builder.import_path
    assert_equal DEFAULT_PROTO_PATH, builder.service_proto_path
    assert_equal DEFAULT_DATA, builder.data
    assert_equal DEFAULT_SERVER_ADDRESS, builder.server_address
    assert_equal DEFAULT_SERVICE_NAME, builder.service_name
    assert_equal DEFAULT_METHOD_NAME, builder.method_name
    assert_equal DEFAULT_HEADERS, builder.headers
    assert_equal false, builder.insecure
    assert_equal true, builder.verbose_output

  end

  test "init via from_params" do
    headers = DEFAULT_HEADERS
    params = {
        "options" => {
            "import_path" => DEFAULT_IMPORT_PATH,
            "service_proto_path" => DEFAULT_PROTO_PATH,
            "insecure" => true,
            "verbose" => false
        },
        "server_address" => DEFAULT_SERVER_ADDRESS,
        "service_name" => DEFAULT_SERVICE_NAME,
        "method_name" => DEFAULT_METHOD_NAME,
        "data" => DEFAULT_DATA,
        "headers" => DEFAULT_HEADERS
    }
    builder = GrpcurlBuilder.from_params(headers, params)

    assert_equal DEFAULT_IMPORT_PATH, builder.import_path
    assert_equal DEFAULT_PROTO_PATH, builder.service_proto_path
    assert_equal DEFAULT_DATA, builder.data
    assert_equal DEFAULT_SERVER_ADDRESS, builder.server_address
    assert_equal DEFAULT_SERVICE_NAME, builder.service_name
    assert_equal DEFAULT_METHOD_NAME, builder.method_name
    assert_equal DEFAULT_HEADERS, builder.headers
    assert_equal true, builder.insecure
    assert_equal false, builder.verbose_output
  end

  test "should handle import path" do
    # Option present
    builder = build(:grpcurl_builder,  import_path: 'foobar')
    expected = "grpcurl  -import-path foobar  -proto /path/to/main/service/proto/file.proto  -plaintext  -d {\"test\":\"json data\"}  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build,DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder,  import_path: nil)
    expected = "grpcurl  -proto /path/to/main/service/proto/file.proto  -plaintext  -d {\"test\":\"json data\"}  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test "should handle service_proto_path path" do
    # Option present
    builder = build(:grpcurl_builder,  service_proto_path: 'foobar')
    expected = "grpcurl  -import-path /path/to/importable/protos  -proto foobar  -plaintext  -d {\"test\":\"json data\"}  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build,DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder,  service_proto_path: nil)
    expected = "grpcurl  -import-path /path/to/importable/protos  -plaintext  -d {\"test\":\"json data\"}  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test "should handle insecure flag" do
    # Option present
    builder = build(:grpcurl_builder,  insecure: true)
    expected = "grpcurl  -import-path /path/to/importable/protos  -proto /path/to/main/service/proto/file.proto  -plaintext  -d {\"test\":\"json data\"}  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build,DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder,  insecure: false)
    expected = "grpcurl  -import-path /path/to/importable/protos  -proto /path/to/main/service/proto/file.proto  -d {\"test\":\"json data\"}  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test "should handle data" do
    # Option present
    builder = build(:grpcurl_builder,  data: DEFAULT_DATA)
    expected = "grpcurl  -import-path /path/to/importable/protos  -proto /path/to/main/service/proto/file.proto  -plaintext  -d {\"test\":\"json data\"}  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder, data: nil)
    expected = "grpcurl  -import-path /path/to/importable/protos  -proto /path/to/main/service/proto/file.proto  -plaintext  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test "should handle server address" do
    # Option present
    builder = build(:grpcurl_builder,  server_address: DEFAULT_SERVER_ADDRESS)
    expected = "grpcurl  -import-path /path/to/importable/protos  -proto /path/to/main/service/proto/file.proto  -plaintext  -d {\"test\":\"json data\"}  #{DEFAULT_SERVER_ADDRESS}  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder,  server_address: nil)
    expected = "grpcurl  -import-path /path/to/importable/protos  -proto /path/to/main/service/proto/file.proto  -plaintext  -d {\"test\":\"json data\"}  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test "should fail with missing server address" do
    builder = build(:grpcurl_builder)
    assert builder.valid?
    assert_empty builder.errors

    builder = build(:grpcurl_builder,  server_address: nil)
    assert_not builder.valid?
    assert_not_empty builder.errors
    assert_equal builder.errors.first, "server_address is not set"
  end

  test "should handle service name" do
    # Option present
    builder = build(:grpcurl_builder,  service_name: DEFAULT_SERVICE_NAME)
    expected = "grpcurl  -import-path /path/to/importable/protos  -proto /path/to/main/service/proto/file.proto  -plaintext  -d {\"test\":\"json data\"}  example.com:443  #{DEFAULT_SERVICE_NAME}/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder,  service_name: nil)
    expected = "grpcurl  -import-path /path/to/importable/protos  -proto /path/to/main/service/proto/file.proto  -plaintext  -d {\"test\":\"json data\"}  example.com:443 /ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test "should fail with missing service name" do
    builder = build(:grpcurl_builder)
    assert builder.valid?
    assert_empty builder.errors

    builder = build(:grpcurl_builder,  service_name: nil)
    assert_not builder.valid?
    assert_not_empty builder.errors
    assert_equal builder.errors.first, "service_name is not set"
  end

  test "should handle method name" do
    # Option present
    builder = build(:grpcurl_builder,  method_name: DEFAULT_METHOD_NAME)
    expected = "grpcurl  -import-path /path/to/importable/protos  -proto /path/to/main/service/proto/file.proto  -plaintext  -d {\"test\":\"json data\"}  example.com:443  com.example.protos.ExampleService/#{DEFAULT_METHOD_NAME} "
    assert_equal expected, builder.build, DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder,  method_name: nil)
    expected = "grpcurl  -import-path /path/to/importable/protos  -proto /path/to/main/service/proto/file.proto  -plaintext  -d {\"test\":\"json data\"}  example.com:443  com.example.protos.ExampleService"
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

  test "should fail with missing method name" do
    builder = build(:grpcurl_builder)
    assert builder.valid?
    assert_empty builder.errors

    builder = build(:grpcurl_builder,  method_name: nil)
    assert_not builder.valid?
    assert_not_empty builder.errors
    assert_equal builder.errors.first, "method_name is not set"
  end

  test "should handle headers" do
    # Option present
    builder = build(:grpcurl_builder,  headers: DEFAULT_HEADERS)
    expected = "grpcurl  -import-path /path/to/importable/protos  -proto /path/to/main/service/proto/file.proto  -H 'Authorization:auth-token'  -plaintext  -d {\"test\":\"json data\"}  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build,DEFAULT_PRESENT_ERROR

    # Option omitted
    builder = build(:grpcurl_builder,  headers: nil)
    expected = "grpcurl  -import-path /path/to/importable/protos  -proto /path/to/main/service/proto/file.proto  -plaintext  -d {\"test\":\"json data\"}  example.com:443  com.example.protos.ExampleService/ExampleMethod "
    assert_equal expected, builder.build, DEFAULT_OMITTED_ERROR
  end

end